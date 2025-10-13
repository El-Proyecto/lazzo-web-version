import 'package:flutter/material.dart';
import '../../../../shared/components/inputs/input_box.dart';

class NameInput extends StatelessWidget {
  final TextEditingController controller;

  const NameInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InputBox(
      label: 'Name',
      hintText: 'e.g. Manuel Semedo',
      controller: controller,
    );
  }
}
