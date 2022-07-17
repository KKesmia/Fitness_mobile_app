// ignore_for_file: file_names, non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_login/flutter_login.dart';
import 'package:runboyrun/HomePage.dart';
import 'users.dart';
import 'HomePage.dart';
import 'custom_route.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

// https://github.com/NearHuscarl/flutter_login Le code est tiré de ce lien, puis modofié pour adapter notre application
// La page de connexion a l'application ne fonction pas entiérement, Veuillez voir le readme pour renseigner les comptes qu on deja 
// prédéfinit dans la base de données coté serveur.
// Pour simplifier les formulaire d'inscription, il suffit seulement présenter une addresse mail valide et définir un mot de passe. Malheureusement on n'avait pas
// le temps pour travailler sur la requête correspondante.

class LoginScreen extends StatefulWidget {
  static const routeName = '/auth';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int id = 0;

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);

//Définition de la requête a envoyer afin de vérifier une connexion a un compte
  Future<http.Response> report_to_server(name, pass) {
    debugPrint("atempting authentification");
    return http.post(Uri.parse('https://yakuru43.pythonanywhere.com/login/'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: jsonEncode({
          "username": name,
          "pass": pass,
        }));
  }
//La fonction a déclencher suite a un clique sur le bouton login
  Future<String?> _loginUser(LoginData data) {
    return Future.delayed(loginTime).then((_) async {
      //http request to check from server
      http.Response rep = await report_to_server(data.name, data.password);
      id = int.parse(rep.body);
      // debugPrint(id.toString());
      // Récupérer l'identifiant attribué a ce compte par le serveur
      globals.identifiant = id;
      if (id == 0) {
        return 'User not exists';
      }
      if (id == 0) {
        return 'Password does not match';
      }
      return null;
    });
  }
//La fonction a déclencher pour la création d'un compte 
  Future<String?> _signupUser(SignupData data) {
    return Future.delayed(loginTime).then((_) {
      //http request for signing up
      return null;
    });
  }

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) {
      // http request to check if the user exist
      if (!mockUsers.containsKey(name)) {
        return 'User not exists';
      }
      return null;
    });
  }

  Future<String?> _signupConfirm(String error, LoginData data) {
    // snackbar preferably
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: "Run boy!  RUN!!!",
      navigateBackAfterRecovery: true,
      onConfirmRecover: _signupConfirm,
      onConfirmSignup: _signupConfirm,
      loginAfterSignUp: false,
      initialAuthMode: AuthMode.login,
      theme: LoginTheme(
        primaryColor: Colors.black,
        accentColor: Colors.orangeAccent,
      ),
      userValidator: (value) {
        if (!value!.contains('@') || !value.endsWith('.com')) {
          return "Email must contain '@' and end with '.com'";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return 'Password is empty';
        }
        return null;
      },
      onLogin: (loginData) {
        debugPrint('Login info');
        debugPrint('Name: ${loginData.name}');
        debugPrint('Password: ${loginData.password}');
        return _loginUser(loginData);
      },
      onSignup: (signupData) {
        debugPrint('Signup info');
        debugPrint('Name: ${signupData.name}');
        debugPrint('Password: ${signupData.password}');

        signupData.additionalSignupData?.forEach((key, value) {
          debugPrint('$key: $value');
        });
        if (signupData.termsOfService.isNotEmpty) {
          debugPrint('Terms of service: ');
          for (var element in signupData.termsOfService) {
            debugPrint(
                ' - ${element.term.id}: ${element.accepted == true ? 'accepted' : 'rejected'}');
          }
        }
        return _signupUser(signupData);
      },
      onSubmitAnimationCompleted: () {
        // le lien vers la page de MyHomePage 
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => const MyHomePage(),
        ));
      },
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return _recoverPassword(name);
        // Show new password dialog
      },
      showDebugButtons: true,
    );
  }
}
