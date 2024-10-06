import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Geovisitas extends StatefulWidget {
  final int? beneficiaryID;
  final String? nombre;
  final String? address;
  final String? fechaNacimiento; // Nuevo campo
  final int? edad; // Nuevo campo
  final String? telefono; // Nuevo campo

  Geovisitas({
    this.beneficiaryID,
    this.nombre,
    this.address,
    this.fechaNacimiento,
    this.edad,
    this.telefono,
  });

  @override
  _GeovisitasState createState() => _GeovisitasState();
}

class _GeovisitasState extends State<Geovisitas> {
  // Controladores para los campos de texto
  TextEditingController beneficiaryIDController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController fechaNacimientoController = TextEditingController();
  TextEditingController edadController = TextEditingController();
  TextEditingController fechaVisitaController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController telefonoController = TextEditingController();
  TextEditingController nombreMadreController = TextEditingController();
  TextEditingController nombrePadreController = TextEditingController();
  TextEditingController nombreEncargadoController = TextEditingController();
  TextEditingController hombresController = TextEditingController();
  TextEditingController mujeresController = TextEditingController();
  TextEditingController inscritosCdiController = TextEditingController();
  TextEditingController observacionesController = TextEditingController();
  TextEditingController usuarioVisitaController =
      TextEditingController(); // Nuevo campo

  // Variables para Dropdowns
  String conQuienVive = 'Seleccione una opción';
  String comoVive = 'Seleccione una opción';
  String tipoCasa = 'Seleccione una opción';
  String quienesTrabajan = 'Seleccione una opción';
  String trabajaElNino = 'Seleccione una opción';

  @override
  void initState() {
    super.initState();
    // Prellenar los campos solo si se proporcionan los datos desde Geopoint
    if (widget.beneficiaryID != null) {
      beneficiaryIDController.text = widget.beneficiaryID.toString();
    }
    if (widget.nombre != null) {
      nombreController.text = widget.nombre!;
    }
    if (widget.address != null) {
      addressController.text = widget.address!;
    }
    if (widget.fechaNacimiento != null) {
      fechaNacimientoController.text = widget.fechaNacimiento!;
    }
    if (widget.edad != null) {
      edadController.text = widget.edad.toString();
    }
    if (widget.telefono != null) {
      telefonoController.text = widget.telefono!;
    }
  }

