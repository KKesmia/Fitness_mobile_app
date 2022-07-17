import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'transition_route_observer.dart';
import 'fade_in.dart';
import 'History.dart';
import 'Stopwatch.dart';

// La page suite a l'authentification, la ou le homepage définit ces 2 fils stopwatch et history
// Ya rien d'exceptionnelle en relation avec le backend de l application dans ce fichier
// on définit l'interface seulement 

class MyHomePage extends StatefulWidget {
  static const routeName = '/homepage';
  
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, TransitionRouteAware {
  // le lien de retour vers le page de connexion = > la fonction a déclencher lors du clique de deconnecte
  Future<bool> _goToLogin(BuildContext context) {
    return Navigator.of(context)
        .pushReplacementNamed('/auth')
        // we dont want to pop the screen, just replace it completely
        .then((_) => false);
  }

  final routeObserver = TransitionRouteObserver<PageRoute?>();
  static const headerAniInterval = Interval(.1, .3, curve: Curves.easeOut);
  AnimationController? _loadingController;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );


  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
        this, ModalRoute.of(context) as PageRoute<dynamic>?);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _loadingController!.dispose();
    super.dispose();
  }

  @override
  void didPushAfterTransition() => _loadingController!.forward();

  AppBar _buildAppBar(ThemeData theme) {
    final signOutBtn = IconButton(
      icon: const Icon(FontAwesomeIcons.signOutAlt),
      color: Colors.black,
      onPressed: () => _goToLogin(context),
    );
    final title = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text("Run boy!  RUN!!!", style: TextStyle(color :Colors.black)),
          SizedBox(width: 20),
        ],
      ),
    );

    return AppBar(
      backgroundColor: Colors.orangeAccent,
      foregroundColor: Colors.grey,
      actions: <Widget>[
        FadeIn(
          controller: _loadingController,
          offset: .3,
          curve: headerAniInterval,
          fadeDirection: FadeDirection.endToStart,
          child: signOutBtn,
        ),
      ],
      title: title,
      bottom: const TabBar(
        indicatorColor:Colors.grey,
        tabs: [
          Tab(icon : Icon(Icons.directions_bike_sharp, color :Colors.black)),
          Tab(icon : Icon(Icons.history, color :Colors.black)),
        ],
      ), 
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(theme),
          body: TabBarView(
            children:[
              const StopwatchPage(),
              HistoryPage(),
            ],
          ),
        ),
      ),
    );
  }
}



