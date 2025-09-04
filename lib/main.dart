import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // se no futuro precisares iniciar Supabase, Firebase, etc. fazes aqui
  // await Supabase.initialize(...);

  runApp(
    const ProviderScope( // necessário se usas Riverpod; se não, podes tirar
      child: LazzoApp(),
    ),
  );
}
