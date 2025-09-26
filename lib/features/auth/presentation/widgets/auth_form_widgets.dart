import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../shared/components/buttons/continue_with.dart';
import '../../../../shared/components/buttons/green_button.dart';
import '../../../../shared/constants/spacing.dart';
import 'email_input.dart';
import 'name_input.dart';
import 'login_prompt.dart';
import 'or_divider.dart';

class AuthFormWidgets extends StatelessWidget {
  final TextEditingController? nameController;
  final TextEditingController emailController;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onAppleSignIn;
  final VoidCallback? onLoginTap;
  final bool isLoading;
  final bool isLogin;
  final String buttonText;
  final String bottomText;
  final String bottomActionText;

  const AuthFormWidgets({
    super.key,
    this.nameController,
    required this.emailController,
    this.onCreateAccount,
    this.onGoogleSignIn,
    this.onAppleSignIn,
    this.onLoginTap,
    this.isLoading = false,
    this.isLogin = false,
    this.buttonText = 'Create Account',
    this.bottomText = 'Already have an account?',
    this.bottomActionText = 'Log In',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isLogin) ...[
          // Social Login Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ContinueWith(
                    text: 'Google',
                    icon: FontAwesomeIcons.google,
                    onPressed: onGoogleSignIn,
                  ),
                ),
                const SizedBox(width: Gaps.md),
                Expanded(
                  child: ContinueWith(
                    text: 'Apple',
                    icon: FontAwesomeIcons.apple,
                    onPressed: onAppleSignIn,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),

          // OR Divider
          const OrDivider(),
          const SizedBox(height: Gaps.lg),
        ],

        // Email Form
        if (!isLogin && nameController != null)
          NameInput(controller: nameController!),
        if (!isLogin) const SizedBox(height: Gaps.md),
        EmailInput(controller: emailController),
        const SizedBox(height: Gaps.lg),
        GreenButton(
          text: buttonText,
          onPressed: isLogin ? onLoginTap : onCreateAccount,
          isLoading: isLoading,
        ),
        const SizedBox(height: Gaps.sm),
        LoginPrompt(onTap: onLoginTap),
      ],
    );
  }
}
