import 'package:flutter/material.dart';
//import '../../../../../shared/constants/spacing.dart';

class OtpTitle extends StatelessWidget {
  const OtpTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 370,
      child: Text(
        'Check your email',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 28,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          height: 1.29,
        ),
      ),
    );
  }
}
