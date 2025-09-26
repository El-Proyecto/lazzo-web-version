import 'package:flutter/material.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/themes/colors.dart';

class ResendOtpButton extends StatefulWidget {
  final VoidCallback? onResend;
  final bool isBusy;

  const ResendOtpButton({super.key, this.onResend, this.isBusy = false});

  @override
  State<ResendOtpButton> createState() => _ResendOtpButtonState();
}

class _ResendOtpButtonState extends State<ResendOtpButton> {
  static const _resendDelay = 30; // 30 seconds delay
  int _remainingSeconds = _resendDelay;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = _resendDelay;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 0;
          _canResend = true; // <- garante que troca para "Resend"
        }
      });
      return _remainingSeconds > 0;
    });
  }

  void _handleResend() {
    if (_canResend && !widget.isBusy) {
      widget.onResend?.call();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Pads.ctlH,
          vertical: Pads.ctlV,
        ),
        decoration: ShapeDecoration(
          color: _canResend
              ? BrandColors.text1
              : Colors.transparent, // Branco quando habilitado
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            side: BorderSide(
              color: BrandColors.text2.withOpacity(0.3), // Borda sutil
              width: 1,
            ),
          ),
        ),
        child: InkWell(
          onTap: _canResend && !widget.isBusy ? _handleResend : null,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Center(
            child: Text(
              _canResend ? 'Resend' : 'Resend in ${_remainingSeconds}s',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _canResend
                    ? BrandColors.bg1
                    : BrandColors.text2, // Texto escuro quando habilitado
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
    );
  }
}
