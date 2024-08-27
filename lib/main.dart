import 'package:flutter/material.dart';
import 'package:flutter_app/pages/menu.dart';
import 'package:flutter_app/pages/geopoint.dart';
//import 'package:flutter_app/pages/geocabina.dart';
//import 'package:flutter_app/pages/geodatos.dart';
//import 'package:flutter_app/pages/geodatos_1.dart';
import 'package:flutter_app/pages/iniciar_sesion.dart';
import 'package:flutter_app/pages/inicio.dart';
import 'package:flutter_app/pages/registrarse.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      home: Inicio(),
      routes: {
        '/menu': (context) => Menu(),
//        '/geocabina': (context) => Geocabina(),
        '/geopoint': (context) => Geopoint(),
//        '/geodatos': (context) => Geodatos(),
//        '/geodatos1': (context) => Geodatos1(),
        '/iniciar_sesion': (context) => IniciarSesion(),
        '/registrarse': (context) => Registrarse(),
      },
    );
  }
}
