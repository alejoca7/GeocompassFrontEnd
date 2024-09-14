import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
    final response =
        await http.get(Uri.parse('http://192.168.1.68:8080/geopoints'));

    if (response.statusCode == 200) {
      final List<dynamic> geopoints = jsonDecode(response.body);

      setState(() {
        markers.clear();
        for (var geopoint in geopoints) {
          final LatLng position =
              LatLng(geopoint['latitude'], geopoint['longitude']);
          final Marker marker = Marker(
            markerId: MarkerId(geopoint['beneficiary_id']
                .toString()), // Mostrar beneficiary_id
            position: position,
            icon: customIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title:
                  'Código Niño: ${geopoint['beneficiary_id']} - ${geopoint['nombre']}',
              snippet: geopoint['address'],
              onTap: () {
                setState(() {
                  selectedMarkerId = geopoint['beneficiary_id'];
                });
                _showInfoWindow(
                  geopoint['ID'],
                  geopoint['beneficiary_id'],
                  geopoint['nombre'],
                  geopoint['address'],
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
                    if (selectedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seleccione una ubicación en el mapa.'),
                        ),
                      );
                      return;
                    }

                    if (beneficiaryIDController.text.isEmpty ||
                        nombreController.text.isEmpty ||
                        addressController.text.isEmpty ||
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
                      selectedImageUrl ?? '',
                    );

                    Navigator.of(context).pop(); // Cerrar el dialog de progreso
                    Navigator.of(context).pop(); // Cerrar el dialog principal
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
      Uri.parse('http://192.168.1.68:8080/upload'),
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
        selectedImageUrl = imageUrl;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen')),
      );
    }
  }

  Future<void> _saveGeopoint(int beneficiaryID, String nombre, LatLng location,
      String address, String imageURL) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.68:8080/geopoints'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'beneficiary_id': beneficiaryID,
        'nombre': nombre,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': address,
        'image_url': imageURL,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geopoint guardado con éxito')),
      );

      final Marker marker = Marker(
        markerId: MarkerId(beneficiaryID
            .toString()), // Usar el beneficiary_id como ID del marcador
        position: location,
        icon: customIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: 'Código Niño: $beneficiaryID - $nombre',
          snippet: address,
          onTap: () {
            _showInfoWindow(0, beneficiaryID, nombre, address,
                imageURL); // Mostrar beneficiary_id
          },
        ),
      );

      setState(() {
        markers.add(marker);
      });
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

  void _showInfoWindow(int id, int beneficiaryID, String nombre, String address,
      String imageUrl) {
    imageUrl = imageUrl.replaceAll('localhost', '192.168.1.68');
    imageUrl = imageUrl.replaceAll(r'\', '/');

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
                _showEditDeleteDialog(
                    id, beneficiaryID, nombre, address, imageUrl);
              },
              child: Text('Opciones'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeleteDialog(int id, int beneficiaryID, String nombre,
      String address, String imageUrl) {
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
                _showEditDialog(id, beneficiaryID, nombre, address, imageUrl);
              },
              child: Text('Editar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteGeopoint(id);
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

  Future<void> _deleteGeopoint(int id) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.68:8080/geopoints/$id'),
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
      String imageUrl) {
    final TextEditingController beneficiaryIDController =
        TextEditingController(text: beneficiaryID.toString());
    final TextEditingController nombreController =
        TextEditingController(text: nombre);
    final TextEditingController addressController =
        TextEditingController(text: address);

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
                  child: Text('Guardar Cambios'),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    await _uploadImage();
                    await _updateGeopoint(
                      id,
                      int.parse(beneficiaryIDController.text),
                      nombreController.text,
                      addressController.text,
                      selectedImageUrl ?? imageUrl,
                    );

                    Navigator.of(context).pop(); // Cerrar el dialog de progreso
                    Navigator.of(context).pop(); // Cerrar el dialog principal
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateGeopoint(int id, int beneficiaryID, String nombre,
      String address, String imageURL) async {
    // Obtener las coordenadas actuales del punto que se está editando
    Marker? currentMarker;
    try {
      currentMarker = markers
          .firstWhere((marker) => marker.markerId.value == id.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al encontrar el geopoint para actualizar.')),
      );
      return;
    }

    // Mantener las coordenadas originales si no han cambiado
    final double latitude = currentMarker.position.latitude;
    final double longitude = currentMarker.position.longitude;

    final response = await http.put(
      Uri.parse('http://192.168.1.68:8080/geopoints/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'beneficiary_id': beneficiaryID,
        'nombre': nombre,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'image_url': imageURL,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geopoint actualizado con éxito')),
      );
      _fetchAndDisplayGeopoints();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el geopoint')),
      );
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
