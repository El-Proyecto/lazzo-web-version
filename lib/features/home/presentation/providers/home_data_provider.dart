import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemorySummary { final String emoji; final String title; const MemorySummary(this.emoji, this.title); }
final lastMemoryProvider = Provider<MemorySummary?>((_) => const MemorySummary('🐟','Pescaria com o Zé'));