  // Función para enviar datos a la API con validaciones
  Future<void> enviarEncuesta() async {
    if (!_validarCamposObligatorios()) {
      _mostrarMensajeError();
      return;
    }

    try {
      final url =
          Uri.parse('https://geocompass-back-omega.vercel.app/geovisitas');
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'beneficiary_id': int.parse(beneficiaryIDController.text),
          'nombre': nombreController.text,
          'fecha_nacimiento': fechaNacimientoController.text,
          'edad': int.parse(edadController.text),
          'fecha_visita': fechaVisitaController.text,
          'address': addressController.text,
          'telefono': telefonoController.text,
          'nombre_madre': nombreMadreController.text,
          'nombre_padre': nombrePadreController.text,
          'nombre_encargado': nombreEncargadoController.text,
          'hombres': int.parse(hombresController.text),
          'mujeres': int.parse(mujeresController.text),
          'inscritos_cdi': int.parse(inscritosCdiController.text),
          'con_quien_vive': conQuienVive,
          'como_vive': comoVive,
          'tipo_casa': tipoCasa,
          'quienes_trabajan': quienesTrabajan,
          'trabaja_nino': trabajaElNino,
          'observaciones': observacionesController.text,
          'uservisita': usuarioVisitaController.text, // Nuevo campo agregado
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al enviar la encuesta: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error al enviar la encuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la encuesta: $e')),
      );
    }
  }

  // Función para validar los campos obligatorios
  bool _validarCamposObligatorios() {
    return beneficiaryIDController.text.isNotEmpty &&
        nombreController.text.isNotEmpty &&
        fechaVisitaController.text.isNotEmpty &&
        fechaNacimientoController.text.isNotEmpty &&
        telefonoController.text.isNotEmpty &&
        usuarioVisitaController.text
            .isNotEmpty; // Asegurarse que el campo usuario visita no esté vacío
  }

  // Mostrar mensaje de error si los campos no están completos
  void _mostrarMensajeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Por favor, complete todos los campos obligatorios.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Función para mostrar una ventana emergente de éxito
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Encuesta enviada"),
          content: Text("La encuesta se ha enviado exitosamente."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función para resetear el formulario
  void _resetForm() {
    beneficiaryIDController.clear();
    nombreController.clear();
    fechaNacimientoController.clear();
    edadController.clear();
    fechaVisitaController.clear();
    addressController.clear();
    telefonoController.clear();
    nombreMadreController.clear();
    nombrePadreController.clear();
    nombreEncargadoController.clear();
    hombresController.clear();
    mujeresController.clear();
    inscritosCdiController.clear();
    observacionesController.clear();
    usuarioVisitaController.clear(); // Limpiar el campo usuario visita
    setState(() {
      conQuienVive = 'Seleccione una opción';
      comoVive = 'Seleccione una opción';
      tipoCasa = 'Seleccione una opción';
      quienesTrabajan = 'Seleccione una opción';
      trabajaElNino = 'Seleccione una opción';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150.0),
        child: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Color(0xFF003366),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Image.asset('assets/images/logogeocompass_31.png', height: 90),
              SizedBox(height: 10),
              Text(
                'GEOVISITAS',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Datos Personales',
                color: Color(0xFF00C7BE),
                child: Column(
                  children: [
                    TextFieldInput(
                      label: 'Beneficiary ID',
                      controller: beneficiaryIDController,
                      keyboardType: TextInputType.number,
                      showError: beneficiaryIDController.text.isEmpty,
                    ),
                    TextFieldInput(
                      label: 'Nombre beneficiario (a)',
                      controller: nombreController,
                      keyboardType: TextInputType.text,
                      showError: nombreController.text.isEmpty,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DateInputField(
                            controller: fechaNacimientoController,
                            label: 'Fecha de nacimiento',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFieldInput(
                            label: 'Edad',
                            controller: edadController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 0),
                        Expanded(
                          child: DateInputField(
                            controller: fechaVisitaController,
                            label: 'Fecha visita',
                          ),
                        ),
                      ],
                    ),
                    TextFieldInput(
                      label: 'Dirección',
                      controller: addressController,
                      keyboardType: TextInputType.text,
                    ),
                    TextFieldInput(
                      label: 'Teléfono',
                      controller: telefonoController,
                      keyboardType: TextInputType.phone,
                      showError: telefonoController.text.isEmpty,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Aspectos Familiares',
                color: Color(0xFF34C759),
                child: Column(
                  children: [
                    TextFieldInput(
                      label: 'Nombre de la madre',
                      controller: nombreMadreController,
                      keyboardType: TextInputType.text,
                    ),
                    TextFieldInput(
                      label: 'Nombre del padre',
                      controller: nombrePadreController,
                      keyboardType: TextInputType.text,
                    ),
                    TextFieldInput(
                      label: 'Nombre de encargado (a)',
                      controller: nombreEncargadoController,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFieldInput(
                            label: 'Hombres',
                            controller: hombresController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextFieldInput(
                            label: 'Mujeres',
                            controller: mujeresController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextFieldInput(
                      label: 'Inscritos en el C.D.I. Pena de Horeb',
                      controller: inscritosCdiController,
                      keyboardType: TextInputType.number,
                    ),
                    DropdownField(
                      label: 'Con quién vive el nino (a)',
                      items: [
                        'Seleccione una opción',
                        'Padre',
                        'Madre',
                        'Padre/Madre'
                      ],
                      value: conQuienVive,
                      onChanged: (value) {
                        setState(() {
                          conQuienVive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Aspecto Domiciliar',
                color: Color(0xFFFFCC00),
                child: Column(
                  children: [
                    DropdownField(
                      label: 'Cómo vive',
                      items: [
                        'Seleccione una opción',
                        'Casa propia',
                        'Alquilada',
                        'Prestada'
                      ],
                      value: comoVive,
                      onChanged: (value) {
                        setState(() {
                          comoVive = value;
                        });
                      },
                    ),
                    DropdownField(
                      label: 'Tipo de casa',
                      items: ['Seleccione una opción', 'Madera', 'Block'],
                      value: tipoCasa,
                      onChanged: (value) {
                        setState(() {
                          tipoCasa = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildSection(
                title: 'Aspecto Laboral',
                color: Color(0xFF007AFF),
                child: Column(
                  children: [
                    DropdownField(
                      label: 'Quiénes trabajan',
                      items: [
                        'Seleccione una opción',
                        'Papa',
                        'Mama',
                        'Papa/Mama',
                        'Otros'
                      ],
                      value: quienesTrabajan,
                      onChanged: (value) {
                        setState(() {
                          quienesTrabajan = value;
                        });
                      },
                    ),
                    DropdownField(
                      label: 'Trabaja el nino',
                      items: ['Seleccione una opción', 'Si', 'No'],
                      value: trabajaElNino,
                      onChanged: (value) {
                        setState(() {
                          trabajaElNino = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildTitle('Observaciones', Color(0xFFFF2D55)),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: observacionesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Ingrese observaciones...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFieldInput(
                label: 'Tutor Visita', // Nuevo campo de usuario visita
                controller: usuarioVisitaController,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: enviarEncuesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003366),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Enviar Encuesta',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required Color color, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 18, color: color),
          ),
          Divider(color: Colors.grey[400], thickness: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style:
            TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color),
      ),
    );
  }
}

// Componentes auxiliares...

class TextFieldInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool showError;

  const TextFieldInput({
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (showError && controller.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                "* Campo obligatorio",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class DateInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const DateInputField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          }
        },
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;

  const DropdownField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ),
    );
  }
}
