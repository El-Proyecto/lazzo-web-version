import 'package:flutter/material.dart';
import '../../../../../shared/themes/colors.dart';

class VerifyFooter extends StatelessWidget {
  final VoidCallback? onSend;
  final bool isEnabled;

  const VerifyFooter({super.key, this.onSend, this.isEnabled = false});

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
              color: isEnabled ? BrandColors.planning : BrandColors.bg3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onSend : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: SizedBox(
                    width: 267,
                    child: Text(
                      'Verify',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BrandColors.text1,
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
          ),
        ],
      ),
    );
  }
}
