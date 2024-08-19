import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';
import '../service/alert_service.dart';
import '../service/navigation_service.dart';
import '../constant/consts.dart';
import '../service/auth_service.dart';
import '../widget/custom_form_field.dart';
import '../widget/button_widget.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GetIt _getIt = GetIt.instance;
  final _loginFormKey = GlobalKey<FormState>();
  String? userid, password;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  bool _isLoading = false;

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
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/army2.jpg'), // Use AssetImage with correct path
          fit: BoxFit.cover, // Fit the image to cover the entire background
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3), // Optional: Add a color filter for better text contrast
            BlendMode.darken,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            children: [

              _loginForm(),
            ],
          ),
        ),
      ),
    );
  }





  Widget _loginForm() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.05),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0), // Adjust padding as needed
                    decoration: BoxDecoration(
                      color: Colors.black, // Background color
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(50.0), // Circular shape
                      border: Border.all(
                        color: Colors.white, // White border color
                        width: 4.0, // Border width
                      ),
                    ),
                    child: Text(
                      "CrypComm",
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 60.0),
              Form(
                key: _loginFormKey,
                child: Column(
                  children: [
                    CustomFormField(
                      height: MediaQuery.of(context).size.height * 0.1,
                      hintText: "User Id",
                      validationRegEx: EMAIL_VALIDATION_REGEX,
                      onsaved: (value) {
                        setState(() {
                          userid = value;
                        });
                      },
                    ),
                    SizedBox(height: 20.0),
                    CustomFormField(
                      height: MediaQuery.of(context).size.height * 0.1,
                      hintText: "Password",
                      validationRegEx: PASSWORD_VALIDATION_REGEX,
                      obscureText: true,
                      onsaved: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                    ),
                    SizedBox(height: 30.0),
                    _loginButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      child: RoundButton(
        title: 'Login',
        onTap: () async {
          setState(() {
            _isLoading = true;
          });

          try {
            if (_loginFormKey.currentState?.validate() ?? false) {
              _loginFormKey.currentState?.save();
              String email = userid! + '@gmail.com';
              bool result = await _authService.login(email, password!);

              if (result) {
                _navigationService.pushReplacementNamed('/home');
              } else {
                _alertService.showToast(
                  text: "Failed to login. Please check your userid and verify it before trying again.",
                  icon: Icons.perm_identity,
                );
              }
            }
          } catch (e) {
            _alertService.showToast(
              text: "An error occurred during login. Please try again later.",
              icon: Icons.error,
            );
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
        loading: _isLoading,
      ),
    );
  }
}
