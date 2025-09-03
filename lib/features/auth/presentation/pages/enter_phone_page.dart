import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/enter_phonepage/enter_phone_header.dart';
import '../widgets/enter_phonepage/enter_phone_footer.dart';
import '../widgets/enter_phonepage/phone_banner.dart';
import '../../../../shared/constants/countries.dart';
import '../../data/models/country.dart';

class EnterPhonePage extends StatefulWidget {
  const EnterPhonePage({super.key});

  @override
  State<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends State<EnterPhonePage> {
  final TextEditingController phoneController = TextEditingController();
  late Country selectedCountry;
  String? bannerMessage;

  @override
  void initState() {
    super.initState();
    selectedCountry = countries[0]; // ✅ usa a lista do ficheiro
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final phone = phoneController.text.trim();
    final code = selectedCountry.code; // ex: +351
    if (phone.isEmpty || phone.length < 6) {
      setState(() => bannerMessage = 'Por favor insira um número de telemóvel válido.');
      return;
    }

    // Certifica-te que está em E.164: +3519...
    final fullPhone = '$code$phone'.replaceAll(' ', '');

    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: fullPhone);

      setState(() => bannerMessage = null);
      if (!mounted) return;
      Navigator.pushNamed(context, '/otp', arguments: {'phoneNumber': fullPhone});
    } catch (e) {
      setState(() => bannerMessage = 'Não foi possível enviar o código: $e');
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
              EnterPhoneFooter(onSend: _onSend),
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
              const SizedBox(height: 32),
              EnterPhoneHeader(
                controller: phoneController,
                selectedCountry: selectedCountry,
                onCountryChanged: (country) {
                  setState(() => selectedCountry = country);
                },
                countries: countries, // ✅ envia lista para o widget
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
