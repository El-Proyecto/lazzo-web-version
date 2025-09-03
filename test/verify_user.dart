import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://pgpryaelqhspwhplttzb.supabase.co'; // substitui
  final supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncHJ5YWVscWhzcHdocGx0dHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNjY0MzUsImV4cCI6MjA2ODk0MjQzNX0.hPcn2J8zSKTC_rY8OeCmhLdJLhZEMT-yV1EZjYGFD2A'; // substitui

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final phoneNumber = '+351924467772'; // ex: +351912345678
  final token = '058359'; // o código OTP recebido por SMS

  try {
    final response = await client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneNumber,
      token: token,
    );

    final user = response.user;

    if (user == null) {
      print('❌ OTP inválido ou expirado.');
    } else {
      print('✅ Utilizador autenticado com sucesso!');
      print('User ID: ${user.id}');
    }
  } catch (e) {
    print('❌ Erro ao verificar OTP: $e');
  }
}
