import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/otp_verification/enter_codetitle.dart';
import '../widgets/otp_verification/otp_boxes.dart';
import '../widgets/otp_verification/verify_footer.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
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
    try {
      await _authDatasource.register(widget.email);
      setState(() => _bannerMessage = 'Enviámos novamente o código por email.');
    } catch (e) {
      setState(() => _bannerMessage = 'Falha ao reenviar código: $e');
    }
  }

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
      Navigator.pushNamedAndRemoveUntil(context, '/finish-setup', (_) => false);
    } on AuthException catch (e) {
      setState(() => _bannerMessage = e.message);
    } catch (e) {
      setState(() => _bannerMessage = 'Erro ao verificar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: EnterPhoneFooter(
            onSend: _busy ? null : _verify, // botão "Verify"
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              EnterCodeTitle(email: widget.email),
              const SizedBox(height: 24),
              OtpCodeBoxes(
                onCompleted: (code) => setState(() => _code = code),
                onResend: _resend,
              ),
              if (_bannerMessage != null) ...[
                const SizedBox(height: 12),
                _Banner(message: _bannerMessage!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: const Color(0xFF2B2B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFF2F2F2)),
      ),
    );
  }
}
