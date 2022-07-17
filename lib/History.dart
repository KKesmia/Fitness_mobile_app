// ignore_for_file: use_key_in_widget_constructors, file_names, constant_identifier_names
import 'package:flutter/material.dart';
import 'sqflite.dart';
import 'package:fl_chart/fl_chart.dart';

// Alors dans ce fichier, on définit l'interface et les differents composants 
// necessaires pour faire fonctionner le historique
// On montre que les graphes de speeds et altitude, le reste des variables sont trop difficule a reprensenter et des fois
// ambigues
// l'affichage sera par jour, l'activité de chaque jour sera présente comme un onglet dans chaqu un il y aura un graph
// + un bouton pour charger vers les valeurs de altitude

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPage createState() => _HistoryPage();
}
// définir les types pour l'affichage des historiques
enum choices { Speed, Height }

class _HistoryPage extends State<HistoryPage> {
  // couleurs pour les courbes de speed et hauteur
  final List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  // variables pour récuperer les valeurs dispo dans la BD
  Map<String, Map<String, dynamic>> speeds = {};
  Map<String, Map<String, dynamic>> heights = {};

  // variable pour récupere toutes les positions dispo dans la BD
  bool isLoading = false;
  List<bool> isSelected = [];
  int size = 0;
  List<double> max = [12, 24, 0, 0];
  late List<Position> v;
  List<FlSpot> spots = [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // La fonction qui récupére toutes les points de la BD et en suite les chargent dans les variable speeds et heights
  Future<void> refresh() async{
    setState(() {
      isLoading = true;
    });
    v = (await DatabaseHelper.instance.queryPosition())!;
    for ( var i = 0; i < v.length; i++){
      var temp = DateTime.parse(v[i].Date);
      String days = temp.year.toString() + "-" + temp.month.toString() + "-" + temp.day.toString();
      String hrs = temp.hour.toString() + ":" + temp.minute.toString() + ":" + temp.second.toString();
      if (speeds.containsKey( days )){
        speeds[days]![hrs] = v[i].speed;
        heights[days]![hrs] = v[i].Altitude;
      }else{
        speeds[days] = {};
        heights[days] = {};
        speeds[days]![hrs] = v[i].speed;
        heights[days]![hrs] = v[i].Altitude;
        isSelected.add(false);
      }
    }
    setState(() {
      isLoading = false;
      size = v.length;
    });
  }

  // definir le premier bout de l'interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: isLoading ? const CircularProgressIndicator( color: Colors.orangeAccent)
        : (size == 0)? const Text("You better go run first", style: TextStyle(color: Colors.orangeAccent, fontSize: 30, fontWeight: FontWeight.bold))
          : buildDays()
      ),
    );
  }

  // La fonction qui crée les onglets des journées
  Widget buildDays() {
    return Column(
      children:[
        for ( var i = 0; i < speeds.length; i++)
          GestureDetector(
            onTap: (){
              setState((){
                isSelected[i] = !isSelected[i];
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Center(
                child: AnimatedContainer(
                  width: MediaQuery.of(context).size.width,
                  height: !isSelected[i] ? 40.0 : 500.0,
                  duration: const Duration(milliseconds: 500),
                  color: Colors.orangeAccent,
                  alignment: isSelected[i] ? Alignment.center : AlignmentDirectional.topCenter,
                  child: !isSelected[i] ? Text( speeds.keys.elementAt(i) , style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold ))
                  : buildCharts(speeds.keys.elementAt(i))
                ),
              )
            ) 
          )
      ] ,
    );
  }

  // transofrmer une map<string , dynamic> vers des points sur un graph
  List<FlSpot>? transform( Map<String, dynamic>? temp){
    List<FlSpot> r = [];
    max = [24, 0, 0, 0];
    for (var i = 0; i< temp!.length; i++){
      var t = temp.keys.elementAt(i).split(":");
      double x = double.parse(t[0]) + double.parse(t[1]) / 60; 
      r.add( FlSpot(x, double.parse( temp[temp.keys.elementAt(i)])));
      // définir les limites de axis de x et y
      if (max[3] < r.last.y) max[3] = r.last.y;
      if (max[0] > double.parse(t[0])) max[0] = double.parse(t[0]);
      if (max[1] < double.parse(t[0])) max[1] = double.parse(t[0]);
    }
    return r;
  }

  // défnir le bouton de changement du choix des données affichées
  Widget button(keyy){
    return PopupMenuButton<choices>(
      onSelected: (choices result) { 
        setState(() { 
          spots =  transform(  (result == choices.Speed)?  speeds[keyy] : heights[keyy] )!;
          debugPrint(spots.toString());
        }); 
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<choices>>[
        const PopupMenuItem<choices>(
          value: choices.Speed,
          child: Text('Speed'),
        ),
        const PopupMenuItem<choices>(
          value: choices.Height,
          child: Text('Height'),
        ),
      ],
    );
  }
  
  // définir les graphs
  Widget buildCharts(String keyy) {
    return Column(
      children:[
        button(keyy),
        Expanded(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(10),
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.black,
                minX: max[0],
                maxX: max[1] + 1,
                minY: 0,
                maxY: max[3] + 1,
                titlesData: FlTitlesData(
                  rightTitles: SideTitles(showTitles: false),
                  topTitles: SideTitles(showTitles: false),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                  drawVerticalLine: true,
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    show: true,
                    isCurved: true,
                    colors: gradientColors,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
                    ),
                  ),
                ],
              )
            ),
          )
        ))
      ],
    ); 
  }

}
