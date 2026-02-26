import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/constants/spacing.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/themes/colors.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/welcome_section.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/components/common/top_banner.dart';
import 'verify_otp.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
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
      final authNotifier = ref.read(authProvider.notifier);
      final name = _nameController.text.trim(); // Capture name BEFORE clearing

      await authNotifier.register(email);
      if (!mounted) return;

      _nameController.clear();
      _emailController.clear();

      if (mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Verification code sent to $email',
        );
      }

      // Debug

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            email: email,
            name: name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: const CommonAppBar(
        title: 'LAZZO',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeSection(),
              const SizedBox(height: Gaps.xl),
              AuthFormWidgets(
                nameController: _nameController,
                emailController: _emailController,
                onCreateAccount:
                    _canSubmit && !_isLoading ? _handleSubmit : null,
                isLoading: _isLoading,
                onLoginTap: _handleLogin,
              ),
              // Hidden reviewer access - tap logo 5 times to reveal
              const SizedBox(height: Gaps.xl),
              GestureDetector(
                onLongPress: () {
                  Navigator.pushNamed(context, '/reviewer-auth');
                },
                child: const Center(
                  child: Text(
                    'v1.0.1',
                    style: TextStyle(
                      color: BrandColors.text2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
