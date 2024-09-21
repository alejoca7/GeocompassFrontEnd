import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Geodatos extends StatefulWidget {
  @override
  _GeodatosState createState() => _GeodatosState();
}

class _GeodatosState extends State<Geodatos> {
  List<dynamic> geodatos = [];
  List<dynamic> displayGeodatos = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGeodatos();
  }

  Future<void> fetchGeodatos() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.68:8080/geovisitas'));
      if (response.statusCode == 200) {
        setState(() {
          geodatos = json.decode(response.body);
          displayGeodatos = geodatos;
        });
      } else {
        throw Exception('Failed to load geodatos');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load data');
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        displayGeodatos = geodatos;
      });
    } else {
      List<dynamic> tempList = geodatos.where((item) {
        return item['beneficiary_id'].toString() == query;
      }).toList();
      setState(() {
        displayGeodatos = tempList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150.0),
        child: AppBar(
          backgroundColor: Color(0xFF003366),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Image.asset('assets/images/logogeocompass_31.png', height: 90),
                SizedBox(height: 10),
                Text(
                  'GEODATOS',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterSearchResults,
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Buscar por ID Beneficiario",
                hintText: "Ingrese ID Beneficiario",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateColor.resolveWith(
                      (states) => const Color.fromARGB(255, 255, 255, 255)!),
                  dataRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.grey[50]!),
                  columnSpacing: 25,
                  columns: [
                    DataColumn(
                        label: Text('ID',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                    DataColumn(
                        label: Text('Fecha Visita',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                    DataColumn(
                        label: Text('Nombre',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                    DataColumn(
                        label: Text('Tutor Visita',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14))),
                  ],
                  rows: displayGeodatos
                      .map((data) => DataRow(cells: [
                            DataCell(Text(data['beneficiary_id'].toString())),
                            DataCell(
                                Text(data['fecha_visita'] ?? 'No disponible')),
                            DataCell(Text(data['nombre'] ?? 'Desconocido')),
                            DataCell(Text(data['uservisita'] ?? 'Desconocido')),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
