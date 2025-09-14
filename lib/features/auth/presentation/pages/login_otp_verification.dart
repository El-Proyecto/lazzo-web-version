import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/otp_verification/enter_codetitle.dart';
import '../widgets/otp_verification/otp_boxes.dart';
import '../widgets/otp_verification/verify_footer.dart';

class LoginOtpVerificationPage extends ConsumerStatefulWidget {
  const LoginOtpVerificationPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<LoginOtpVerificationPage> createState() => _LoginOtpVerificationPageState();
}

class _LoginOtpVerificationPageState extends ConsumerState<LoginOtpVerificationPage> {
  String _code = '';
  String? _bannerMessage;
  bool _busy = false;
  late final AuthRemoteDatasource _authDatasource;

  @override
  void initState() {
    super.initState();
    _authDatasource = AuthRemoteDatasource(Supabase.instance.client);
  }

  /*Future<void> _resend() async {
    try {
      await _authDatasource.login(widget.email);  // Usa login em vez de register
      setState(() => _bannerMessage = 'Enviámos novamente o código por email.');
    } catch (e) {
      setState(() => _bannerMessage = 'Falha ao reenviar código: $e');
    }
  }
  */
  
  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _bannerMessage = 'Introduz os 6 dígitos do código.');
      return;
    }
    
    setState(() {
      _busy = true;
      _bannerMessage = null;
    });

    try {
      await _authDatasource.verifyOtp(
        email: widget.email,
        token: _code,
      );

      if (!mounted) return;

      // Navega direto para home após login bem sucedido
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnterCodeTitle(email: widget.email),
              const SizedBox(height: 32),
              OtpCodeBoxes(
                onCompleted: (code) => setState(() => _code = code),
              ),
              if (_bannerMessage != null) ...[
                const SizedBox(height: 24),
                Text(
                  _bannerMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              VerifyFooter(
                onSend: _busy ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}