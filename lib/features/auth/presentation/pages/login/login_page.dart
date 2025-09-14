import 'package:app/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/components/sections/lazzo_header.dart';
import '../../providers/auth_provider.dart';
//import '../verifyOTP.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  bool _canSubmit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _canSubmit = _emailController.text.isNotEmpty &&
                   _emailController.text.contains('@');
    });
  }

  void _handleSubmit() async {
    if (!_canSubmit) return;
    
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    
    try {
      print('[LOGIN_PAGE] Iniciando login para email: $email');
      final authNotifier = ref.read(authProvider.notifier);
      
      // Envia o código OTP
      await authNotifier.login(email);
      
      if (!mounted) return;
      
      // Limpa o campo após o envio bem-sucedido
      _emailController.clear();
      
      // Mostra mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navega para a página de verificação específica de login
      Navigator.pushNamed(
        context,
        '/otp-login',
        arguments: {'email': email},
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

  void _handleLogin() {
    Navigator.pushNamed(context, '/auth');
  }

  void _handleAppleLogIn() {
    Navigator.pushNamed(context, '/auth');
  }

  void _handleGoogleLogIn() {
    Navigator.pushNamed(context, '/auth');
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
              const Center(child: LazzoHeader()),
              SizedBox(height: Gaps.xl),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Gaps.xl),
              LoginForm(
                emailController: _emailController,
                onCreateAccount: _canSubmit && !_isLoading ? _handleSubmit : null,
                isLoading: _isLoading,
                onGoogleSignIn: _handleGoogleLogIn,
                onAppleSignIn: _handleAppleLogIn,
                onLoginTap: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
