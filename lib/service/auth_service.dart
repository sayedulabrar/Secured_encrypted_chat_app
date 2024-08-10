import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/profile.dart';



class AuthService {
  User? _user;
  Profile? _userprofile;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  User? get user {
    return _user;
  }

  Profile? get userprofile {
    return _userprofile;
  }

  set user(User? reuse) {
    _user = reuse;
  }

  AuthService() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    print("AuthService has been initialized");
    String? userEmail = await _secureStorage.read(key: 'userEmail');
    String? userPassword = await _secureStorage.read(key: 'userPassword');

    if (userEmail != null && userPassword != null) {
      try {
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );

        if (credential.user != null) {
          _user = credential.user;
          await fetchPersonalProfile();
        }
      } catch (e) {
        print("Error initializing user: $e");
      }
    }
  }

  Future<void> fetchPersonalProfile() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection("users")
          .where('userid', isEqualTo: _user!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot document = querySnapshot.docs.first;
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        _userprofile = Profile.fromJson(data);
      } else {
        print("No profile found for the current user.");
      }
    } catch (e) {
      print("Error fetching personal profile: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _user = credential.user;
        await checkUserDisabledStatus(email);

        await fetchPersonalProfile();
        await _secureStorage.write(key: 'userEmail', value: email);
        await _secureStorage.write(key: 'userPassword', value: password);
        if (_userprofile?.role == "Admin") {
          await _secureStorage.write(key: 'adminPassword', value: password);
        }

        return true;
      }
      return false;
    } catch (e) {
      print(e);
      throw Exception("Login failed: $e");
    }
  }

  Future<void> checkUserDisabledStatus(String email) async {
    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception("User not found.");
    }

    DocumentSnapshot userDoc = userQuery.docs.first;

    if (userDoc.exists && userDoc['disabled'] == true) {
      throw Exception("Your account has been disabled. Please contact support.");
    }
  }

  Future<bool> logout() async {
    try {
      await _firestore.collection('tokens').doc(user!.uid).update({
        'is_online': false,
        'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      await _firebaseAuth.signOut();
      _user = null;
      _userprofile = null;

      await _secureStorage.delete(key: 'userEmail');
      await _secureStorage.delete(key: 'userPassword');

      return true;
    } catch (e) {
      print(e);
      throw Exception("Logout failed: $e");
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      // Reauthenticate user
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception("No user is currently signed in.");
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: oldPassword,
      );

      // Reauthenticate
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(newPassword);

      // Optionally, you can also update the password in secure storage
      await _secureStorage.write(key: 'userPassword', value: newPassword);

      await _firestore.collection("users").doc(user?.uid).update({'password':newPassword});

      return true; // Password change successful
    } catch (e) {
      print("Error changing password: $e");
      return false; // Password change failed
    }
  }
}
