import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/constants/spacing.dart';
import '../widgets/auth_form_widgets.dart';
import '../../../../shared/components/sections/lazzo_header.dart';
import '../widgets/welcome_section.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/components/common/top_banner.dart';
import 'verify_otp.dart';
import './login/login_page.dart';

// Domínio: para tipar o listen
import '../../domain/entities/user.dart' as domain;

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

  // Flag para só navegar quando o fluxo OAuth realmente acontecer
  bool _pendingOAuth = false;

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

      print('🔄 Navegando para OTP com email: $email, name: $name'); // Debug

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

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
        _pendingOAuth = true; // a iniciar OAuth
      });

      await ref.read(authProvider.notifier).signInWithGoogle();
      // Navegação acontece no listener no build
    } catch (e) {
      _pendingOAuth = false;
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Google Sign In failed: $e',
        );
      }
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
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ref.listen deve estar no build
    ref.listen<AsyncValue<domain.User?>>(authProvider, (prev, next) async {
      next.whenOrNull(
        data: (u) async {
          if (!_pendingOAuth || u == null || !mounted) return;

          _pendingOAuth = false;

          // Garantir row no backend (se necessário)
          final navigator = Navigator.of(context);
          final n = ref.read(authProvider.notifier);
          await n.ensureUsersRow(
            u.id,
            u.email.trim().toLowerCase(),
            name: u.name,
          );

          if (mounted) {
            navigator.pushNamedAndRemoveUntil('/home', (_) => false);
          }
        },
      );
    });

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
              const WelcomeSection(),
              const SizedBox(height: Gaps.xl),
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
