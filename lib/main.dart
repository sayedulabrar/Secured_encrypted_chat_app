import 'package:cryp_comm/service/alert_service.dart';
import 'package:cryp_comm/service/auth_service.dart';
import 'package:cryp_comm/service/database_service.dart';
import 'package:cryp_comm/service/media_service.dart';
import 'package:cryp_comm/service/navigation_service.dart';
import 'package:cryp_comm/service/notification_service.dart';
import 'package:cryp_comm/service/storage_service.dart';
import 'package:cryp_comm/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';


void main() async {
  await setup();
  runApp(
    MyApp(),
  );
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


Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await registerServices();
}

Future<void> registerServices() async {
  final getIt = GetIt.instance;
  getIt.registerSingleton<AuthService>(
    AuthService(),
  );
  getIt.registerSingleton<NavigationService>(
    NavigationService(),
  );
  getIt.registerSingleton<AlertService>(
    AlertService(),
  );
  getIt.registerSingleton<MediaService>(
    MediaService(),
  );

  getIt.registerSingleton<StorageService>(
    StorageService(),
  );

  getIt.registerSingleton<DatabaseService>(
    DatabaseService(),
  );

  getIt.registerSingleton<PushNotificationService>(
    PushNotificationService(),
  );
}

String generateChatID({required String uid1, required String uid2}) {
  List uids = [uid1, uid2];
  uids.sort();
  String chatID = uids.fold("", (id, uid) => "$id$uid");
  return chatID;
}
