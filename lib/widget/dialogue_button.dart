import 'package:flutter/material.dart';

Widget buildDialogButton({
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