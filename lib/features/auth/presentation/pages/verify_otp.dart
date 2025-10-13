import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/otp_verification/otp_title.dart';
import '../widgets/otp_verification/otp_subtitle.dart';
import '../widgets/otp_verification/otp_boxes.dart';
import '../widgets/otp_verification/verify_footer.dart';
import '../widgets/otp_verification/resend_otp_button.dart';
import '../../../../shared/components/sections/lazzo_header.dart';
import '../../../../shared/themes/colors.dart';

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
  late final AuthRemoteDatasource _authDatasource;

  @override
  void initState() {
    super.initState();
    _authDatasource = AuthRemoteDatasource(Supabase.instance.client);
  }

  Future<void> _resend() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    try {
      await _authDatasource.register(widget.email);
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
      print('📱 Iniciando verificação OTP com email: ${widget.email}, name: ${widget.name}'); // Debug
      
      // Pass name directly to verifyOtp method
      await _authDatasource.verifyOtp(
        email: widget.email, 
        token: _code,
        name: widget.name?.trim(),
      );

      print('📱 OTP verificado com sucesso, navegando para /main'); // Debug

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } on AuthException catch (e) {
      print('📱 Erro AuthException: ${e.message}'); // Debug
      setState(() => _bannerMessage = e.message);
    } catch (e) {
      print('📱 Erro geral: $e'); // Debug
      setState(() => _bannerMessage = 'Erro ao verificar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                          isEnabled:
                              _code.length == 6 && !_busy, // alinhado com Login
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
