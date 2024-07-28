import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/profile.dart';

class AuthService {
  User? _user;
  Profile? _userprofile;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  User? get user {
    return _user;
  }
  Profile ? get userprofile{
    return _userprofile;
  }
  void set user(User? reuse){
    _user=reuse;
  }

  // AuthService() {
  //   _firebaseAuth.authStateChanges().listen(authStateChangesStreamListener);
  // }


  Future<void> fetchPersonalProfile() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection("users")
          .where('userid', isEqualTo: _user!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document
        DocumentSnapshot document = querySnapshot.docs.first;

        // Convert the document data to a Map
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;

        // Create a Profile object from the data
        _userprofile = Profile.fromJson(data);
      } else {
        print("No profile found for the current user.");
      }
    } catch (e) {
      print("Error fetching personal profile: $e");
      // Handle the error appropriately
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

        // Check user disabled status after successful login
        await checkUserDisabledStatus(email);

        // // Check if the email is verified
        // if (!_user!.emailVerified) {
        //   await sendVerificationEmail(_user!);
        //   return false; // Indicate that email verification is required
        // }

        await fetchPersonalProfile();
        return true; // Login successful
      }
      return false; // Login failed
    } catch (e) {
      print(e);
      throw Exception("Login failed: $e");
    }
  }

  // Future<void> sendVerificationEmail(User user) async {
  //   if (!user.emailVerified) {
  //     await user.sendEmailVerification();
  //   }
  // }




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
      throw Exception(
          "Your account has been disabled. Please contact support.");
    }
  }


  Future<bool> logout() async {
    try {
      await _firestore.collection('tokens').doc(user!.uid).update({
        'is_online': false,
        'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _userprofile=null;
      await _firebaseAuth.signOut();

      return true;
    } catch (e) {
      print(e);
      throw Exception("Logout failed: $e");
    }
  }

  // void authStateChangesStreamListener(User? user) {
  //   if (user != null) {
  //     _user = user;
  //   } else {
  //     _user = null;
  //   }
  // }
}
