import 'package:flutter/material.dart';
import 'utils/app.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _imageSizeAnimation;
  late Animation<double> _textSizeAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4), // Extended duration to accommodate fade out
    );

    _jumpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.bounceOut), // Bounce out curve for initial jump
      ),
    );

    _imageSizeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut), // Initial size increase during jump
      ),
    );

    _textSizeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut), // Delayed size increase for text
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.75, 1.0, curve: Curves.easeOut), // Fade out at the end of animation
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextPage();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => App()), // Replace with your actual next page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 250,
            ),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeOutAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0.0, -100 * _jumpAnimation.value), // Adjust initial jump height
                    child: Transform.scale(
                      scale: _imageSizeAnimation.value,
                      child: Image.asset(
                        'assets/cryp.png',
                        width: MediaQuery.of(context).size.width * 0.3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20), // Add some space between the image and the text
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeOutAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0.0, -100 * _jumpAnimation.value), // Adjust initial jump height
                    child: Transform.scale(
                      scale: _textSizeAnimation.value,
                      child: Text(
                        'Cryp_Comm',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
