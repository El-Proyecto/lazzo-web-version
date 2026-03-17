import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/otp_verification/otp_title.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../widgets/otp_verification/otp_subtitle.dart';
import '../widgets/otp_verification/otp_boxes.dart';
import '../widgets/otp_verification/verify_footer.dart';
import '../widgets/otp_verification/resend_otp_button.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/utils/auth_analytics.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key, required this.email, this.name});

  final String email;
  final String? name;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  String _code = '';
  String? _bannerMessage;
  bool _busy = false;

  Future<void> _resend() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    try {
      // Usa o repositório de auth para reenviar OTP de signup
      await ref.read(authRepositoryProvider).register(email: widget.email);
      setState(
        () => _bannerMessage = 'A new code has been sent to your email.',
      );
    } catch (e) {
      setState(() => _bannerMessage = 'Failed to resend code: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(
        () => _bannerMessage = 'Put in the six digit code sent to your email.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    try {
      // 1) Verifica OTP via repositório (signup, shouldCreateUser: true)
      final user = await ref.read(authRepositoryProvider).verifyOtp(
            email: widget.email,
            otp: _code,
            name: widget.name?.trim(),
            isSignup: true,
          );

      // 2) Atualiza estado de sessão no provider (mantém consistente com login)
      await ref.read(authProvider.notifier).getCurrentUser();

      // 3) PostHog: identify novo utilizador + evento auth_completed
      final domainUser = user ?? ref.read(authProvider).valueOrNull;
      if (domainUser != null) {
        await trackAuthCompleted(
          user: domainUser,
          isNewUser: true,
        );
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } on AuthException catch (e) {
      // Debug
      setState(() => _bannerMessage = e.message);
    } catch (e) {
      // Debug
      setState(() => _bannerMessage = 'Erro ao verificar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'LAZZO',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OtpTitle(),
              const SizedBox(height: Gaps.md),
              OtpSubtitle(email: widget.email),
              const SizedBox(height: Gaps.xl),
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
              VerifyFooter(
                onSend: _busy ? null : _verify,
                isEnabled: _code.length == 6 && !_busy,
              ),
              const SizedBox(height: 16),
              ResendOtpButton(
                onResend: _resend,
                isBusy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
