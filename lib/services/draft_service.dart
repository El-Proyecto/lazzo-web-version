import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/event_draft.dart';

/// Serviço para gerenciar rascunhos de eventos
/// Salva e carrega rascunhos usando SharedPreferences
class DraftService {
  static const String _draftKey = 'event_draft';

  static final DraftService _instance = DraftService._internal();
  factory DraftService() => _instance;
  DraftService._internal();

  /// Salva um rascunho
  Future<void> saveDraft(EventDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = jsonEncode(draft.toJson());
      await prefs.setString(_draftKey, draftJson);
    } catch (e) {
      // Log error but don't throw - drafts are not critical
          }
  }

  /// Carrega o rascunho salvo
  Future<EventDraft?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);

      if (draftJson == null) return null;

      final draftMap = jsonDecode(draftJson) as Map<String, dynamic>;
      return EventDraft.fromJson(draftMap);
    } catch (e) {
      // Log error but don't throw - drafts are not critical
            return null;
    }
  }

  /// Remove o rascunho salvo
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (e) {
      // Log error but don't throw - drafts are not critical
          }
  }

  /// Verifica se existe um rascunho salvo
  Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_draftKey);
    } catch (e) {
      return false;
    }
  }
}
