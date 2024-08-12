import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../widget/navigation_drawer.dart';

class MapScreen extends StatefulWidget {
  final LatLng location;

  // Constructor with required location parameter
  MapScreen({required this.location});

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<LatLng> _userLocations = [];
  int _currentUserIndex = 0;



  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }







  Future<void> _loadMarkers() async {
    List<Map<String, dynamic>> users = await getMaliciousUsers();

    List<LatLng> locations = [];
    Set<Marker> markers = {};

    // Create a DateFormat instance for the desired format
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final DateFormat timeFormat = DateFormat('h:mm a'); // 12-hour format with am/pm

    for (var user in users) {
      final LatLng position = LatLng(user['latitude'], user['longitude']);
      final DateTime tt = (user['timestamp'] as Timestamp).toDate(); // Convert Firestore Timestamp to DateTime

      // Format the date and time
      final String formattedDate = dateFormat.format(tt);
      final String formattedTime = timeFormat.format(tt);
      final String formattedTimestamp = '$formattedDate $formattedTime';

      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot userDoc = await firestore.collection('users').doc(user['userId']).get();
      final String pfpURL = userDoc['pfpURL'];
      String name = userDoc['email'];
      name = name.split('@')[0];

      final BitmapDescriptor icon = await getBitmapDescriptorFromUrl(pfpURL);

      markers.add(Marker(
        markerId: MarkerId(name),
        position: position,
        infoWindow: InfoWindow(title: name, snippet: formattedTimestamp),
        icon: icon,
      ));

      locations.add(position);
    }

    setState(() {
      _markers.addAll(markers);
      _userLocations = locations;
      if (_userLocations.isNotEmpty) {
        _setCameraToLocation(_userLocations[_currentUserIndex]);
      }else{
        _setCameraToLocation(widget.location);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMaliciousUsers() async {
    final firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('malicious_users').get();

    List<Map<String, dynamic>> users = [];
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      userData['userId'] = doc.id; // Add the document ID as userId
      users.add(userData);
    }

    return users;
  }



  Future<BitmapDescriptor> getBitmapDescriptorFromUrl(String url) async {
    try {
      // Load image data from URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      // Decode the image data
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Create a circular image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(48, 48)));

      final paint = Paint()
        ..isAntiAlias = true
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final radius = 24.0;
      final center = Offset(radius, radius);

      // Draw a circular clip
      canvas.drawCircle(center, radius, paint);

      // Draw the image
      paint.blendMode = BlendMode.srcIn;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, 48, 48),
        paint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(48, 48);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      // Convert bytes to BitmapDescriptor
      return BitmapDescriptor.bytes(pngBytes!);
    } catch (e) {
      print('Error loading or processing image: $e');
      // Fallback icon if the image fails to load
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _setCameraToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  void _moveToNextUser() {
    if (_userLocations.isNotEmpty) {
      setState(() {
        _currentUserIndex = (_currentUserIndex + 1) % _userLocations.length;
        _setCameraToLocation(_userLocations[_currentUserIndex]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Malicious Users Map'),
      ),
      drawer: NavigationDrawerWidget(initialSelectedIndex: 3),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            mapType: MapType.normal,
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: _userLocations.isNotEmpty ? _userLocations[0] : widget.location,
              zoom: 17.0, // Adjust zoom level as needed
            ),
          ),
          Positioned(
            top: 10,
            right: 0,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.black), // Set button color to blue
                minimumSize: WidgetStateProperty.all(Size(80, 40)), // Adjust size of the button
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Optional: Add rounded corners
                )),
              ),
              onPressed: _moveToNextUser,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    color: Colors.white,
                    Icons.arrow_forward,
                    size: 30, // Make the icon bigger
                  ),
                  SizedBox(width: 8), // Add some space between the icon and text
                  Text(
                    _userLocations.isNotEmpty?'Check Next':'No Malacious User Found',
                    style: TextStyle(
                      fontSize: 16, // Adjust font size as needed
                      color: Colors.white, // Set text color to white
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}