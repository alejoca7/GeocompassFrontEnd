import 'package:flutter/material.dart';
import 'package:flutter_app/pages/geovisitas.dart';
import 'package:google_fonts/google_fonts.dart';
import 'geopoint.dart'; // Importa la pantalla de Geopoint

class Menu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Encabezado similar a inicio.dart
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
                  'assets/images/logogeocompass_31.png',
                  width: 300,
                  height: 150,
                ),
                SizedBox(height: 17),
                Text(
                  'GEOCOMPASS',
                  style: GoogleFonts.martelSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Cards de opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildOptionCard(
                  context,
                  'GEOPOINTS',
                  'assets/images/cdmp_fw_9_vr_x_0.png',
                  Geopoint(), // Pasar la pantalla Geopoint
                ),
                SizedBox(height: 40),
                _buildOptionCard(
                  context,
                  'GEOVISITAS',
                  'assets/images/cdmp_fw_9_vr_x_02.png',
                  Geovisitas(), // Coloca la ventana que quieras o null si aún no está implementada
                ),
                SizedBox(height: 40),
                _buildOptionCard(
                  context,
                  'GEODATOS',
                  'assets/images/cdmp_fw_9_vr_x_01.png',
                  null, // Coloca la ventana que quieras o null si aún no está implementada
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
          // Versículo
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            child: Text(
              '“Instruye al niño en su camino, Y aun cuando fuere viejo no se apartará de él.”\nProverbios 22:6',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoCondensed(
                fontSize: 15,
                height: 1.3,
                color: Color(0xFF01035C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, String imagePath,
      Widget? targetScreen) {
    return GestureDetector(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF01035C),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Text(
                title,
                style: GoogleFonts.robotoCondensed(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
