import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class Geodatos extends StatefulWidget {
  @override
  _GeodatosState createState() => _GeodatosState();
}

class _GeodatosState extends State<Geodatos> {
  List<dynamic> geodatos = [];
  List<dynamic> displayGeodatos = [];
  TextEditingController searchController = TextEditingController();
  List<bool> selectedRows = [];
  String selectedFilter = 'Todos'; // Filtro por defecto
  List<String> uniqueTutores = ['Todos']; // Lista para los tutores únicos

  @override
  void initState() {
    super.initState();
    fetchGeodatos();
  }

  Future<void> fetchGeodatos() async {
    try {
      final response = await http.get(
          Uri.parse('https://geocompass-back-omega.vercel.app/geovisitas'));
      if (response.statusCode == 200) {
        setState(() {
          geodatos = json.decode(response.body);
          displayGeodatos = geodatos;
          selectedRows = List<bool>.filled(geodatos.length, false);
          extractUniqueTutores(); // Extraer los tutores únicos
        });
      } else {
        throw Exception('Failed to load geodatos');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load data');
    }
  }

  // Función para extraer tutores únicos
  void extractUniqueTutores() {
    Set<String> tutoresSet = {}; // Utilizamos un Set para evitar duplicados
    for (var item in geodatos) {
      if (item['uservisita'] != null && item['uservisita'] != '') {
        tutoresSet.add(item['uservisita']);
      }
    }
    setState(() {
      uniqueTutores = ['Todos', ...tutoresSet.toList()];
    });
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

  // Aplicar filtro según el tutor seleccionado
  void applyFilter() {
    if (selectedFilter == 'Todos') {
      setState(() {
        displayGeodatos = geodatos;
      });
    } else {
      List<dynamic> tempList = geodatos.where((item) {
        return item['uservisita'].toString() == selectedFilter;
      }).toList();
      setState(() {
        displayGeodatos = tempList;
      });
    }
  }

  // Función para exportar a CSV con UTF-8-BOM
  Future<void> exportToCSV() async {
    List<List<dynamic>> rows = [
      [
        'ID',
        'Nombre',
        'Fecha Nacimiento',
        'Edad',
        'Fecha Visita',
        'Direccion',
        'Telefono',
        'Nombre Madre',
        'Nombre Padre',
        'Nombre Encargado',
        'Hombres',
        'Mujeres',
        'Inscritos CDI',
        'Con Quien Vive',
        'Como Vive',
        'Tipo Casa',
        'Quienes Trabajan',
        'Trabaja Niño',
        'Observaciones',
        'Tutor Visita'
      ]
    ];

    for (int i = 0; i < displayGeodatos.length; i++) {
      if (selectedRows[i]) {
        rows.add([
          displayGeodatos[i]['beneficiary_id'].toString(),
          displayGeodatos[i]['nombre']?.toString() ?? 'Desconocido',
          displayGeodatos[i]['fecha_nacimiento']?.toString() ?? 'No disponible',
          displayGeodatos[i]['edad']?.toString() ?? 'No disponible',
          displayGeodatos[i]['fecha_visita']?.toString() ?? 'No disponible',
          displayGeodatos[i]['address']?.toString() ?? 'No disponible',
          displayGeodatos[i]['telefono']?.toString() ?? 'No disponible',
          displayGeodatos[i]['nombre_madre']?.toString() ?? 'No disponible',
          displayGeodatos[i]['nombre_padre']?.toString() ?? 'No disponible',
          displayGeodatos[i]['nombre_encargado']?.toString() ?? 'No disponible',
          displayGeodatos[i]['hombres']?.toString() ?? 'No disponible',
          displayGeodatos[i]['mujeres']?.toString() ?? 'No disponible',
          displayGeodatos[i]['inscritos_cdi']?.toString() ?? 'No disponible',
          displayGeodatos[i]['con_quien_vive']?.toString() ?? 'No disponible',
          displayGeodatos[i]['como_vive']?.toString() ?? 'No disponible',
          displayGeodatos[i]['tipo_casa']?.toString() ?? 'No disponible',
          displayGeodatos[i]['quienes_trabajan']?.toString() ?? 'No disponible',
          displayGeodatos[i]['trabaja_nino']?.toString() ?? 'No disponible',
          displayGeodatos[i]['observaciones']?.toString() ?? 'No disponible',
          displayGeodatos[i]['uservisita']?.toString() ?? 'Desconocido',
        ]);
      }
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Añadimos el BOM al inicio del CSV
    csv = '\uFEFF' + csv;

    // Obtén el directorio de almacenamiento externo
    final directory = await getExternalStorageDirectory();
    String baseFilePath = path.join(directory!.path, 'geodatos.csv');

    // Verifica si ya existe un archivo con ese nombre
    File file = File(baseFilePath);
    int counter = 1;
    while (await file.exists()) {
      // Si el archivo existe, añade un sufijo numérico
      baseFilePath = path.join(directory.path, 'geodatos($counter).csv');
      file = File(baseFilePath);
      counter++;
    }

    // Crea y guarda el archivo CSV con BOM para que se interpreten bien los caracteres especiales
    await file.writeAsString(csv, encoding: Encoding.getByName('utf-8')!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Archivo CSV exportado en: $baseFilePath',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Función para exportar a PDF
  Future<void> exportToPDF() async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/logogeocompass_31.png'))
          .buffer
          .asUint8List(),
    );
    final currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    final List<List<String>> data = displayGeodatos
        .where((geodato) => selectedRows[displayGeodatos.indexOf(geodato)])
        .map((geodato) => [
              geodato['beneficiary_id'].toString(),
              geodato['nombre']?.toString() ?? 'Desconocido',
              geodato['fecha_nacimiento']?.toString() ?? 'No disponible',
              geodato['edad']?.toString() ?? 'No disponible',
              geodato['fecha_visita']?.toString() ?? 'No disponible',
              geodato['address']?.toString() ?? 'No disponible',
              geodato['telefono']?.toString() ?? 'No disponible',
              geodato['nombre_madre']?.toString() ?? 'No disponible',
              geodato['nombre_padre']?.toString() ?? 'No disponible',
              geodato['nombre_encargado']?.toString() ?? 'No disponible',
              geodato['hombres']?.toString() ?? 'No disponible',
              geodato['mujeres']?.toString() ?? 'No disponible',
              geodato['inscritos_cdi']?.toString() ?? 'No disponible',
              geodato['con_quien_vive']?.toString() ?? 'No disponible',
              geodato['como_vive']?.toString() ?? 'No disponible',
              geodato['tipo_casa']?.toString() ?? 'No disponible',
              geodato['quienes_trabajan']?.toString() ?? 'No disponible',
              geodato['trabaja_nino']?.toString() ?? 'No disponible',
              geodato['observaciones']?.toString() ?? 'No disponible',
              geodato['uservisita']?.toString() ?? 'Desconocido',
            ])
        .toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 50, height: 50),
                  pw.Text('Reporte de Geovisitas',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Fecha: $currentDate\nHora: $currentTime',
                      style: pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  'ID',
                  'Nombre',
                  'Fecha Nacimiento',
                  'Edad',
                  'Fecha Visita',
                  'Direccion',
                  'Telefono',
                  'Nombre Madre',
                  'Nombre Padre',
                  'Nombre Encargado',
                  'Hombres',
                  'Mujeres',
                  'Inscritos CDI',
                  'Con Quien Vive',
                  'Como Vive',
                  'Tipo Casa',
                  'Quienes Trabajan',
                  'Trabaja Niño',
                  'Observaciones',
                  'Tutor Visita'
                ],
                data: data,
              ),
            ],
          );
        },
      ),
    );

    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/geodatos.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Archivo PDF exportado en: ${file.path}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
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
            child: Column(
              children: [
                TextField(
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
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: exportToCSV,
                      icon: Icon(Icons.download),
                      label: Text('Exportar CSV'),
                    ),
                    ElevatedButton.icon(
                      onPressed: exportToPDF,
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text('Exportar PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtrar por Tutor:', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                      applyFilter();
                    });
                  },
                  items: uniqueTutores
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 25,
                  columns: [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Fecha Nacimiento')),
                    DataColumn(label: Text('Edad')),
                    DataColumn(label: Text('Fecha Visita')),
                    DataColumn(label: Text('Direccion')),
                    DataColumn(label: Text('Telefono')),
                    DataColumn(label: Text('Nombre Madre')),
                    DataColumn(label: Text('Nombre Padre')),
                    DataColumn(label: Text('Nombre Encargado')),
                    DataColumn(label: Text('Hombres')),
                    DataColumn(label: Text('Mujeres')),
                    DataColumn(label: Text('Inscritos CDI')),
                    DataColumn(label: Text('Con Quien Vive')),
                    DataColumn(label: Text('Como Vive')),
                    DataColumn(label: Text('Tipo Casa')),
                    DataColumn(label: Text('Quienes Trabajan')),
                    DataColumn(label: Text('Trabaja Niño')),
                    DataColumn(label: Text('Observaciones')),
                    DataColumn(label: Text('Tutor Visita')),
                    DataColumn(label: Text('Seleccionar')),
                  ],
                  rows: List<DataRow>.generate(
                    displayGeodatos.length,
                    (index) => DataRow(
                      selected: selectedRows[index],
                      onSelectChanged: (bool? selected) {
                        setState(() {
                          selectedRows[index] = selected ?? false;
                        });
                      },
                      cells: [
                        DataCell(Text(displayGeodatos[index]['beneficiary_id']
                            .toString())),
                        DataCell(Text(
                            displayGeodatos[index]['nombre']?.toString() ??
                                'Desconocido')),
                        DataCell(Text(displayGeodatos[index]['fecha_nacimiento']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['edad']?.toString() ??
                                'No disponible')),
                        DataCell(Text(displayGeodatos[index]['fecha_visita']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['address']?.toString() ??
                                'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['telefono']?.toString() ??
                                'No disponible')),
                        DataCell(Text(displayGeodatos[index]['nombre_madre']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(displayGeodatos[index]['nombre_padre']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(displayGeodatos[index]['nombre_encargado']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['hombres']?.toString() ??
                                'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['mujeres']?.toString() ??
                                'No disponible')),
                        DataCell(Text(displayGeodatos[index]['inscritos_cdi']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(displayGeodatos[index]['con_quien_vive']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['como_vive']?.toString() ??
                                'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['tipo_casa']?.toString() ??
                                'No disponible')),
                        DataCell(Text(displayGeodatos[index]['quienes_trabajan']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(displayGeodatos[index]['trabaja_nino']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(displayGeodatos[index]['observaciones']
                                ?.toString() ??
                            'No disponible')),
                        DataCell(Text(
                            displayGeodatos[index]['uservisita']?.toString() ??
                                'Desconocido')),
                        DataCell(Checkbox(
                          value: selectedRows[index],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedRows[index] = value ?? false;
                            });
                          },
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
