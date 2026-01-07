import 'package:app/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/components/common/top_banner.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/components/sections/lazzo_header.dart';
import '../../../../../shared/constants/text_styles.dart';
import '../../../../../shared/themes/colors.dart';
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
      final authNotifier = ref.read(authProvider.notifier);

      // Envia o código OTP
      await authNotifier.login(email);
      
      if (!mounted) return;

      // Limpa o campo após o envio bem-sucedido
      _emailController.clear();

      // Navega para a página de verificação específica de login
      Navigator.pushNamed(context, '/otp-login', arguments: {'email': email});

      // Mostra mensagem de sucesso
      TopBanner.showSuccess(
        context,
        message: 'Verification code sent to $email',
      );
    } catch (e) {
      if (!mounted) return;

      TopBanner.showError(
        context,
        message: 'Error: ${e.toString()}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: LazzoHeader()),
              const SizedBox(height: Gaps.xl),
              Text(
                'Welcome Back!',
                style: AppText.headlineMedium.copyWith(
                  fontSize: 24,
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.md),
              LoginForm(
                emailController: _emailController,
                onCreateAccount:
                    _canSubmit && !_isLoading ? _handleSubmit : null,
                isLoading: _isLoading,
                onLoginTap: _handleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
