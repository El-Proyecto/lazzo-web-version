import 'package:flutter/material.dart';

class EnterPhoneFooter extends StatelessWidget {
  final VoidCallback? onSend;

  const EnterPhoneFooter({super.key, this.onSend});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 370,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
            decoration: ShapeDecoration(
              color: Color(0xFF32D445),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 267,
                child: GestureDetector(
                  onTap: onSend,
                  child: Text(
                    'Send Verification Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2F2F2),
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
          SizedBox(height: 16),
          SizedBox(
            width: 370,
            child: Text(
              'By continuing, you agree to our Terms of Service and Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA5A5A5),
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