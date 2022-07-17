// ignore_for_file: use_key_in_widget_constructors, non_constant_identifier_names, file_names
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'sqflite.dart';
import 'globals.dart' as globals;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock/wakelock.dart';

// Ce qui est réalisé sur cette page, l'enregistrement des données sur le serveur, sur le local du telephone, et le monitoring de qiu est d'entraine d'enregistrer aussi
// Ce qui manque est la notification en cas de soupçons d'accident, ce qui est prévu est la détection d'une chute des valeurs envoyées au serveur, 
// ce qui devrait déclencher une notifcation de confirmation chez le client, si aucune réponse aucun retour est recu = > accident


//Convertir les Millisecondes en format HH/MM/SS
String formatTime(int milliseconds) {
  var secs = milliseconds ~/ 1000;
  var hours = (secs ~/ 3600).toString().padLeft(2, '0');
  var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
  var seconds = (secs % 60).toString().padLeft(2, '0');
  return "$hours:$minutes:$seconds";
}

//Calculter la distance entre 2 points de positions
double calculateDistance(lat1, lon1, lat2, lon2) {
  if ((lat1 == 0) & (lon1 == 0)) {
    return 0;
  }
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class StopwatchPage extends StatefulWidget {
  const StopwatchPage();

  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  //Variable pour manipuler le temps
  late Stopwatch _stopwatch;
  late Timer _timer;

  //Variables pour detcter la chute
  bool min = false;
  bool max = false;
  int i = 0;

  //Variables a monitoriser
  String d = '00.00';
  double _d = 0;
  String v = '00.00';
  double departn = 0, N = 0;
  double departw = 0, W = 0;
  String h = '00.00';

  //Variables de position, permission, 
  Location locate = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool serviceEnabled = false;
  late PermissionStatus permissionGranted;
  bool permitted = false;
  bool isStopped = false;

  _StopwatchPageState();
  
  // La fonction qui communique les variables vers le serveur
  Future<http.Response> report_to_server() {
    // debugPrint("sending once every 1 seconds");
    return http.post(Uri.parse('https://yakuru43.pythonanywhere.com/test/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "id_user": globals.identifiant,
          "vitesse": v.toString(),
          "latitude": N.toString(),
          "longitude": W.toString(),
          "distance": d.toString(),
          "hauteur": h.toString(),
          "timestamp": DateTime.now().toString(),
        }));
  }

  // Fonction pour demander les permissions au user pour accéder au capteur de positions
  void get_permission() async {
    // ignore: unrelated_type_equality_checks
    var t = await locate.hasPermission();
    if (t.name == "granted") {
      permitted = true;
      final LocationData data = await locate.getLocation();
      departn = data.latitude!;
      departw = data.longitude!;
      return;
    }
    serviceEnabled = await locate.requestService();
    if (serviceEnabled) {
      permissionGranted = await locate.requestPermission();
      if (permissionGranted == PermissionStatus.granted) {
        final LocationData data = await locate.getLocation();
        departn = data.latitude!;
        departw = data.longitude!;
        permitted = true;
      }
    }
  }

  // Pour optimiser l'enregistrement de position, vaut mieux utiliser un protocol de sub
  // a chaque fois la position change les variable monitorisées sont mis a jour
  Future<void> _listenLocation() async {
    _locationSubscription = locate.onLocationChanged.handleError((onError) {
      debugPrint(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((LocationData currentlocation) async {
      v = currentlocation.speed!.toStringAsFixed(2);
      N = currentlocation.latitude!;
      W = currentlocation.longitude!;
      _d = _d + calculateDistance(departn, departw, N, W);
      d = _d.toStringAsFixed(2);
      h = currentlocation.altitude!.toStringAsFixed(2);
      departn = N;
      departw = W;
    });
  }

    // La fonction qui communique les variables vers le serveur
  Future<http.Response> report_chute() {
    return http.post(Uri.parse('https://yakuru43.pythonanywhere.com/chute/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "id_user": globals.identifiant,
        }));
  }

  double t = 0;
  @override
  void initState() {
    super.initState();
    get_permission();

    _stopwatch = Stopwatch();
    // re-render every 30ms
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {});
    });

    // detection de chute 
    userAccelerometerEvents.listen(
      (UserAccelerometerEvent event){
        var x = event.x;
        var y = event.y;
        var z = event.z;
        double aaa = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2));
        if( aaa <= 6.0){
          min = true;
          t = aaa;
        }
        if(min == true){
          i += 1;
          if(aaa >= 20){
            max = true;
          }
        }
        if( min && max){
          report_chute();
          final snackBar = SnackBar(
            content:
                const Text("Fall detected"),
            action: SnackBarAction(
              label: "I'm Ok.",
              onPressed: () {
                //nothing
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          i = 0;
          min = false;
          max = false;
        }
        if(i>4){
          i = 0; 
          min = false;
          max = false;
        }
      }
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Notifier le serveur le debut de l'enregistrement, elle sert a déduire sur le serveur qui
  // utilise l'enregistrement live
  Future<http.Response> report_start() {
    // debugPrint("Reporting that the race started");
    return http.post(
        Uri.parse('https://yakuru43.pythonanywhere.com/start_course/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "id_user": globals.identifiant,
        }));
  }

  // Notifier le serveur la pause de l'enregistrement, elle sert a déduire sur le serveur qui
  // as pausé l'enregistrement live
  Future<http.Response> report_pause() {
    // debugPrint("Reporting that the race is paused");
    return http.post(
        Uri.parse('https://yakuru43.pythonanywhere.com/pause_course/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "id_user": globals.identifiant,
        }));
  }

  // La fonction declenchee suite au clique sur start
  void handleStartStop() {
    if (_stopwatch.isRunning) {
      report_pause();
      _stopwatch.stop();
      _locationSubscription!.cancel();
      isStopped = true;
    } else {
      if (permitted) {
        report_start();
        _stopwatch.start();
        isStopped = false;
        Wakelock.enable();
        _listenLocation();
        Timer.periodic(const Duration(seconds: 1), (tick) {
          if (isStopped) {
            tick.cancel();
          } else {
            report_to_server();
            Position p = Position();
            p.id = globals.identifiant;
            p.Date = DateTime.now().toString();
            p.speed = v.toString();
            p.Longtitude = N.toString();
            p.Latitude = W.toString();
            p.Altitude = h.toString();
            p.distance = d.toString();
            DatabaseHelper.instance.insert(p);
          }
        });
      } else {
        setState(() {
          reset();
          final snackBar = SnackBar(
            content:
                const Text('Please head to settings and give us permission.'),
            action: SnackBarAction(
              label: 'Got it!',
              onPressed: () {
                //nothing
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }
    }
    setState(() {}); // re-render the page
  }

  // Notifier le serveur la fin de l'enregistrement, elle sert a déduire sur le serveur qui
  // as arréter l'enregistrement live
  Future<http.Response> report_stop() {
    // debugPrint("Reporting that the race stoped");
    return http.post(
        Uri.parse('https://yakuru43.pythonanywhere.com/stop_course/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "id_user": globals.identifiant,
        }));
  }

  // La fonction declenchee suite au clique sur stop
  void reset() {
    report_stop();
    _locationSubscription?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    isStopped = true;
    _locationSubscription = null;
    Wakelock.disable();
    setState(() {}); // re-render the page
  }

  // d"but de description d'interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: <Widget>[
          Container(
            color: const Color(0xFF000000),
            padding: const EdgeInsets.all(20.0),
            child: Table(
              border: TableBorder.all(color: Colors.black),
              children: [
                const TableRow(children: [
                  Center(
                    child: Text(
                      'Vitesse',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Position',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 25,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Distance',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 25,
                      ),
                    ),
                  )
                ]),
                TableRow(children: [
                  Center(
                    child: Text(
                      v + 'km/h',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      N.toString() + '" N',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      d.toString() + 'km',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ]),
                TableRow(children: [
                  const Text(''),
                  Center(
                    child: Text(
                      W.toString() + '" W',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Text(''),
                ]),
                TableRow(children: [
                  const Text(''),
                  Center(
                    child: Text(
                      h.toString() + '" H',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Text(''),
                ]),
              ],
            ),
          ),
          Expanded(
            child: Text(formatTime(_stopwatch.elapsedMilliseconds),
                style: const TextStyle(
                    color: Colors.orangeAccent, fontSize: 48.0)),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: handleStartStop,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orangeAccent,
                      ),
                      child: Text(_stopwatch.isRunning ? 'Pause' : 'Start',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15))),
                  const SizedBox(width: 30),
                  ElevatedButton(
                      onPressed: reset,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orangeAccent,
                      ),
                      child: const Text('Stop',
                          style: TextStyle(color: Colors.black, fontSize: 15))),
                ],
              ))
        ],
      ),
    );
  }

}
