import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> createUserWithPhone() async {
  const projectUrl = 'https://pgpryaelqhspwhplttzb.supabase.co'; // substitui pelo teu
  const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBncHJ5YWVscWhzcHdocGx0dHpiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzM2NjQzNSwiZXhwIjoyMDY4OTQyNDM1fQ.-FNS3LqPOapG4_yfrJ0jFvnNvOs9ho6asuED7LOJbGs'; // substitui pela tua chave

  final url = Uri.parse('$projectUrl/auth/v1/admin/users');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'apikey': serviceRoleKey, // ✅ obrigatório!
      'Authorization': 'Bearer $serviceRoleKey', // também necessário
    },
    body: jsonEncode({
      'phone': '+351924467772',
      'password': 'teste123',
      'user_metadata': {
        'Display name': 'user1'
      }
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('✅ Utilizador criado com sucesso!');
    print(jsonDecode(response.body));
  } else {
    print('❌ Erro ao criar utilizador: ${response.statusCode}');
    print(response.body);
  }
}

void main() async {
  await createUserWithPhone();
}
