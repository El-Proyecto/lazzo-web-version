import 'package:flutter/material.dart';

class CompleteSetupButton extends StatelessWidget {
  const CompleteSetupButton({
    super.key,
    this.onPressed,
    this.label = 'Complete Setup',
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: const Color(0xFF2BB956), // main-green
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 49, vertical: 12),
            child: Center(
              child: SizedBox(
                width: 267,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2F2F2)),
                        ),
                      )
                    : const Text(
                        'Complete Setup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
      ),
    );
  }
}
