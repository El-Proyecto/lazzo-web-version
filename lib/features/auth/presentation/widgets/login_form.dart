import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginForm extends ConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final identifierCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: identifierCtrl,
          decoration: const InputDecoration(labelText: 'Phone Number eg +1234567890'),
        ),
        TextField(
          controller: passwordCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            ref.read(authProvider.notifier).login(
                  identifierCtrl.text.trim(),
                );
          },
          child: const Text("Login"),
        ),
        if (authState.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              authState.error.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (authState.value != null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Login efetuado com sucesso!',
              style: TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }
}