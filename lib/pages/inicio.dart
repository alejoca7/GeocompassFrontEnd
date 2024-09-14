import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/pages/iniciar_sesion.dart'; // Asegúrate de importar la página de inicio de sesión

class Inicio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF004B93), // Color azul del encabezado
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logogeocompass_31.png', // Asegúrate de tener este logo
                        width: 300,
                        height: 280,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Liberando a los niños de la pobreza\n en el nombre de Jesús',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.martelSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // Color del texto blanco
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/vectors/combined_shape_2_x2.svg',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 20),
                Image.asset(
                  'assets/images/logogeocompass_111.png',
                  width: 300,
                  height: 300,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Acción al presionar el botón
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IniciarSesion()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF01035C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'INICIAR',
                    style: GoogleFonts.martelSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Inicio(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}
