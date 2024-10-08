import 'package:cryp_comm/utils/malicious_user_track.dart';
import 'package:cryp_comm/utils/profile_page.dart';
import 'package:cryp_comm/utils/unread_messages.dart';
import 'package:cryp_comm/utils/update_password.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../utils/email_verification.dart';
import '../utils/user_control.dart';
import '/utils/home.dart';
import '/utils/login.dart';

class NavigationService {
  late final GlobalKey<NavigatorState> _navigatorKey;

  final Map<String, Widget Function(BuildContext)> _routes = {
    '/login': (context) => Login(),
    '/home': (context) => Home(),
    '/adduser': (context) => UserControlPage(),
    '/verify-email':(context) => VerifyEmailPage(),
    '/unread':(context) => UnreadMessages(),
    '/profile': (context) => Profile_Page(),
    '/changepassword': (context) => ChangePassword(),
  };

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() => _navigatorKey.currentState?.pop();
}
