import 'package:flutter/material.dart';

class OtpSubtitle extends StatelessWidget {
  final String email;

  const OtpSubtitle({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 370,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'We sent a link to ',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.50,
                letterSpacing: 0.50,
              ),
            ),
            TextSpan(
              text: email,
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.50,
                letterSpacing: 0.50,
              ),
            ),
       ],
        ),
      ),
    );
  }
}