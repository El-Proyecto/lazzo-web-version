import 'package:flutter/material.dart';
import 'inline_text_editor.dart';

class InlinePhoneEditor extends StatelessWidget {
  const InlinePhoneEditor({
    super.key,
    this.initial,
    required this.onCancel,
    required this.onSave,
  });

  final String? initial;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  static final _phoneRx = RegExp(r'^\+?\d{6,15}$');

  @override
  Widget build(BuildContext context) {
    return InlineTextEditor(
      title: 'Phone Number',
      hint: 'Enter your phone in E.164 (e.g. +3519...)',
      initial: initial,
      keyboardType: TextInputType.phone,
      normalizer: (t) => t.trim().replaceAll(' ', ''),
      validator: (t) => _phoneRx.hasMatch(t.trim())
          ? null
          : 'Use +código e apenas dígitos (6–15).',
      onCancel: onCancel,
      onSave: onSave,
    );
  }
}
