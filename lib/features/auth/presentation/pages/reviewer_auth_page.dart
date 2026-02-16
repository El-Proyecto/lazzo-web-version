import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/components/common/top_banner.dart';
import '../../../../../shared/constants/spacing.dart';
import '../../../../../shared/constants/text_styles.dart';
import '../../../../../shared/themes/colors.dart';
import '../../../../../shared/components/nav/common_app_bar.dart';

/// Dedicated authentication page for Apple App Review team
/// Uses email + password authentication (not OTP)
class ReviewerAuthPage extends ConsumerStatefulWidget {
  const ReviewerAuthPage({super.key});

  @override
  ConsumerState<ReviewerAuthPage> createState() => _ReviewerAuthPageState();
}

class _ReviewerAuthPageState extends ConsumerState<ReviewerAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _canSubmit = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _canSubmit = _emailController.text.isNotEmpty &&
          _emailController.text.contains('@') &&
          _passwordController.text.length >= 6;
    });
  }

  Future<void> _handleLogin() async {
    if (!_canSubmit || _isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      // Use Supabase password authentication
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }

      // Log reviewer access (optional - for audit)
      try {
        await Supabase.instance.client.rpc('log_reviewer_access', params: {
          'p_email': email,
          'p_action': 'login',
        });
      } catch (_) {
        // Ignore logging errors - don't block login
      }

      if (!mounted) return;

      // Navigate to main layout (with nav bar)
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      TopBanner.showError(
        context,
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      TopBanner.showError(
        context,
        message: 'Login failed. Please check credentials.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'LAZZO',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Reviewer Access',
                style: AppText.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Gaps.sm),
              Text(
                'For Apple App Review team only',
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                ),
              ),
              const SizedBox(height: Gaps.xl),

              // Email Field
              Text(
                'Email',
                style: AppText.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Gaps.sm),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'reviewer@example.com',
                  hintStyle: const TextStyle(color: BrandColors.text2),
                  filled: true,
                  fillColor: BrandColors.bg2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gaps.md,
                    vertical: Gaps.md,
                  ),
                ),
              ),
              const SizedBox(height: Gaps.lg),

              // Password Field
              Text(
                'Password',
                style: AppText.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Gaps.sm),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autocorrect: false,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: BrandColors.text2),
                  filled: true,
                  fillColor: BrandColors.bg2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gaps.md,
                    vertical: Gaps.md,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: BrandColors.text2,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: Gaps.xl),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit && !_isLoading ? _handleLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canSubmit ? BrandColors.planning : BrandColors.bg3,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    disabledBackgroundColor: BrandColors.bg3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
