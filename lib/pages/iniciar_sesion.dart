import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'inicio.dart';
import 'registrarse.dart';
import 'menu.dart'; // Asegúrate de que la ruta sea correcta

class IniciarSesion extends StatefulWidget {
  @override
  _IniciarSesionState createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  bool _obscureText = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, complete todos los campos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String apiUrl = "https://geocompass-back-omega.vercel.app/login";

    final Map<String, dynamic> loginData = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        // Inicio de sesión exitoso, muestra el nombre del usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido ${_usernameController.text}!'),
            backgroundColor: Colors.green,
          ),
        );
        // Redirige al usuario a menu.dart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Menu()),
        );
      } else {
        // Error en el ingreso, muestra un mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el ingreso: ${response.body}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen superior
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/images/logogeocompass_41.png'),
                  ),
                ),
              ),
              // Contenedor principal
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Flecha y Título
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Color(0xFF01035C)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Inicio()),
                              );
                            },
                          ),
                          Expanded(
                            child: Text(
                              'INICIAR SESIÓN',
                              style: GoogleFonts.getFont(
                                'Martel Sans',
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                height: 1.2,
                                letterSpacing: 2,
                                color: Color(0xFF01035C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Campos de entrada
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F5F7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Usuario',
                            hintStyle: GoogleFonts.getFont(
                              'Martel Sans',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: -0.2,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F5F7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Contraseña',
                                  hintStyle: GoogleFonts.getFont(
                                    'Martel Sans',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.5,
                                    letterSpacing: -0.2,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Color(0xFFBDBDBD),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      // Botón de iniciar sesión
                      GestureDetector(
                        onTap: _loginUser,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFF01035C),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: Text(
                              'INICIAR SESIÓN',
                              style: GoogleFonts.getFont(
                                'Martel Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.5,
                                letterSpacing: 0.6,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Texto de "¿No tienes cuenta?"
                      Text(
                        '¿No tienes cuenta?',
                        style: GoogleFonts.getFont(
                          'Martel Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.5,
                          letterSpacing: -0.2,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Botón de registro
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Registrarse()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF01035C)),
                            borderRadius: BorderRadius.circular(30),
                            color: Color(0xFFFFFFFF),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'REGISTRATE',
                                style: GoogleFonts.getFont(
                                  'Martel Sans',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  height: 1.5,
                                  letterSpacing: -0.1,
                                  color: Color(0xFF01035C),
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.add_circle, color: Color(0xFF01035C)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
