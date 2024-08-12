import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'package:cryp_comm/service/alert_service.dart';
import 'package:cryp_comm/service/auth_service.dart';
import 'package:cryp_comm/service/database_service.dart';
import 'package:cryp_comm/service/media_service.dart';
import 'package:cryp_comm/service/navigation_service.dart';
import 'package:cryp_comm/service/notification_service.dart';
import 'package:cryp_comm/service/storage_service.dart';
import 'package:cryp_comm/splash_screen.dart';

// Initialize secure storage
final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await registerServices();

  // Save user location when app starts
  await getUserLocation();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryp_Comm',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

Future<void> registerServices() async {
  final getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<NavigationService>(NavigationService());
  getIt.registerSingleton<AlertService>(AlertService());
  getIt.registerSingleton<MediaService>(MediaService());
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<DatabaseService>(DatabaseService());
  getIt.registerSingleton<PushNotificationService>(PushNotificationService());
}

// Function to generate a chat ID
String generateChatID({required String uid1, required String uid2}) {
  List<String> uids = [uid1, uid2];
  uids.sort();
  return uids.fold("", (id, uid) => "$id$uid");
}

// Function to save the user's location securely
Future<void> saveLocation(LatLng location) async {
  await _secureStorage.write(key: 'latitude', value: location.latitude.toString());
  await _secureStorage.write(key: 'longitude', value: location.longitude.toString());
}



// Function to get and save the user's current location
Future<void> getUserLocation() async {
  Location location = Location();

  bool _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return;
    }
  }

  PermissionStatus _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }
  }

  LocationData _locationData = await location.getLocation();
  LatLng myLocation = LatLng(_locationData.latitude!, _locationData.longitude!);

  // Save the location securely
  await saveLocation(myLocation);
}
