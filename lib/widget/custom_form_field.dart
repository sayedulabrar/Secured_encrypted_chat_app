import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String hintText;
  final double height;
  final RegExp validationRegEx;
  final bool obscuretext;
  final void Function(String?) onsaved;

  const CustomFormField(
      {super.key,
      required this.hintText,
      required this.height,
      required this.validationRegEx,
      required this.onsaved,
      this.obscuretext = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        onSaved: onsaved,
        obscureText: obscuretext,
        validator: (value) {
          if (value != null && !validationRegEx.hasMatch(value)) {
            return "Enter a valid ${hintText.toLowerCase()}";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
