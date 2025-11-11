import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';

// Form principal
import '../widgets/finish_auth/body.dart';

// Botão "Complete setup"
import '../widgets/finish_auth/complete_setup.dart';

// Providers (injeção de dependências)
import '../../presentation/providers/users_repository_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/users_repository.dart';

class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

enum _Editing { none, name, city, birthDate }

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
  // ---- estado local (UI) ----
  String? _name;
  String? _emailOverride; // caso venhas a permitir edição inline
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
    _repo = ref.read(usersRepositoryProvider);
    // Garante row (faz insert se não existir)
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
        leading: const Icon(Icons.error_outline, color: BrandColors.cantVote),
        contentTextStyle: const TextStyle(color: Colors.white),
        content: Text(
          'Please complete the required fields: ${missing.join(', ')}',
        ),
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

  // Persistência -------------------------------------------------------------

  Future<void> _savePatch(
    Map<String, dynamic> patch, {
    bool showSuccess = false,
    String successMsg = 'Saved',
  }) async {
    try {
      await _repo.upsertPatch(patch);
      if (showSuccess && mounted) {
        TopBanner.showSuccess(
          context,
          message: successMsg,
        );
      }
    } catch (e) {
      if (mounted) {
        TopBanner.showError(
          context,
          message: 'Could not save: $e',
        );
      }
    }
  }

  void _toggleNotifyBirthday(bool v) {
    setState(() => _notifyBirthday = v);
    _savePatch({'Notify_birthday': v}); // nome da coluna conforme schema
  }

  void _finishSetup() {
    // Aqui já está tudo persistido campo-a-campo; basta navegar
    Navigator.pushNamedAndRemoveUntil(context, '/auth-done', (_) => false);
  }

  // Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // User autenticado (reativo)
    final user = ref.watch(authProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );

    // Email vindo por argumento da rota (se existir)
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final String? routeEmail =
        (routeArgs is Map && routeArgs['email'] is String)
            ? (routeArgs['email'] as String?)
            : null;

    // Prioridade: override local > argumento de rota > auth user
    final String? effectiveEmail =
        (_emailOverride ?? routeEmail ?? user?.email)?.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Create Profile',
          style: TextStyle(color: Colors.white),
        ),
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
                email: effectiveEmail, // <- passa o email resolvido
                name: _name,
                city: _city,
                birthDate: _birthDate,
                notifyBirthday: _notifyBirthday,

                // links (valores)
                instagram: _instagram,
                tiktok: _tiktok,
                spotify: _spotify,

                // ----- entrar em modo edição -----
                onAddPhoto: () {
                  /* TODO: picker/upload avatar + storage */
                },

                onEditName: () => setState(() => _editing = _Editing.name),
                onEditCity: () => setState(() => _editing = _Editing.city),
                onEditBirthDate: () =>
                    setState(() => _editing = _Editing.birthDate),
                onToggleNotifyBirthday: _toggleNotifyBirthday,

                // ----- NAME -----
                isEditingName: _editing == _Editing.name,
                onCancelEditName: () =>
                    setState(() => _editing = _Editing.none),
                onSaveEditName: (v) {
                  setState(() {
                    _name = v;
                    _editing = _Editing.none;
                  });
                  _savePatch({'name': v});
                },

                // ----- CITY -----
                isEditingCity: _editing == _Editing.city,
                onCancelEditCity: () =>
                    setState(() => _editing = _Editing.none),
                onSaveEditCity: (v) {
                  setState(() {
                    _city = v;
                    _editing = _Editing.none;
                  });
                  _savePatch({'city': v});
                },

                // ----- BIRTH DATE -----
                isEditingBirthDate: _editing == _Editing.birthDate,
                onCancelEditBirthDate: () =>
                    setState(() => _editing = _Editing.none),
                onSaveEditBirthDate: (d) {
                  setState(() {
                    _birthDate = d;
                    _editing = _Editing.none;
                  });
                  _savePatch({'birth_date': d.toIso8601String()});
                },
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
