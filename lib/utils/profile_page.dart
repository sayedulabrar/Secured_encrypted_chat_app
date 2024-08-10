import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../constant/consts.dart';
import '../models/profile.dart';
import '../service/alert_service.dart';
import '../service/database_service.dart';
import '../service/media_service.dart';
import '../service/navigation_service.dart';


class Profile_Page extends StatefulWidget {
  const Profile_Page({Key? key}) : super(key: key);

  @override
  State<Profile_Page> createState() => _Profile_PageState();
}

class _Profile_PageState extends State<Profile_Page> {
  final GetIt _getIt = GetIt.instance;
  late MediaService _mediaService;
  late DatabaseService _databaseService;
  late AlertService _alertService;
  File? selectedImage;
  bool _isLoading = false;
  bool showPassword = false;
  bool _isPasswordObscured = true; // Initially obscure the password
  bool _isEyeIconVisible = false; // Controls visibility of the eye icon
  late NavigationService _navigationService;
  bool _isImageSelected = false;
  Profile? myself;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _alertService = _getIt.get<AlertService>();
    _navigationService = _getIt.get<NavigationService>();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      myself = await _databaseService.fetchPersonalProfile();
    } catch (e) {
      _alertService.showToast(
        text: "Failed to load profile",
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleProfilePicUpdate() async {
    if (selectedImage == null) return;

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      await _databaseService.updateProfileImage(selectedImage!);
      _alertService.showToast(
        text: "Profile picture updated successfully",
        icon: Icons.check_circle_outline_rounded,
      );

      // Refresh profile data
      await _initializeChat();

    } catch (e) {
      _alertService.showToast(
        text: "Profile picture update failed",
        icon: Icons.error_outline,
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
        selectedImage = null; // Clear selected image
        _isImageSelected = false; // Hide update button
      });
    }
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
              backgroundImage: selectedImage != null
                  ? FileImage(selectedImage!)
                  : myself?.pfpURL != null
                  ? NetworkImage(myself!.pfpURL!) as ImageProvider
                  : NetworkImage(PLACEHOLDER_PFP) as ImageProvider, // Fallback image
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
                    selectedImage = file;
                    _isImageSelected = true; // Show update button
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),

      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: 340),
          child: Column(
            children: [
              SizedBox(height: 16),
              buildProfileImage(setState),
              if (_isImageSelected)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _handleProfilePicUpdate,
                    child: Text("Update Profile Picture",style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),),
                  ),
                ),
              if (myself != null)
                ...[
                  buildTextField("User Id", myself!.email.split('@')[0], false),
                  buildTextField("Password", myself!.password, true),
                  buildTextField("Role", myself!.role, false),
                  const SizedBox(height: 20), // Adds space before the button
                  TextButton.icon(
                    onPressed: () {
                     _navigationService.pushNamed('/changepassword');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding
                    ),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white), // Icon
                    label: const Text('Change Password'),
                  ),
                ],
              if (_isLoading)
                Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, String placeholder, bool isPasswordTextField) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: TextField(
        obscureText: isPasswordTextField ? _isPasswordObscured : false,
        decoration: InputDecoration(
          suffixIcon: isPasswordTextField
              ? _isEyeIconVisible
              ? IconButton(
            onPressed: () {
              setState(() {
                _isPasswordObscured = !_isPasswordObscured; // Toggle password visibility
              });
            },
            icon: Icon(
              _isPasswordObscured
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey,
            ),
          )
              : null
              : null,
          contentPadding: EdgeInsets.only(bottom: 3),
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: placeholder,
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onChanged: (value) {
          if (isPasswordTextField) {
            setState(() {
              _isEyeIconVisible = value.isNotEmpty; // Show eye icon if there's text
            });
          }
        },
      ),
    );
  }


}

