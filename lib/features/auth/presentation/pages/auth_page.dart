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

  // Flag para só navegar quando o fluxo OAuth realmente acontecer
  bool _pendingOAuth = false;

  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);

    // OUVE eventos de auth e navega APENAS se estivermos num fluxo OAuth
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      d,
    ) async {
      if (!_pendingOAuth) return;

      if ((d.event == AuthChangeEvent.signedIn ||
              d.event == AuthChangeEvent.userUpdated) &&
          d.session != null &&
          mounted) {
        _pendingOAuth = false; // reset
        final u = d.session!.user;
        final meta = (u.userMetadata ?? {});
        final nameRaw = meta['full_name'] ?? meta['name'];
        final name = (nameRaw is String && nameRaw.trim().isNotEmpty)
            ? nameRaw.trim()
            : null;

        await ref
            .read(authProvider.notifier)
            .ensureUsersRow(
              u.id,
              (u.email ?? '').trim().toLowerCase(),
              name: name,
            );

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
      _canSubmit =
          _nameController.text.isNotEmpty &&
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

      await authNotifier.register(email);
      if (!mounted) return;

      _nameController.clear();
      _emailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
        _pendingOAuth = true; // marca que estamos a iniciar OAuth
      });

      await ref.read(authProvider.notifier).signInWithGoogle();
      // NÃO navegues aqui; o listener acima trata disso quando voltar o deep link
    } catch (e) {
      _pendingOAuth = false; // falhou o fluxo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign In failed: $e'),
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
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
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
              const WelcomeSection(),
              const SizedBox(height: Gaps.xl),
              AuthFormWidgets(
                nameController: _nameController,
                emailController: _emailController,
                onCreateAccount: _canSubmit && !_isLoading
                    ? _handleSubmit
                    : null,
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
