import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/otp_verification/otp_title.dart';
import '../../widgets/otp_verification/otp_subtitle.dart';
import '../../widgets/otp_verification/otp_boxes.dart';
import '../../widgets/otp_verification/verify_footer.dart';
import '../../widgets/otp_verification/resend_otp_button.dart';
import '../../../../../shared/components/sections/lazzo_header.dart';
import '../../../../../shared/themes/colors.dart';

// Auth providers (DI)
import '../../providers/auth_provider.dart';
// Rotas
import '../../../../../routes/app_router.dart';

class LoginOtpVerificationPage extends ConsumerStatefulWidget {
  const LoginOtpVerificationPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<LoginOtpVerificationPage> createState() =>
      _LoginOtpVerificationPageState();
}

class _LoginOtpVerificationPageState
    extends ConsumerState<LoginOtpVerificationPage> {
  String _code = '';
  String? _bannerMessage;
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _bannerMessage = null);
    try {
      // Pede novo OTP via repositório (login por email)
      await ref.read(authRepositoryProvider).login(email: widget.email);
      setState(() => _bannerMessage = 'New code sent to your email.');
    } catch (e) {
      setState(() => _bannerMessage = 'Falha ao reenviar código: $e');
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _bannerMessage = 'Input the six digit code sent.');
      return;
    }

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    try {
      // 1) Verifica OTP via repo (camada de dados)
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: widget.email, otp: _code);

      // 2) Atualiza estado de sessão no provider (camada de domínio)
      await ref.read(authProvider.notifier).getCurrentUser();

      if (!mounted) return;

      // 3) Navega para o layout principal usando o ROOT navigator
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRouter.mainLayout,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _bannerMessage = 'Erro ao verificar código: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LazzoHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OtpTitle(),
                    const SizedBox(height: 16),
                    OtpSubtitle(email: widget.email),
                    const SizedBox(height: 32),
                    OtpCodeBoxes(
                      onCompleted: (code) => setState(() => _code = code),
                    ),
                    if (_bannerMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: BrandColors.bg3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _bannerMessage!,
                          style: const TextStyle(
                            color: BrandColors.cantVote,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VerifyFooter(
                          onSend: _busy ? null : _verify,
                          isEnabled: _code.length == 6 && !_busy,
                        ),
                        const SizedBox(height: 16),
                        ResendOtpButton(onResend: _busy ? null : _resend, isBusy: _busy),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
