import 'package:flutter/material.dart';
import 'package:flutter_app/pages/menu.dart';
import 'package:flutter_app/pages/geopoint.dart';
import 'package:flutter_app/pages/geovisitas.dart';
import 'package:flutter_app/pages/geodatos.dart';
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
        '/geopoint': (context) => Geopoint(),
        '/geovisitas': (context) => Geovisitas(),
        '/geodatos': (context) => Geodatos(),
        '/iniciar_sesion': (context) => IniciarSesion(),
        '/registrarse': (context) => Registrarse(),
      },
    );
  }
}
