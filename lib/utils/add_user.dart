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
import '../widget/navigation_drawer.dart';

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
  final _roleController = TextEditingController();
  late DatabaseService _databaseService;
  UserRole _selectedRole = UserRole.User;
  late AlertService _alertService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? selectedimage;
  late StorageService _storageService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
  }



  Widget buildProfileImage() {
    double radius = MediaQuery.of(context).size.width * 0.20;

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
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Users'),
      ),
        drawer: NavigationDrawerWidget(initialSelectedIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildProfileImage(),
            SizedBox(
              height: 60,
              width: 600,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'User Id',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  // Optional: Adds a background color
                ),
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: "required Capital,small letters and >=3 numbers",
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(0),
                ),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                // Optional: Adds a background color
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
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
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(0),
                ),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                // Optional: Adds a background color
              ),
              items: UserRole.values.map((role) {
                return DropdownMenuItem<UserRole>(
                  value: role,
                  child: Text(role == UserRole.Admin ? 'Admin' : 'User'),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: () {
                String email = _emailController.text+'@gmail.com';
                String password = _passwordController.text;
                if (PASSWORD_VALIDATION_REGEX.hasMatch(password)&& EMAIL_VALIDATION_REGEX.hasMatch(email)) {
                  _databaseService.signupWithRole(email, password, _selectedRole.name,selectedimage!);
                  _alertService.showToast(text: "Account created successfully");
                  // Clear text fields
                  _emailController.clear();
                  _passwordController.clear();
                  setState(() {
                    selectedimage=null;
                  });
                } else {
                  _alertService.showToast(
                      text: "Follow correct pattern for password and email");
                }
              },
              child: Text('Create User'),
            ),
            SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users found.'));
                  }

                  List<Profile> users = snapshot.data!.docs.map((doc) {
                    return Profile(
                      userid : doc['userid'],
                      email: doc['email'],
                      password: doc['password'],
                      role: doc['role'],
                      disabled: doc['disabled'] ?? false,
                    );
                  }).toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      Profile user = users[index];
                      return Card(
                        elevation: 4,
                        margin:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          trailing: user.role == "User"
                              ? IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirm User role'),
                                    content: Text(
                                        "Are you sure you want to change this user's role?"),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Confirm'),
                                        onPressed: () {
                                          _databaseService.toggleUserStatus(user.email);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          )
                              : null,
                          title: Text(user.email.split('@')[0]),
                          subtitle: Text(user.role),
                          leading: CircleAvatar(
                            backgroundColor:
                            user.disabled ? Colors.red : Colors.green,
                            child: Icon(
                              user.disabled ? Icons.block : Icons.check,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
