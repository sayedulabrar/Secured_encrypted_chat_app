import 'package:flutter/material.dart';

class TColor {
  // Private constructor to prevent instantiation
  TColor._();

  // Define the primary color palette
  static const Color primaryColor = Color(0xFF6200EE); // Example purple color
  static const Color primaryLightColor = Color(0xFFBB86FC);
  static const Color primaryDarkColor = Color(0xFF3700B3);

  // Define the secondary color palette
  static const Color secondaryColor = Color(0xFF03DAC6); // Example teal color
  static const Color secondaryLightColor = Color(0xFF66FFF9);
  static const Color secondaryDarkColor = Color(0xFF00A896);

  // Define the accent color palette
  static const Color accentColor = Color(0xFFFFC107); // Example amber color
  static const Color accentLightColor = Color(0xFFFFF350);
  static const Color accentDarkColor = Color(0xFFC79100);

  // Define background colors
  static const Color backgroundColor =
      Color(0xFFF5F5F5); // Example light grey background color
  static const Color backgroundContainerColor =
      Color(0xFFFFFFFF); // Example white container color

  // Define surface colors
  static const Color surfaceColor =
      Color(0xFFFFFFFF); // Example white surface color

  // Define error colors
  static const Color errorColor = Color(0xFFB00020); // Example red error color
  static const Color onErrorColor =
      Color(0xFFFFFFFF); // Text/icon color on error color

  // Define text colors
  static const Color textPrimaryColor =
      Color(0xFF212121); // Example dark text color
  static const Color textSecondaryColor =
      Color(0xFF757575); // Example light text color
  static const Color onPrimaryColor =
      Color(0xFFFFFFFF); // Text/icon color on primary color
  static const Color onSecondaryColor =
      Color(0xFF000000); // Text/icon color on secondary color
  static const Color onBackgroundColor =
      Color(0xFF000000); // Text/icon color on background color
  static const Color onSurfaceColor =
      Color(0xFF000000); // Text/icon color on surface color

  // Define button colors
  static const Color buttonColor = Color(0xFF6200EE); // Example button color
  static const Color buttonTextColor =
      Color(0xFFFFFFFF); // Example button text color

  // Define border colors
  static const Color borderColor = Color(0xFFBDBDBD); // Example border color

  // Define neutral shades
  static const Color neutralLight =
      Color(0xFFF5F5F5); // Example light neutral color
  static const Color neutralMedium =
      Color(0xFF9E9E9E); // Example medium neutral color
  static const Color neutralDark =
      Color(0xFF616161); // Example dark neutral color

  // Define gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, surfaceColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient radialGradient = RadialGradient(
    colors: [primaryColor, secondaryColor],
    center: Alignment.center,
    radius: 0.5,
  );

// Add any additional colors and gradients you need for your app
}
