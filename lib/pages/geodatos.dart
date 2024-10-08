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
  String selectedFilter = 'Todos';
  List<String> uniqueTutores = ['Todos'];

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
          extractUniqueTutores();
        });
      } else {
        throw Exception('Failed to load geodatos');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load data');
    }
  }

  void extractUniqueTutores() {
    Set<String> tutoresSet = {};
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
    csv = '\uFEFF' + csv;

    final directory = await getExternalStorageDirectory();
    String baseFilePath = path.join(directory!.path, 'geodatos.csv');

    File file = File(baseFilePath);
    int counter = 1;
    while (await file.exists()) {
      baseFilePath = path.join(directory.path, 'geodatos($counter).csv');
      file = File(baseFilePath);
      counter++;
    }

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

  Future<void> exportToPDF() async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/logogeocompass_111.png'))
          .buffer
          .asUint8List(),
    );
    final currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

    for (int i = 0; i < displayGeodatos.length; i++) {
      if (selectedRows[i]) {
        final geodato = displayGeodatos[i];

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
                      pw.Text('Registro de Visitas Domiciliarias',
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Fecha: $currentDate\nHora: $currentTime',
                          style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'DATOS PERSONALES',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    headers: [],
                    data: [
                      ['Nombre del Beneficiario(a)', geodato['nombre'] ?? ''],
                      ['Edad', geodato['edad']?.toString() ?? ''],
                      [
                        'Fecha de Nacimiento',
                        geodato['fecha_nacimiento']?.toString() ?? ''
                      ],
                      ['Código', geodato['beneficiary_id'].toString()],
                      ['Dirección', geodato['address'] ?? ''],
                      ['Teléfono', geodato['telefono']?.toString() ?? ''],
                      [
                        'Fecha que efectuaron la visita',
                        geodato['fecha_visita']
                      ]
                    ],
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    cellStyle: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'ASPECTOS FAMILIARES',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    headers: [],
                    data: [
                      ['Nombre de la Madre', geodato['nombre_madre'] ?? ''],
                      ['Nombre del Padre', geodato['nombre_padre'] ?? ''],
                      [
                        'Nombre del Encargado',
                        geodato['nombre_encargado'] ?? ''
                      ],
                      [
                        'Cantidad de Hijos (Hombres/Mujeres)',
                        '${geodato['hombres'] ?? ''} / ${geodato['mujeres'] ?? ''}'
                      ],
                      [
                        'Inscritos en el C.D.I. Peña de Horeb',
                        geodato['inscritos_cdi']?.toString() ?? ''
                      ],
                      [
                        'Con quién vive el niño',
                        geodato['con_quien_vive'] ?? ''
                      ],
                    ],
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    cellStyle: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'ASPECTO DOMICILIAR',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    headers: [],
                    data: [
                      [
                        'Casa (Propia/Alquilada/Prestada)',
                        geodato['tipo_casa']?.toString() ?? ''
                      ],
                      ['Tipo de Casa', geodato['como_vive'] ?? ''],
                    ],
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    cellStyle: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'ASPECTO LABORAL',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    headers: [],
                    data: [
                      ['Quienes Trabajan', geodato['quienes_trabajan'] ?? ''],
                      ['Trabaja el niño', geodato['trabaja_nino'] ?? ''],
                    ],
                    border: pw.TableBorder.all(color: PdfColors.grey600),
                    cellStyle: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Observaciones: ${geodato['observaciones'] ?? ''}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(
                      height:
                          150), // Añadir un espacio entre observaciones y Vo.Bo.
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Vo.Bo. DIRECTOR'),
                      pw.Text('Vo.Bo. Coordinador de Programas'),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    final directory = await getExternalStorageDirectory();
    String baseFilePath = path.join(directory!.path, 'geodatos.pdf');

    File file = File(baseFilePath);
    int counter = 1;
    while (await file.exists()) {
      baseFilePath = path.join(directory.path, 'geodatos($counter).pdf');
      file = File(baseFilePath);
      counter++;
    }

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
