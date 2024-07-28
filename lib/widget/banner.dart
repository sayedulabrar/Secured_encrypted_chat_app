import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Tophalf extends StatelessWidget {
  final String headline;
  const Tophalf({Key? key, required this.headline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double screenWidth = mediaQuery.size.width;

    return Container(
      height: screenHeight * 0.3,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(90)),
        image: DecorationImage(
          image: AssetImage('assets/lottie_animations/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              headline,
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
            SizedBox(height: 10),
            Lottie.asset(
              'assets/lottie_animations/Animation1718333394342.json',
              height: screenHeight * 0.2,
              width: screenWidth * 0.6,
            ),
          ],
        ),
      ),
    );
  }
}
