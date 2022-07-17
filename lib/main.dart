// ignore_for_file: use_key_in_widget_constructors

// La facon dont dart/flutter fonction est comme une arborescence des structures appélées Widgets
// La racine ou bien le widget pére est classe MyApp qui définit des fils ou bien des branchement suite a la métaphor
// Donc sur ce fichier la, main.dart, on définit widgets fils, ces fils sont définit dans 2 fichiers differents 
// MyHomePage.dart et Auth.dart, on force l'application de passer par auth.LoginScreen d abord ! 
// Le prochaine fichers a voir est Auth.dart
// les fichiers custom_route, transition_route_oberserver et fade_in sont strictement reliés la manipulation de l'interface
// donc a ignorer
import 'package:flutter/material.dart';
import 'package:runboyrun/Auth.dart';
import 'package:runboyrun/HomePage.dart';
import 'Auth.dart';
import 'transition_route_observer.dart';
import 'HomePage.dart';

void main() {runApp(const MyApp());}

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run Boy! RUN!!!',
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MyHomePage.routeName: (context) => const MyHomePage(),
      },
    );
  }
}


