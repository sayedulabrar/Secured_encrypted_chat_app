import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    final Uri? link = Uri.base; // Use the incoming link

    if (link != null) {
      try {
        await FirebaseAuth.instance
            .applyActionCode(link.queryParameters['oobCode']!);

        // Email verified successfully
        Navigator.pushReplacementNamed(context, '/home'); // Navigate to home
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Email Verification')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
