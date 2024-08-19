import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../constant/consts.dart';
import '../service/alert_service.dart';
import '../service/database_service.dart';
import '../service/media_service.dart';
import '../widget/navigation_drawer.dart';
import '../widget/user_list_widget.dart';

class UserControlPage extends StatefulWidget {
  @override
  _UserControlPageState createState() => _UserControlPageState();
}

class _UserControlPageState extends State<UserControlPage> {
  final GetIt _getIt = GetIt.instance;
  late MediaService _mediaService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late DatabaseService _databaseService;

  late AlertService _alertService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? selectedimage;
  bool _isLoading = false;


  String? _selectedDiv;
  String? _selectedUnit;
  String? _selectedAppointment;
  String _selectedRole='User' ;



  final List<String> userroles=['User','Admin'];
  final Map<String, List<String>> divUnitMap = {
    'Div1': ['Unit1-1', 'Unit1-2'],
    'Div2': ['Unit2-1', 'Unit2-2'],
  };

  final Map<String, List<String>> unitAppointmentMap = {
    'Unit1-1': ['Appointment1-1-1', 'Appointment1-1-2'],
    'Unit1-2': ['Appointment1-2-1', 'Appointment1-2-2'],
    'Unit2-1': ['Appointment2-1-1', 'Appointment2-1-2'],
    'Unit2-2': ['Appointment2-2-1', 'Appointment2-2-2'],
  };

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
  }


  Future<void> _handleSignup(String selectedRole,String? selectedDiv,String? selectedUnit,
      String? selectedAppointment) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    String email = _emailController.text + '@gmail.com';
    String password = _passwordController.text;

    if (PASSWORD_VALIDATION_REGEX.hasMatch(password) &&
        EMAIL_VALIDATION_REGEX.hasMatch(email)) {
      await _databaseService.signupWithRole(email, password, selectedRole,selectedDiv,selectedUnit,selectedAppointment,selectedimage!);
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


  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  final List<String> _titles = ['Users Control', 'Add User'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green, // Set the AppBar background color
        iconTheme: IconThemeData(color: Colors.white), // Set the icon color to white
      ),
      drawer: NavigationDrawerWidget(initialSelectedIndex: 1),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildUserControlPage(),
                _buildAddUserPage(),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
            color: Colors.white,
            height: 50, // Height of the page control buttons
            child: Row(
              children: [
                _buildPageButton('Users Control', 0),
                _buildPageButton('Add User', 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(String title, int pageIndex) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.jumpToPage(pageIndex);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          color: _selectedIndex == pageIndex
              ? Colors.blueAccent
              : Colors.grey[300],
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: _selectedIndex == pageIndex
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserControlPage() {
    return UserListWidget(firestore: FirebaseFirestore.instance, databaseService: _databaseService);
  }

  Widget _buildAddUserPage() {
    // Use the dialog's content as the page content here
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildProfileImage(),
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
            SizedBox(height: 16),
            _buildDivDropdown(),
            SizedBox(height: 16),
            _buildUnitDropdown(),
            SizedBox(height: 16),
            _buildAppointmentDropdown(),
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
                  onPressed: () async {
                    print("I am pressed");



                    String selectedRole1 = _selectedRole;
                    String? selectedDiv1 = _selectedDiv;
                    String? selectedUnit1 = _selectedUnit;
                    String? selectedAppointment1 =_selectedAppointment;

                    // Check if any of the required fields are null
                    if (selectedDiv1 != null &&
                        selectedUnit1 != null &&
                        selectedAppointment1 != null) {
                      await _handleSignup(selectedRole1, selectedDiv1, selectedUnit1, selectedAppointment1);
                      _alertService.showToast(text: "User created Successfully",icon: Icons.check_circle_outline);
                    } else {
                      _alertService.showToast(text: "Select the Army feature to continue....");
                    }

                  },
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileImage() {
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

  Widget _buildRoleDropdown() {
    return Container(
      height: 50,
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        onChanged: (String? value) {
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
        items: userroles.map((role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(role),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivDropdown() {
    return Container(
      height: 50,
      child: DropdownButtonFormField<String>(
        value: _selectedDiv,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedDiv = value;
              _selectedUnit = null;  // Reset the Unit selection
              _selectedAppointment = null;  // Reset the Appointment selection
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Div',
          prefixIcon: Icon(Icons.work),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: divUnitMap.keys.map((div) {
          return DropdownMenuItem<String>(
            value: div,
            child: Text(div),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      height: 50,
      child: DropdownButtonFormField<String>(
        value: _selectedUnit,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedUnit = value;
              _selectedAppointment = null;  // Reset the Appointment selection
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Unit',
          prefixIcon: Icon(Icons.business),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _selectedDiv != null
            ? divUnitMap[_selectedDiv]!.map((unit) {
          return DropdownMenuItem<String>(
            value: unit,
            child: Text(unit),
          );
        }).toList()
            : [],
      ),
    );
  }

  Widget _buildAppointmentDropdown() {
    return Container(
      height: 50,
      child: DropdownButtonFormField<String>(
        value: _selectedAppointment,
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedAppointment = value;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Appointment',
          prefixIcon: Icon(Icons.schedule),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: _selectedUnit != null
            ? unitAppointmentMap[_selectedUnit]!.map((appointment) {
          return DropdownMenuItem<String>(
            value: appointment,
            child: Text(appointment),
          );
        }).toList()
            : [],
      ),
    );
  }


}
