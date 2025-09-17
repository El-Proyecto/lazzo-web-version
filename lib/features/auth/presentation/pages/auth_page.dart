import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/constants/spacing.dart';
import '../widgets/auth_form_widgets.dart';
import '../../../../shared/components/sections/lazzo_header.dart';
import '../widgets/welcome_section.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/themes/colors.dart';
import 'verifyotp.dart';
import './login/login_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _canSubmit = false;
  bool _isLoading = false;

  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // Navega quando a sessão chega via deep link (Google OAuth)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _canSubmit = _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _emailController.text.contains('@');
    });
  }

  void _handleSubmit() async {
    if (!_canSubmit) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      print('[AUTH_PAGE] Iniciando autenticação para email: $email');
      final authNotifier = ref.read(authProvider.notifier);

      // Envia o código OTP
      await authNotifier.register(email);

      if (!mounted) return;

      // Limpar os campos após o envio bem-sucedido
      _nameController.clear();
      _emailController.clear();

      // Mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navega para a página de verificação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.signInWithGoogle(); // não navegues aqui — listener trata disso
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign In failed: ${e.toString()}'),
          backgroundColor: BrandColors.cantVote,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAppleSignIn() {
    // TODO: Implement Apple sign in when needed
  }

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: LazzoHeader()),
              SizedBox(height: Gaps.xl),
              WelcomeSection(),
              SizedBox(height: Gaps.xl),
              AuthFormWidgets(
                nameController: _nameController,
                emailController: _emailController,
                onCreateAccount:
                    _canSubmit && !_isLoading ? _handleSubmit : null,
                isLoading: _isLoading,
                onGoogleSignIn: _handleGoogleSignIn,
                onAppleSignIn: _handleAppleSignIn,
                onLoginTap: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
