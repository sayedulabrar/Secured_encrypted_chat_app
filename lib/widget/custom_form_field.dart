import 'package:flutter/material.dart';

class CustomFormField extends StatefulWidget {
  final String hintText;
  final double height;
  final RegExp validationRegEx;
  final bool obscureText;
  final void Function(String?) onsaved;

  const CustomFormField({
    super.key,
    required this.hintText,
    required this.height,
    required this.validationRegEx,
    required this.onsaved,
    this.obscureText = false,
  });

  @override
  _CustomFormFieldState createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: TextFormField(
        onSaved: widget.onsaved,
        obscureText: _obscureText,
        validator: (value) {
          if (value != null && !widget.validationRegEx.hasMatch(value)) {
            return "Enter a valid ${widget.hintText.toLowerCase()}";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          suffixIcon: widget.hintText.toLowerCase() == 'password'
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleObscureText,
          )
              : null,
        ),
      ),
    );
  }
}
