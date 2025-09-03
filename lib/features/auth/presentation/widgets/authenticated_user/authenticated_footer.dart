import 'package:flutter/material.dart';

class GetStartedCta extends StatelessWidget {
  const GetStartedCta({
    super.key,
    this.onPressed,
    this.title = 'Get Started',
    this.subtitle = 'Ready to create your first event?',
  });

  final VoidCallback? onPressed;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botão verde
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              decoration: ShapeDecoration(
                color: const Color(0xFF32D445),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 267,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF2F2F2), // Text-1
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
                      letterSpacing: 0.10,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Texto auxiliar
          SizedBox(
            width: 360,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFA5A5A5), // Text-2
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
