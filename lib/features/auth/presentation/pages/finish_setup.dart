// lib/features/auth/presentation/pages/finish_setup.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Form principal
import '../widgets/finish_auth/body.dart';

// Editor inline para telefone (abaixo do tile)
import '../widgets/editor_tiles/inline_phone_editor.dart';

// Botão "Complete setup"
import '../widgets/finish_auth/complete_setup.dart';

// >>> NOVOS imports para persistência
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/repositories/users_repository.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

enum _Editing { none, phone, name, city, birthDate, instagram, tiktok, spotify }

class _CreateProfilePageState extends State<CreateProfilePage> {
  // ---- estado local (UI) ----
  String? _name;
  String? _phoneOverride;
  String? _city;
  DateTime? _birthDate;
  bool _notifyBirthday = false;

  // Redes
  String? _instagram;
  String? _tiktok;
  String? _spotify;

  _Editing _editing = _Editing.none;

  // ---- repo para persistência ----
  late final UsersRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = UsersRepository(UsersRemoteDatasource(Supabase.instance.client));
    // Garante row (faz insert com phone do auth se não existir)
    _repo.upsertPatch({});
  }


  // Helpers UI ---------------------------------------------------------------

  List<String> _missingRequiredFields() {
    final missing = <String>[];
    if ((_name?.trim().isNotEmpty ?? false) == false) missing.add('Name');
    if (_birthDate == null) missing.add('Birth Date');
    return missing;
  }

  void _onTapCompleteSetup() {
    final missing = _missingRequiredFields();
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      _finishSetup();
    } else {
      _showRequiredBanner(missing);
    }
  }

  void _showRequiredBanner(List<String> missing) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF2B2B2B),
        elevation: 0,
        leading: const Icon(Icons.error_outline, color: Color(0xFFFF3B30)),
        contentTextStyle: const TextStyle(color: Colors.white),
        content: Text('Please complete the required fields: ${missing.join(', ')}'),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              setState(() {
                if (missing.contains('Name')) {
                  _editing = _Editing.name;
                } else if (missing.contains('Birth Date')) {
                  _editing = _Editing.birthDate;
                }
              });
            },
            child: const Text('Fix now'),
          ),
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  String? _resolvedPhone(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final argPhone = (args is Map) ? args['phoneNumber'] as String? : null;
    final authPhone = Supabase.instance.client.auth.currentUser?.phone;
    return (argPhone?.trim().isNotEmpty ?? false)
        ? argPhone!.trim()
        : ((authPhone?.trim().isNotEmpty ?? false) ? authPhone!.trim() : null);
  }

  // Persistência -------------------------------------------------------------

  Future<void> _savePatch(Map<String, dynamic> patch, {bool showSuccess = false, String successMsg = 'Saved'}) async {
    try {
      await _repo.upsertPatch(patch);
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }


  void _toggleNotifyBirthday(bool v) {
    setState(() => _notifyBirthday = v);
    _savePatch({'Notify_birthday': v}); // nome da tua coluna com N maiúsculo
  }

  void _finishSetup() {
    // aqui já está tudo persistido campo-a-campo; basta navegar
    Navigator.pushNamedAndRemoveUntil(context, '/auth-done', (_) => false);
  }

  // Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final effectivePhone = _phoneOverride ?? _resolvedPhone(context);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Create Profile', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CreateProfileForm(
                // ----- dados -----
                phoneNumber: effectivePhone,
                name: _name,
                city: _city,
                birthDate: _birthDate,
                notifyBirthday: _notifyBirthday,

                // links (valores)
                instagram: _instagram,
                tiktok: _tiktok,
                spotify: _spotify,

                // ----- entrar em modo edição -----
                onAddPhoto: () {/* TODO: picker/upload avatar + storage */},
                onEditPhone:     () => setState(() => _editing = _Editing.phone),
                onEditName:      () => setState(() => _editing = _Editing.name),
                onEditCity:      () => setState(() => _editing = _Editing.city),
                onEditBirthDate: () => setState(() => _editing = _Editing.birthDate),
                onToggleNotifyBirthday: _toggleNotifyBirthday,

                // links: taps para entrar em edição
                onEditInstagram: () => setState(() => _editing = _Editing.instagram),
                onEditTikTok:    () => setState(() => _editing = _Editing.tiktok),
                onEditSpotify:   () => setState(() => _editing = _Editing.spotify),

                // ----- NAME -----
                isEditingName: _editing == _Editing.name,
                onCancelEditName: () => setState(() => _editing = _Editing.none),
                onSaveEditName: (v) {
                  setState(() { _name = v; _editing = _Editing.none; });
                  _savePatch({'name': v});
                },

                // ----- CITY -----
                isEditingCity: _editing == _Editing.city,
                onCancelEditCity: () => setState(() => _editing = _Editing.none),
                onSaveEditCity: (v) {
                  setState(() { _city = v; _editing = _Editing.none; });
                  _savePatch({'city': v});
                },

                // ----- BIRTH DATE -----
                isEditingBirthDate: _editing == _Editing.birthDate,
                onCancelEditBirthDate: () => setState(() => _editing = _Editing.none),
                onSaveEditBirthDate: (d) {
                  setState(() { _birthDate = d; _editing = _Editing.none; });
                  _savePatch({'birth_date': d.toIso8601String()});
                },

                // ----- LINKS -----
                isEditingInstagram: _editing == _Editing.instagram,
                onCancelEditInstagram: () => setState(() => _editing = _Editing.none),
                onSaveEditInstagram: (v) {
                  setState(() { _instagram = v; _editing = _Editing.none; });
                  _savePatch({'instagram_url': v});
                },

                isEditingTikTok: _editing == _Editing.tiktok,
                onCancelEditTikTok: () => setState(() => _editing = _Editing.none),
                onSaveEditTikTok: (v) {
                  setState(() { _tiktok = v; _editing = _Editing.none; });
                  _savePatch({'tiktok_url': v});
                },

                isEditingSpotify: _editing == _Editing.spotify,
                onCancelEditSpotify: () => setState(() => _editing = _Editing.none),
                onSaveEditSpotify: (v) {
                  setState(() { _spotify = v; _editing = _Editing.none; });
                  _savePatch({'spotify_url': v});
                },

                // ----- PHONE (editor inline) -----
                phoneEditor: _editing == _Editing.phone
                    ? InlinePhoneEditor(
                        initial: effectivePhone,
                        onCancel: () => setState(() => _editing = _Editing.none),
                        onSave: (v) {
                          setState(() { _phoneOverride = v; _editing = _Editing.none; });
                          _savePatch({'phone': v});
                        },
                      )
                    : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: CompleteSetupButton(onPressed: _onTapCompleteSetup),
        ),
      ),
    );
  }
}
