import 'package:flutter/material.dart';
import '../../../../shared/components/inputs/input_box.dart';

class EmailInput extends StatelessWidget {
  final TextEditingController controller;

  const EmailInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InputBox(
      label: 'Email',
      hintText: 'you@example.com',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
    );
  }
}
