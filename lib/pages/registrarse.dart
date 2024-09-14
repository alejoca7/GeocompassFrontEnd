import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'iniciar_sesion.dart'; // Importa la pantalla de inicio de sesión

class Registrarse extends StatefulWidget {
  @override
  _RegistrarseState createState() => _RegistrarseState();
}

class _RegistrarseState extends State<Registrarse> {
  bool _obscureText = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registerUser() async {
    final String apiUrl = "http://192.168.1.68:8080/users";

    final Map<String, dynamic> userData = {
      "username": _usernameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso, muestra un cuadro de diálogo y redirige
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Registro Exitoso'),
              content: Text('El usuario ha sido registrado correctamente.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el cuadro de diálogo
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => IniciarSesion()),
                    ); // Redirige a la pantalla de inicio de sesión
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Error en el registro, muestra un mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al registrar usuario: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding:
                      EdgeInsets.fromLTRB(30, 20, 30, 20), // Ajuste de padding
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
                              Navigator.pop(context); // Navega hacia atrás
                            },
                          ),
                          Expanded(
                            child: Text(
                              'REGISTRARSE',
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
                          SizedBox(
                              width: 48), // Espacio para equilibrar la flecha
                        ],
                      ),
                      SizedBox(
                          height: 20), // Espacio entre el título y los campos
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
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F5F7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Correo',
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
                      SizedBox(height: 30), // Espacio entre campos y botón
                      // Botón de registrarse
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF01035C),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: GestureDetector(
                            onTap:
                                _registerUser, // Llama a la función para registrar
                            child: Text(
                              'REGISTRARSE',
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
                      SizedBox(
                          height:
                              20), // Espacio entre botón y texto de "Ya tienes cuenta"
                      // Texto de "Ya tienes cuenta"
                      Text(
                        '¿Ya tienes cuenta?',
                        style: GoogleFonts.getFont(
                          'Martel Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.5,
                          letterSpacing: -0.2,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(
                          height:
                              10), // Espacio entre texto y botón de iniciar sesión
                      // Botón de iniciar sesión
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(
                              context); // Volver a la pantalla de inicio de sesión
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
                                'INICIAR SESIÓN',
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
                              Icon(Icons.arrow_forward,
                                  color: Color(0xFF01035C)),
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
