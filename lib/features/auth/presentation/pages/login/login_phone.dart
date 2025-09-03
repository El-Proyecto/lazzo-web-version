import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/enter_phonepage/enter_phone_header.dart';
import '../../widgets/enter_phonepage/enter_phone_footer.dart';
import '../../widgets/enter_phonepage/phone_banner.dart';
import '../../../../../shared/constants/countries.dart';
import '../../../data/models/country.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  late Country selectedCountry;
  String? bannerMessage;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0];
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (_sending) return;
    final local = phoneController.text.trim();
    final code = selectedCountry.code; // ex: +351

    if (local.isEmpty || local.length < 6) {
      setState(() => bannerMessage = 'Please use a valid phone number.');
      return;
    }

    // E.164 simples: +3519...
    final fullPhone = '$code$local'.replaceAll(' ', '');

    setState(() {
      _sending = true;
      bannerMessage = null;
    });

    try {
      // ✅ Tenta enviar OTP **apenas** se o utilizador já existir
      // (em algumas versões do SDK este parâmetro pode não existir;
      // ver nota mais abaixo).
      await Supabase.instance.client.auth.signInWithOtp(
        phone: fullPhone,
        shouldCreateUser: false, // <- chave para comportamento "login apenas"
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/otp-login', arguments: {'phoneNumber': fullPhone});
    } on AuthException catch (e) {
      // Provável: "User not found" / "For security reasons, we do not allow signups on this endpoint"
      setState(() => bannerMessage = e.message.isNotEmpty
          ? e.message
          : 'Account Not Found for this number.');
    } catch (e) {
      setState(() => bannerMessage = 'Its not possible to provide the code: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EnterPhoneFooter(
                onSend: _sending ? null : _onSend,
              ),
              const SizedBox(height: 8),
            ],
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
              // 👇 Título de login
              const SizedBox(height: 8),
              const Text(
                'Welcome back!',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFFF2F2F2),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 24),

              EnterPhoneHeader(
                controller: phoneController,
                selectedCountry: selectedCountry,
                onCountryChanged: (country) {
                  setState(() => selectedCountry = country);
                },
                countries: countries,
              ),

              if (bannerMessage != null) ...[
                const SizedBox(height: 12),
                PhoneBanner(message: bannerMessage!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
