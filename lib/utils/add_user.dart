import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_comm/constant/consts.dart';
import 'package:cryp_comm/service/alert_service.dart';
import 'package:cryp_comm/service/database_service.dart';
import 'package:cryp_comm/models/profile.dart';

import '../service/media_service.dart';
import '../service/storage_service.dart';
import '../widget/button_widget.dart';
import '../widget/navigation_drawer.dart';
import '../widget/user_list_widget.dart';

enum UserRole {
  Admin,
  User,
}

class AddUsers extends StatefulWidget {
  const AddUsers({Key? key}) : super(key: key);

  @override
  State<AddUsers> createState() => _AddUsersState();
}

class _AddUsersState extends State<AddUsers> {
  final GetIt _getIt = GetIt.instance;
  late MediaService _mediaService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late DatabaseService _databaseService;
  UserRole _selectedRole = UserRole.User;
  late AlertService _alertService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? selectedimage;
  late StorageService _storageService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    String email = _emailController.text + '@gmail.com';
    String password = _passwordController.text;

    if (PASSWORD_VALIDATION_REGEX.hasMatch(password) &&
        EMAIL_VALIDATION_REGEX.hasMatch(email)) {
      await _databaseService.signupWithRole(email, password, _selectedRole.name, selectedimage!);
      _alertService.showToast(text: "Account created successfully");

      // Clear text fields
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        selectedimage = null;
      });
    } else {
      _alertService.showToast(text: "Follow correct pattern for password and email");
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  Widget buildProfileImage(StateSetter setState) {
    double radius = MediaQuery.of(context).size.width * 0.15;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CircleAvatar(
              radius: radius - 4, // Subtracting the border width
              backgroundImage: selectedimage != null
                  ? FileImage(selectedimage!)
                  : NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                File? file = await _mediaService.getImageFromGallery();

                if (file != null) {
                  setState(() {
                    selectedimage = file;
                  });
                }
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 4,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  color: Colors.green,
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return _isLoading?Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to only take up as much space as needed
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16), // Add space between the progress indicator and the text
            Text(
              'Please wait until the user is created',
              style: TextStyle(
                fontSize: 16, // Adjust the font size as needed
                color: Colors.black, // Adjust the color as needed
              ),
            ),
          ],
        ),
      ),
    )
        :Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Add Users'),
      ),
      drawer: NavigationDrawerWidget(initialSelectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog(context);
        },
        child: Icon(Icons.add),
      ),
      body: UserListWidget(firestore: _firestore, databaseService: _databaseService),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        
        return Dialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  constraints: BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      buildProfileImage(setState), // Pass setState to the dialog
                      SizedBox(height: 16),
                      _buildInputField(
                        controller: _emailController,
                        label: 'User Id',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 12),
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                      SizedBox(height: 12),
                      _buildRoleDropdown(),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDialogButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                            color: Colors.redAccent,
                          ),

                          _buildDialogButton(
                            label: 'Create User',
                            onPressed: () {
                              _handleSignup();
                              Navigator.of(context).pop();
                            },
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      height: 50,
      child: DropdownButtonFormField<UserRole>(
        value: _selectedRole,
        onChanged: (UserRole? value) {
          if (value != null) {
            setState(() {
              _selectedRole = value;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Role',
          prefixIcon: Icon(Icons.work),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: UserRole.values.map((role) {
          return DropdownMenuItem<UserRole>(
            value: role,
            child: Text(role == UserRole.Admin ? 'Admin' : 'User'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label,style: TextStyle(
        color: Colors.white
      ),),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}