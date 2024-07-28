import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:get_it/get_it.dart';
import '../models/profile.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'package:cryp_comm/constant/consts.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late AuthService _authService;

  PushNotificationService() {
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  Future<void> initialize() async {
    // Request permission for iOS
    // Request permissions for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // // For apple platforms, ensure the APNS token is available
    // final apnsToken = await _firebaseMessaging.getAPNSToken();
    // if (apnsToken != null) {
    //   // APNS token is available
    // }

    // Get the token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Save the token to your database or send it to your server
    if (token != null) {
      await saveToken(token);
    } else {
      print("TOKEN NOT RECIVED.SADDDDDDDD");
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token Refreshed: $newToken");
      await saveToken(newToken);
    }).onError((err) {
      print("Error getting token: $err");
    });
  }

  Future<void> saveToken(String token) async {
    // Save the token in Firestore or another database

    await _firestore.collection('tokens').doc(_authService.user!.uid).set({
      'is_online': true,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'deviceToken': token,
    });
  }

  Future<String?> getToken(String userId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection('tokens').doc(userId).get();
    return snapshot['deviceToken'];
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = SERVICE_ACCOUNT_JSON;


    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

// get the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    client.close();

    return credentials.accessToken.data;
  }

  // Future<bool> status(String userId) async {
  //   DocumentSnapshot snapshot =
  //       await _firestore.collection('tokens').doc(userId).get();
  //   return snapshot['is_online'] ?? false;
  // }

  Future<void> sendNotificationToSelectedDriver(String deviceToken) async {
    Profile? myself = await _databaseService.fetchPersonalProfile();
    String myname = myself!.email;

    final String serverAccessTokenkey = await getAccessToken();

    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/cryp-b62c6/messages:send';

    final Map<String, dynamic> message = {
      "message": {
        "token": deviceToken,
        'notification': {
          "title": "New message from $myname",
          'body': "Please check your message"
        },
        'data': {'': ''}
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessTokenkey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
      print(response.body);
    }
  }
}
