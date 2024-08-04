import 'package:cryp_comm/widget/banner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import '../widget/button_widget.dart';
import '/service/alert_service.dart';
import '/service/navigation_service.dart';
import '../constant/consts.dart';
import '../service/auth_service.dart';
import '../widget/custom_form_field.dart';

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
    // TODO: implement initState
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
    final double screenHeight = mediaQuery.size.height;
    final double screenWidth = mediaQuery.size.width;
    return SafeArea(
        child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
      child: Column(
        children: [
          _headerText(),

          _loginForm(),
          // _createAnAccountLink()
        ],
      ),
    ));
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child:  Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/cryp.png',
            width: MediaQuery.of(context).size.width * 0.2,
          ),
          Text(
            "CrypComm",
            style: TextStyle(
              fontSize:25.0,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),

        ],
      ),
    );
  }

  Widget _loginForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      // EdgeInsets.symmetric                                                                                                                            Form(
      child: Form(
        key: _loginFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), // Adjust padding as needed
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              _loginButton(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: RoundButton(
        title: 'Login',
        onTap: () async {
          setState(() {
            _isLoading = true; // Set loading to true
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
            print("Error during login: $e");
            _alertService.showToast(
              text: "An error occurred during login. Please try again later.",
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
