import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/otp_verification/otp_title.dart';
import '../../widgets/otp_verification/otp_subtitle.dart';
import '../../widgets/otp_verification/otp_boxes.dart';
import '../../widgets/otp_verification/verify_footer.dart';
import '../../widgets/otp_verification/resend_otp_button.dart';
import '../../../../../shared/components/sections/lazzo_header.dart';
import '../../../../../shared/themes/colors.dart';

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
  late final AuthRemoteDatasource _authDatasource;

  @override
  void initState() {
    super.initState();
    _authDatasource = AuthRemoteDatasource(Supabase.instance.client);
  }

  Future<void> _resend() async {
    try {
      await _authDatasource.login(widget.email); // Usa login em vez de register
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
      await _authDatasource.verifyOtp(email: widget.email, token: _code);

      if (!mounted) return;

      // Navega direto para home após login bem sucedido
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
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
                          style: TextStyle(
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
                        ResendOtpButton(onResend: _resend, isBusy: _busy),
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
