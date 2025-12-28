import 'package:flutter/material.dart';
import '../../../../../shared/components/buttons/green_button.dart';

class VerifyFooter extends StatelessWidget {
  final VoidCallback? onSend;
  final bool isEnabled;

  const VerifyFooter({super.key, this.onSend, this.isEnabled = false});

  @override
  Widget build(BuildContext context) {
    return GreenButton(
      text: 'Verify',
      onPressed: isEnabled ? onSend : null,
      isLoading: false,
    );
  }
}
