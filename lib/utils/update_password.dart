import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../service/auth_service.dart';
import '../service/alert_service.dart';
import '../service/navigation_service.dart';
import '../widget/button_widget.dart';
import '../widget/custom_form_field.dart';
import '../constant/consts.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final GetIt _getIt = GetIt.instance;
  final _changePasswordFormKey = GlobalKey<FormState>();
  String? oldPassword, newPassword;
  late AuthService _authService;
  late AlertService _alertService;
  bool _isLoading = false;
  late NavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),

      ),
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double screenWidth = mediaQuery.size.width;
    return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: Column(
            children: [

              _changePasswordForm(),
            ],
          ),
        ));
  }



  Widget _changePasswordForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.50,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Form(
        key: _changePasswordFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomFormField(
                height: MediaQuery.of(context).size.height * 0.1,
                hintText: "Old Password",
                validationRegEx: PASSWORD_VALIDATION_REGEX,
                obscureText: true,
                onsaved: (value) {
                  setState(() {
                    oldPassword = value;
                  });
                },
              ),
              CustomFormField(
                height: MediaQuery.of(context).size.height * 0.1,
                hintText: "New Password",
                validationRegEx: PASSWORD_VALIDATION_REGEX,
                obscureText: true,
                onsaved: (value) {
                  setState(() {
                    newPassword = value;
                  });
                },
              ),
              _changePasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _changePasswordButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: RoundButton(
        title: 'Change Password',
        onTap: () async {
          setState(() {
            _isLoading = true; // Set loading to true
          });

          try {
            if (_changePasswordFormKey.currentState?.validate() ?? false) {
              _changePasswordFormKey.currentState?.save();
              bool result = await _authService.changePassword(oldPassword!, newPassword!);

              if (result) {
                _alertService.showToast(
                  text: "Password changed successfully",
                  icon: Icons.check_circle_outline_rounded,
                );
                _navigationService.pushReplacementNamed('/profile'); // Go back to the previous screen
              } else {
                _alertService.showToast(
                  text: "Failed to change password. Please try again.",
                  icon: Icons.error,
                );
              }
            }
          } catch (e) {
            print("Error during password change: $e");
            _alertService.showToast(
              text: "An error occurred while changing password. Please try again later.",
              icon: Icons.error,
            );
          } finally {
            setState(() {
              _isLoading = false; // Set loading to false
            });
          }
        },
        loading: _isLoading, // Pass the loading state
      ),
    );
  }
}
