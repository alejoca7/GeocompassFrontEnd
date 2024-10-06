import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'geovisitas.dart';
import 'package:intl/intl.dart';

class Geopoint extends StatefulWidget {
  @override
  _GeopointState createState() => _GeopointState();
}

class _GeopointState extends State<Geopoint> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  XFile? selectedImageFile;
  String? selectedImageUrl;
  Set<Marker> markers = {};
  BitmapDescriptor? customIcon;
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};
  MapType _currentMapType = MapType.normal;
  TextEditingController _searchController = TextEditingController();
  int? selectedMarkerId;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
    _requestLocationPermission();
    _fetchAndDisplayGeopoints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  Future<void> _showInstructionsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instrucciones'),
          content: Text(
            'Puedes agregar un punto en tu ubicación actual presionando el botón +. '
            'También puedes mantener presionado el mapa para agregar un punto en una ubicación específica.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ENTENDIDO'),
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print('Permisos de ubicación denegados permanentemente.');
        return;
      }
    }
    if (permission == LocationPermission.denied) {
      print('Permisos de ubicación denegados.');
      return;
    }
    _moveToCurrentLocation();
  }

  Future<void> _loadCustomIcon() async {
    try {
      customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/custom_icon.png',
      );
    } catch (e) {
      print("Error al cargar el ícono personalizado: $e");
    }
  }

  Future<void> _fetchAndDisplayGeopoints() async {
    final response = await http
        .get(Uri.parse('https://geocompass-back-omega.vercel.app/geopoints'));

    if (response.statusCode == 200) {
      final List<dynamic> geopoints = jsonDecode(response.body);

      setState(() {
        markers.clear();
        for (var geopoint in geopoints) {
          final LatLng position =
              LatLng(geopoint['latitude'], geopoint['longitude']);
          final Marker marker = Marker(
            markerId: MarkerId(geopoint['ID'].toString()),
            position: position,
            icon: customIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title:
                  'Código Niño: ${geopoint['beneficiary_id']} - ${geopoint['nombre']}',
              snippet: geopoint['address'],
              onTap: () {
                setState(() {
                  selectedMarkerId = geopoint['ID'];
                });
                _showInfoWindow(
                  geopoint['ID'],
                  geopoint['beneficiary_id'],
                  geopoint['nombre'],
                  geopoint['address'],
                  geopoint['fecha_nacimiento'],
                  geopoint['edad'],
                  geopoint['telefono'],
                  geopoint['image_url'],
                );
              },
            ),
          );

          markers.add(marker);
        }
      });
    } else {
      print('Error al obtener geopoints: ${response.statusCode}');
    }
  }

  Future<void> _addNewPointAtCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        selectedImageFile = null;
        selectedImageUrl = null;
      });
      _showGeopointDialog();
    } catch (e) {
      print('Error al obtener la ubicación actual: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación actual')),
      );
    }
  }

  void _onMapLongClick(LatLng coordinates) {
    setState(() {
      selectedLocation = coordinates;
      selectedImageFile = null;
      selectedImageUrl = null;
    });
    _showGeopointDialog();
  }

  Future<void> _selectImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (image != null) {
      setState(() {
        selectedImageFile = image;
      });
    }
  }

  void _showGeopointDialog() {
    final TextEditingController beneficiaryIDController =
        TextEditingController();
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController fechaNacimientoController =
        TextEditingController();
    final TextEditingController edadController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Guardar Punto de Geolocalización'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: beneficiaryIDController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Código del Beneficiario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: fechaNacimientoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
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
                          setState(() {
                            fechaNacimientoController.text =
                                DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: edadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    selectedImageFile != null
                        ? Column(
                            children: [
                              Image.file(
                                File(selectedImageFile!.path),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _selectImage().then((_) {
                                  setState(() {});
                                }),
                                icon: Icon(Icons.camera_alt),
                                label: Text('Repetir Fotografía'),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _selectImage().then((_) {
                              setState(() {});
                            }),
                            icon: Icon(Icons.camera_alt),
                            label: Text('Tomar Fotografía'),
                          ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Guardar'),
                  onPressed: () async {
                    if (selectedLocation == null ||
                        beneficiaryIDController.text.isEmpty ||
                        nombreController.text.isEmpty ||
                        addressController.text.isEmpty ||
                        fechaNacimientoController.text.isEmpty ||
                        edadController.text.isEmpty ||
                        telefonoController.text.isEmpty ||
                        selectedImageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Por favor, complete todos los campos.'),
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    await _uploadImage();

                    await _saveGeopoint(
                      int.parse(beneficiaryIDController.text),
                      nombreController.text,
                      selectedLocation!,
                      addressController.text,
                      fechaNacimientoController.text,
                      int.parse(edadController.text),
                      telefonoController.text,
                      selectedImageUrl ?? '',
                    );

                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    if (selectedImageFile == null) return;

    final bytes = await selectedImageFile!.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://geocompass-back-omega.vercel.app/upload'), // URL de tu backend
    )..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: selectedImageFile!.name,
        ),
      );

    final res = await request.send();
    final resBody = await http.Response.fromStream(res);

    if (res.statusCode == 200) {
      final imageUrl = jsonDecode(resBody.body)['image_url'];
      setState(() {
        selectedImageUrl = imageUrl; // Guardar la URL de la imagen subida
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen')),
      );
    }
  }

  Future<void> _saveGeopoint(
    int beneficiaryID,
    String nombre,
    LatLng location,
    String address,
    String fechaNacimiento,
    int edad,
    String telefono,
    String imageURL, // URL de la imagen subida
  ) async {
    final response = await http.post(
      Uri.parse('https://geocompass-back-omega.vercel.app/geopoints'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'beneficiary_id': beneficiaryID,
        'nombre': nombre,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': address,
        'fecha_nacimiento': fechaNacimiento,
        'edad': edad,
        'telefono': telefono,
        'image_url': imageURL, // Enviar la URL de la imagen al backend
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geopoint guardado con éxito')),
      );

      final geopoint = jsonDecode(response.body);

      final Marker marker = Marker(
        markerId: MarkerId(geopoint['ID'].toString()),
        position: location,
        icon: customIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: 'Código Niño: $beneficiaryID - $nombre',
          snippet: address,
          onTap: () {
            _navigateToGeovisitas(context,
                beneficiaryID: beneficiaryID,
                nombre: nombre,
                address: address,
                fechaNacimiento: fechaNacimiento,
                edad: edad,
                telefono: telefono);
          },
        ),
      );

      setState(() {
        markers.add(marker);
      });

      await _fetchAndDisplayGeopoints();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el geopoint')),
      );
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 14));
    } catch (e) {
      print('Error al obtener la ubicación actual: $e');
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  Future<void> _searchBeneficiaryById(String beneficiaryId) async {
    int beneficiaryIDInt = int.tryParse(beneficiaryId) ?? -1;

    if (beneficiaryIDInt == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID de Beneficiario inválido')),
      );
      return;
    }

    Marker? foundMarker;
    for (var marker in markers) {
      if (marker.infoWindow.title?.contains('Código Niño: $beneficiaryIDInt') ??
          false) {
        foundMarker = marker;
        break;
      }
    }

    if (foundMarker != null) {
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(foundMarker.position, 16));
      mapController.showMarkerInfoWindow(foundMarker.markerId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beneficiario no encontrado')),
      );
    }
  }

  void _navigateToGeovisitas(BuildContext context,
      {required int beneficiaryID,
      required String nombre,
      required String address,
      required String fechaNacimiento,
      required int edad,
      required String telefono}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Geovisitas(
          beneficiaryID: beneficiaryID,
          nombre: nombre,
          address: address,
          fechaNacimiento: fechaNacimiento,
          edad: edad,
          telefono: telefono,
        ),
      ),
    );
  }

  void _showInfoWindow(int id, int beneficiaryID, String nombre, String address,
      String fechaNacimiento, int edad, String telefono, String imageUrl) {
    imageUrl = imageUrl.replaceAll('localhost', '192.168.1.68');
    imageUrl = imageUrl.replaceAll(r'\\', '/');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Información del Beneficiario'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Código Beneficiario: $beneficiaryID',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'Nombre: $nombre',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'Dirección: $address',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'Fecha de Nacimiento: $fechaNacimiento',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'Edad: $edad',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 5),
                Text(
                  'Teléfono: $telefono',
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(height: 10),
                Text(
                  'Fachada de vivienda:',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                if (imageUrl.isNotEmpty &&
                    Uri.tryParse(imageUrl)?.hasAbsolutePath == true)
                  GestureDetector(
                    onTap: () {
                      _showExpandedImage(imageUrl);
                    },
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return const Text('No se pudo cargar la imagen');
                      },
                    ),
                  )
                else
                  const Text('URL de imagen no válida o imagen no disponible'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                _navigateToGeovisitas(
                  context,
                  beneficiaryID: beneficiaryID,
                  nombre: nombre,
                  address: address,
                  fechaNacimiento: fechaNacimiento,
                  edad: edad,
                  telefono: telefono,
                );
              },
              child: Text('Llenar Geovisita'),
            ),
            TextButton(
              onPressed: () {
                _showEditDeleteDialog(id, beneficiaryID, nombre, address,
                    fechaNacimiento, edad, telefono, imageUrl);
              },
              child: Text('Opciones'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeleteDialog(
      int id,
      int beneficiaryID,
      String nombre,
      String address,
      String fechaNacimiento,
      int edad,
      String telefono,
      String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Opciones'),
          content: Text('¿Qué te gustaría hacer con este punto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog(id, beneficiaryID, nombre, address,
                    fechaNacimiento, edad, telefono, imageUrl);
              },
              child: Text('Editar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(
                    id); // Mostrar confirmación antes de eliminar
              },
              child: Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text('¿Está seguro de que desea eliminar este geopoint?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteGeopoint(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGeopoint(int id) async {
    final response = await http.delete(
      Uri.parse('https://geocompass-back-omega.vercel.app/geopoints/$id'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geopoint eliminado con éxito')),
      );
      setState(() {
        markers.removeWhere((marker) => marker.markerId.value == id.toString());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el geopoint')),
      );
    }
  }

  void _showEditDialog(int id, int beneficiaryID, String nombre, String address,
      String fechaNacimiento, int edad, String telefono, String imageUrl) {
    final TextEditingController beneficiaryIDController =
        TextEditingController(text: beneficiaryID.toString());
    final TextEditingController nombreController =
        TextEditingController(text: nombre);
    final TextEditingController addressController =
        TextEditingController(text: address);
    final TextEditingController fechaNacimientoController =
        TextEditingController(text: fechaNacimiento);
    final TextEditingController edadController =
        TextEditingController(text: edad.toString());
    final TextEditingController telefonoController =
        TextEditingController(text: telefono);

    selectedImageFile = null; // Reiniciar imagen seleccionada

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Punto de Geolocalización'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: beneficiaryIDController,
                      readOnly: true, // Bloquear la edición del beneficiaryID
                      decoration: InputDecoration(
                        labelText: 'Código del Beneficiario (No editable)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: fechaNacimientoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        border: OutlineInputBorder(),
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
                          setState(() {
                            fechaNacimientoController.text =
                                DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: edadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    selectedImageFile != null
                        ? Column(
                            children: [
                              Image.file(
                                File(selectedImageFile!.path),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _selectImage().then((_) {
                                  setState(() {});
                                }),
                                icon: Icon(Icons.camera_alt),
                                label: Text('Repetir Fotografía'),
                              ),
                            ],
                          )
                        : imageUrl.isNotEmpty &&
                                Uri.tryParse(imageUrl)?.hasAbsolutePath == true
                            ? Column(
                                children: [
                                  Image.network(
                                    imageUrl,
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Text(
                                          'No se pudo cargar la imagen');
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _selectImage().then((_) {
                                      setState(() {});
                                    }),
                                    icon: Icon(Icons.camera_alt),
                                    label: Text('Repetir Fotografía'),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _selectImage().then((_) {
                                  setState(() {});
                                }),
                                icon: Icon(Icons.camera_alt),
                                label: Text('Tomar Fotografía'),
                              ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Guardar Cambios'),
                  onPressed: () async {
                    if (selectedImageFile != null) {
                      await _uploadImage();
                    }

                    // Agregamos mensajes de depuración para revisar los valores
                    print('Datos a actualizar:');
                    print('Nombre: ${nombreController.text}');
                    print('Dirección: ${addressController.text}');
                    print(
                        'Fecha de Nacimiento: ${fechaNacimientoController.text}');
                    print('Edad: ${edadController.text}');
                    print('Teléfono: ${telefonoController.text}');

                    await _updateGeopoint(
                      id,
                      beneficiaryID,
                      nombreController.text,
                      addressController.text,
                      fechaNacimientoController.text,
                      int.parse(edadController.text),
                      telefonoController.text,
                      selectedImageUrl ?? imageUrl,
                    );

                    Navigator.of(context).pop(); // Cerrar el dialogo
                    _fetchAndDisplayGeopoints(); // Actualizar puntos en el mapa
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateGeopoint(
      int id,
      int beneficiaryID,
      String nombre,
      String address,
      String fechaNacimiento,
      int edad,
      String telefono,
      String imageURL) async {
    Marker? currentMarker;
    try {
      currentMarker = markers
          .firstWhere((marker) => marker.markerId.value == id.toString());

      final double latitude = currentMarker.position.latitude;
      final double longitude = currentMarker.position.longitude;

      // Agregamos mensajes de depuración para revisar qué datos se están enviando
      print('Enviando actualización al servidor...');
      print('ID: $id');
      print('Nombre: $nombre');
      print('Dirección: $address');
      print('Fecha de Nacimiento: $fechaNacimiento');
      print('Edad: $edad');
      print('Teléfono: $telefono');

      final response = await http.put(
        Uri.parse('https://geocompass-back-omega.vercel.app/geopoints/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'beneficiary_id': beneficiaryID,
          'nombre': nombre,
          'latitude': latitude, // Mantener latitud existente
          'longitude': longitude, // Mantener longitud existente
          'address': address,
          'fecha_nacimiento':
              fechaNacimiento, // Enviar valor de fecha de nacimiento
          'edad': edad, // Enviar valor de edad
          'telefono': telefono, // Enviar valor de teléfono
          'image_url': imageURL,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geopoint actualizado con éxito')),
        );
      } else {
        print('Error en la respuesta del servidor: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el geopoint')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al encontrar el geopoint para actualizar.')),
      );
      return;
    }
  }

  void _showExpandedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return const Text('No se pudo cargar la imagen');
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geopoint'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(15.469408, -90.379583),
              zoom: 14.0,
            ),
            mapType: _currentMapType,
            markers: markers,
            polylines: _polylines,
            polygons: _polygons,
            onLongPress: _onMapLongClick,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por Código de Beneficiario',
                fillColor: Colors.white,
                filled: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchBeneficiaryById(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                _searchBeneficiaryById(value);
              },
            ),
          ),
          Positioned(
            bottom: 120,
            left: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'help',
                  onPressed: _showInstructionsDialog,
                  child: Icon(Icons.help_outline),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _moveToCurrentLocation,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'layers',
                  onPressed: _toggleMapType,
                  child: Icon(Icons.layers),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPointAtCurrentLocation,
        tooltip: 'Agregar punto en la ubicación actual',
        child: Image.asset(
          'assets/images/add-location.png',
          height: 40,
          width: 40,
        ),
        backgroundColor: Colors.blue[400],
      ),
    );
  }
}
