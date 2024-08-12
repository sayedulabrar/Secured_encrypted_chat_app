import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryp_comm/service/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import '../models/profile.dart';
import '../service/database_service.dart';
import '../service/auth_service.dart';

class NavigationDrawerWidget extends StatefulWidget {
  final int initialSelectedIndex;

  const NavigationDrawerWidget({Key? key, required this.initialSelectedIndex}) : super(key: key);

  @override
  State<NavigationDrawerWidget> createState() => _NavigationDrawerWidgetState();
}

class _NavigationDrawerWidgetState extends State<NavigationDrawerWidget> {
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late AuthService _authService;
  late NavigationService _navigationService;

  String imageUrl='';
  String name='';
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _selectedIndex = widget.initialSelectedIndex;
    fetchProfile();
  }

  void fetchProfile() async {
    Profile? profile = await _databaseService.fetchPersonalProfile();
    if (profile != null) {
      setState(() {
        imageUrl = _authService.userprofile!.pfpURL!;
        name = _authService.user!.email!.split('@')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
        color: Colors.green,
        child: ListView(
          children: <Widget>[
            if (imageUrl.isNotEmpty && name.isNotEmpty)
              buildHeader(
                urlImage: imageUrl,
                name: name,
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  buildMenuItem(
                    text: 'Home',
                    icon: Icons.home,
                    index: 0,
                    onClicked: () => selectedItem(context, 0),
                  ),

                  _authService.userprofile?.role=="Admin"?const SizedBox(height: 24):const SizedBox(height: 0),
                  _authService.userprofile?.role=="Admin"?buildMenuItem(
                    text: 'Add User',
                    icon: Icons.person_add,
                    index: 1,
                    onClicked: () => selectedItem(context, 1),
                  ):SizedBox(height: 1,),
                  const SizedBox(height: 24),
                  buildMenuItem(
                    text: 'Unread Message',
                    icon: Icons.mark_chat_unread_outlined,
                    index: 2,
                    onClicked: () => selectedItem(context, 2),
                  ),
                  _authService.userprofile?.role=="Admin"?const SizedBox(height: 24):const SizedBox(height: 0),
                  _authService.userprofile?.role=="Admin"?buildMenuItem(
                    text: 'track malicious User',
                    icon: Icons.warning_outlined,
                    index: 3,
                    onClicked: () => selectedItem(context, 2),
                  ):Container(),
                  const SizedBox(height: 16),
                  buildMenuItem(
                    text: 'Logout',
                    icon: Icons.logout,
                    index: 4,
                    onClicked: () => selectedItem(context, 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader({
    required String urlImage,
    required String name,
  }) =>
      InkWell(
        splashColor: Colors.black26,
        onTap: () {
          setState(() {
            _selectedIndex = -1; // Reset the selected index when header is tapped
          });
          _navigationService.pushReplacementNamed('/profile');
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 30.0,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: urlImage,
                    placeholder: (context, url) => Image.asset(
                      'assets/loading.gif',
                      fit: BoxFit.cover,
                      width: 60.0,
                      height: 60.0,
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error, size: 30.0),
                    fit: BoxFit.cover,
                    width: 60.0,
                    height: 60.0,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildMenuItem({
    required String text,
    required IconData icon,
    required int index,
    VoidCallback? onClicked,
  }) {
    final isSelected = index == _selectedIndex;
    final color = isSelected ? Colors.white : Colors.white70;
    final backgroundColor = isSelected ? Colors.green[700] : null;

    return ListTile(
      leading: AnimatedRotation(
        turns: isSelected ? 1 : 0,
        duration: Duration(milliseconds: 300),
        child: Icon(icon, color: color),
      ),
      title: Text(text, style: TextStyle(color: color)),
      tileColor: backgroundColor,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (onClicked != null) {
          onClicked();
        }
      },
    );
  }

  void selectedItem(BuildContext context, int index) {
    switch (index) {
      case 0:
      // Navigate to home page
        _navigationService.pushReplacementNamed('/home');
        break;
      case 1:
      // Navigate to add user page
      _navigationService.pushReplacementNamed('/adduser');
        break;
      case 2:
        _navigationService.pushReplacementNamed('/unread');
        break;
      case 3:
        _navigationService.pushReplacementNamed('/map');
      case 4:
      // Logout
        _authService.logout();
        _navigationService.pushReplacementNamed('/login');
        break;



    }
  }
}