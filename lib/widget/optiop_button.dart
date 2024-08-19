import 'package:flutter/material.dart';

Widget optionButton({
  required String text,
  required bool isSelected,
  required VoidCallback onPressed,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: Colors.black, backgroundColor: Colors.white, // Transparent background
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey, // Border color
        width: 2.0, // Border width
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    child: Text(text,style: TextStyle(
      color: Colors.black
    ),),
  );
}