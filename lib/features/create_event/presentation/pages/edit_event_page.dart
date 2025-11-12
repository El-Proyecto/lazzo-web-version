import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../widgets/event_group_selector.dart';
import '../widgets/date_time_section.dart';
import '../widgets/location_section.dart'; // Use original version from commit 6641830
import '../widgets/create_event_app_bar.dart'; // Import CreateEventAppBar
// import '../../../../shared/models/event_draft.dart'; // Commented for P1 - conflicts with Google Maps
// import '../../../../services/draft_service.dart'; // Commented for P1
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../domain/entities/event.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../providers/event_providers.dart';
import '../../../event/presentation/providers/event_providers.dart' as event_providers;
import '../../../home/presentation/providers/pending_event_providers.dart' as home_providers;

/// Página para edição de eventos existentes
/// Reutiliza todos os widgets tokenizados da criação de eventos
class EditEventPage extends ConsumerStatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  ConsumerState<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends ConsumerState<EditEventPage> {
  // Estado do evento
  String _eventName = '';
  String _eventEmoji = '🍖';
  GroupInfo? _selectedGroup;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  LocationInfo? _selectedLocation;

  // Estados das seções
  DateTimeState _dateTimeState = DateTimeState.decideLater;
  LocationState _locationState = LocationState.decideLater;

  // Serviços
  // final DraftService _draftService = DraftService(); // Commented for P1

  // Controle de estado
  bool _showValidationErrors = false;

  // Valores iniciais para detectar alterações
  late String _initialEventName;
  late String _initialEventEmoji;
  late GroupInfo? _initialSelectedGroup;
  late DateTime? _initialSelectedDate;
  late TimeOfDay? _initialSelectedTime;
  late DateTime? _initialEndDate;
  late TimeOfDay? _initialEndTime;
  late LocationInfo? _initialSelectedLocation;
  late DateTimeState _initialDateTimeState;
  late LocationState _initialLocationState;

  // Validation errors
  String? _nameError;
  String? _groupError;

  @override
  void initState() {
    super.initState();
    _initializeFromEvent();
  }

  /// Inicializa o estado da página com os dados do evento
  void _initializeFromEvent() {
    final event = widget.event;

    _eventName = event.name;
    _eventEmoji = event.emoji;

    // Load group from groupId - using mock data for now
    final mockGroups = _getMockGroups();
    _selectedGroup =
        mockGroups.where((group) => group.id == event.groupId).firstOrNull;

    // Se não encontrar o grupo nos mocks, criar um temporário com o ID do evento
    if (_selectedGroup == null && event.groupId.isNotEmpty) {
      _selectedGroup = GroupInfo(
        id: event.groupId,
        name: 'Grupo ${event.groupId}',
        memberCount: 1,
      );
    }

    if (event.startDateTime != null) {
      _selectedDate = DateTime(
        event.startDateTime!.year,
        event.startDateTime!.month,
        event.startDateTime!.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(event.startDateTime!);
      _dateTimeState = DateTimeState.setNow;
    }

    if (event.endDateTime != null) {
      _endDate = DateTime(
        event.endDateTime!.year,
        event.endDateTime!.month,
        event.endDateTime!.day,
      );
      _endTime = TimeOfDay.fromDateTime(event.endDateTime!);
    }

    if (event.location != null) {
      _selectedLocation = LocationInfo(
        id: event.location!.id,
        displayName: event.location!.displayName,
        formattedAddress: event.location!.formattedAddress,
        latitude: event.location!.latitude,
        longitude: event.location!.longitude,
      );
      _locationState = LocationState.setNow;
    }

    // Armazenar valores iniciais após todas as inicializações
    _storeInitialValues();
  }

  /// Armazena os valores iniciais para detectar alterações
  void _storeInitialValues() {
    _initialEventName = _eventName;
    _initialEventEmoji = _eventEmoji;
    _initialSelectedGroup = _selectedGroup;
    _initialSelectedDate = _selectedDate;
    _initialSelectedTime = _selectedTime;
    _initialEndDate = _endDate;
    _initialEndTime = _endTime;
    _initialSelectedLocation = _selectedLocation;
    _initialDateTimeState = _dateTimeState;
    _initialLocationState = _locationState;
  }

  /// Detecta se há alterações não salvas
  bool _hasChanges() {
    return _eventName != _initialEventName ||
        _eventEmoji != _initialEventEmoji ||
        _selectedGroup?.id != _initialSelectedGroup?.id ||
        _selectedDate != _initialSelectedDate ||
        _selectedTime != _initialSelectedTime ||
        _endDate != _initialEndDate ||
        _endTime != _initialEndTime ||
        _selectedLocation?.id != _initialSelectedLocation?.id ||
        _dateTimeState != _initialDateTimeState ||
        _locationState != _initialLocationState;
  }

  /// Cria o rascunho atual (Commented for P1)
  // EventDraft _createCurrentDraft() {
  //   return EventDraft(
  //     eventName: _eventName,
  //     eventEmoji: _eventEmoji,
  //     selectedGroup: _selectedGroup,
  //     selectedDate: _selectedDate,
  //     selectedTime: _selectedTime,
  //     endDate: _endDate,
  //     endTime: _endTime,
  //     selectedLocation: _selectedLocation,
  //     dateTimeState: _dateTimeState,
  //     locationState: _locationState,
  //     createdAt: DateTime.now(),
  //   );
  // }

  /// Valida os campos obrigatórios
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _nameError = null;
      _groupError = null;
    });

    if (_eventName.trim().isEmpty) {
      setState(() {
        _nameError = 'Nome do evento é obrigatório';
      });
      isValid = false;
    }

    if (_selectedGroup == null) {
      setState(() {
        _groupError = 'Selecione um grupo';
      });
      isValid = false;
    }

    // Validações específicas para cada estado
    if (_dateTimeState == DateTimeState.setNow) {
      if (_selectedDate == null || _selectedTime == null) {
        isValid = false;
      }
    }

    if (_locationState == LocationState.setNow) {
      if (_selectedLocation == null) {
        isValid = false;
      }
    }

    return isValid;
  }

  /// Verifica se o formulário é válido (sem mostrar erros)
  bool _isFormValid() {
    // Nome é obrigatório
    bool nameValid = _eventName.trim().isNotEmpty;

    // Grupo é obrigatório - mas na edição mantemos o grupo original se não foi alterado
    bool groupValid = _selectedGroup != null || widget.event.groupId.isNotEmpty;

    // Data/hora é válida se for "decide later" ou se tiver ambos data e hora definidos
    bool dateTimeValid = (_dateTimeState == DateTimeState.decideLater ||
        (_selectedDate != null && _selectedTime != null));

    // Localização é válida se for "decide later" ou se tiver localização definida
    bool locationValid = (_locationState == LocationState.decideLater ||
        _selectedLocation != null);

    return nameValid && groupValid && dateTimeValid && locationValid;
  }

  /// Lida com a tentativa de salvar o evento
  void _handleSaveEvent() {
    // Se o botão está verde (isFormValid && hasChanges), salva diretamente
    if (_isFormValid() && _hasChanges()) {
      _updateEvent();
      return;
    }

    // Caso contrário, mostra os erros de validação
    if (!_showValidationErrors) {
      setState(() {
        _showValidationErrors = true;
      });
    }

    if (_validateForm()) {
      _showConfirmEventDialog();
    }
  }

  /// Mostra o dialog de confirmação de atualização
  void _showConfirmEventDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Atualizar Evento',
        message: 'Tem certeza que deseja salvar as alterações?',
        confirmText: 'Salvar Alterações',
        cancelText: 'Cancelar',
        isDestructive: false,
        onConfirm: _updateEvent,
      ),
    );
  }

  /// Atualiza o evento
  Future<void> _updateEvent() async {
    final controller = ref.read(editEventControllerProvider.notifier);

    // Construct DateTime objects from date/time components
    DateTime? startDateTime;
    DateTime? endDateTime;

    if (_dateTimeState == DateTimeState.setNow &&
        _selectedDate != null &&
        _selectedTime != null) {
      startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }
    }

    // Convert LocationInfo to EventLocation
    EventLocation? eventLocation;
    if (_locationState == LocationState.setNow && _selectedLocation != null) {
      final loc = _selectedLocation!;
      eventLocation = EventLocation(
        id: loc.id,
        displayName: loc.displayName ?? loc.formattedAddress,
        formattedAddress: loc.formattedAddress,
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
    }

    // Call the use case through the controller
    await controller.updateEvent(
      eventId: widget.event.id,
      name: _eventName,
      emoji: _eventEmoji,
      groupId: widget.event.groupId, // Keep original group for edit
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: eventLocation,
    );

    // CRITICAL: Invalidate providers to force UI refresh across the app
    // 1. Event detail page (shows updated date/time/location)
    ref.invalidate(event_providers.eventDetailProvider(widget.event.id));
    // 2. Pending events list (home page - shows updated scheduled date)
    ref.invalidate(home_providers.pendingEventsControllerProvider);
    // 3. Date/time suggestions (ensures synced suggestion shows correctly)
    ref.invalidate(event_providers.eventSuggestionsProvider(widget.event.id));
    // 4. Location suggestions (ensures synced suggestion shows correctly)
    ref.invalidate(event_providers.eventLocationSuggestionsProvider(widget.event.id));
    // 5. Suggestion votes (refresh vote counts)
    ref.invalidate(event_providers.suggestionVotesProvider(widget.event.id));
    ref.invalidate(event_providers.userSuggestionVotesProvider(widget.event.id));

    // Reset initial values after successful update
    setState(() {
      _storeInitialValues();
    });

    // Navigate back to previous page
    // Pop twice: once for dialog (if shown), once for edit page
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close dialog if shown
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Return to previous page
    }
  }

  /// Mostra dialog de confirmação de exclusão
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Event',
        message:
            'Are you sure you want to delete this event? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDestructive: true,
        onConfirm: _deleteEvent,
      ),
    );
  }

  /// Exclui o evento
  Future<void> _deleteEvent() async {
    final controller = ref.read(editEventControllerProvider.notifier);

    // Call delete through controller
    await controller.deleteEvent(widget.event.id);

    // Navigate back
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close dialog
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Return to previous page
    }
  }

  /// Lida com o botão de voltar ou tentativa de sair
  void _handleBackPressed() {
    if (_hasChanges()) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Mostra dialog de confirmação para alterações não salvas
  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Unsaved Changes',
        message:
            'You have unsaved changes. Do you want to save them before leaving?',
        confirmText: 'Save',
        cancelText: 'Discard',
        isDestructive: false,
        onConfirm: () {
          if (_isFormValid()) {
            _updateEvent(); // This already navigates back
          } else {
            // Close dialog first, then show validation errors
            Navigator.of(context).pop();
            setState(() {
              _showValidationErrors = true;
            });
          }
        },
        onCancel: () {
          Navigator.of(context).pop(); // Sair sem salvar
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to edit state for loading/error handling
    ref.listen<EditEventState>(editEventControllerProvider, (previous, next) {
      if (next.error != null) {
        TopBanner.showError(
          context,
          message: 'Error: ${next.error}',
        );
      }
    });

    final editState = ref.watch(editEventControllerProvider);
    return PopScope(
      canPop: !_hasChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges()) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CreateEventAppBar(
          title: 'Edit Event',
          onBackPressed: _handleBackPressed,
          trailingAction: GestureDetector(
            onTap: _showDeleteConfirmationDialog,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline,
                color: BrandColors.cantVote,
                size: 20,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screenH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Gaps.lg),

                    // Seletor de nome e grupo do evento
                    EventGroupSelector(
                      eventName: _eventName,
                      eventEmoji: _eventEmoji,
                      selectedGroup: _selectedGroup,
                      isGroupReadOnly:
                          true, // Não permitir mudança de grupo na edição
                      onEventNameChanged: (value) {
                        setState(() {
                          _eventName = value;
                        });

                        // Clear name error if valid
                        if (_showValidationErrors && value.trim().isNotEmpty) {
                          setState(() {
                            _nameError = null;
                          });
                        }
                      },
                      onEmojiPressed: (emoji) {
                        setState(() {
                          _eventEmoji = emoji;
                        });
                      },
                      onGroupPressed: null, // Disabled for edit mode
                      nameError: _showValidationErrors ? _nameError : null,
                      groupError: _showValidationErrors ? _groupError : null,
                    ),

                    const SizedBox(height: Gaps.md),

                    // Seção de Date & Time
                    DateTimeSection(
                      startDate: _selectedDate,
                      startTime: _selectedTime,
                      endDate: _endDate,
                      endTime: _endTime,
                      initialState: _dateTimeState,
                      onStateChanged: (state) {
                        setState(() {
                          _dateTimeState = state;
                          if (state == DateTimeState.decideLater) {
                            _selectedDate = null;
                            _selectedTime = null;
                            _endDate = null;
                            _endTime = null;
                          }
                        });
                      },
                      onStartDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      onStartTimeChanged: (time) {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                      onEndDateChanged: (date) {
                        setState(() {
                          _endDate = date;
                        });
                      },
                      onEndTimeChanged: (time) {
                        setState(() {
                          _endTime = time;
                        });
                      },
                    ),

                    const SizedBox(height: Gaps.md),

                    // Seção de Localização
                    LocationSection(
                      selectedLocation: _selectedLocation,
                      initialState: _locationState,
                      onStateChanged: (state) {
                        setState(() {
                          _locationState = state;
                          if (state == LocationState.decideLater) {
                            _selectedLocation = null;
                          }
                        });
                      },
                      onLocationChanged: (location) {
                        setState(() {
                          _selectedLocation = location;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Botão de salvar
            Container(
              padding: const EdgeInsets.all(Insets.screenH),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isFormValid() && _hasChanges() && !editState.isLoading)
                          ? _handleSaveEvent
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isFormValid() && _hasChanges())
                        ? BrandColors.planning
                        : BrandColors.bg3,
                    foregroundColor: (_isFormValid() && _hasChanges())
                        ? Colors.white
                        : BrandColors.text2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    elevation: 0,
                  ),
                  child: editState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: AppText.labelLarge.copyWith(
                            color: (_isFormValid() && _hasChanges())
                                ? Colors.white
                                : BrandColors.text2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mock data para grupos - TODO: Remover quando tiver integração real
  List<GroupInfo> _getMockGroups() {
    return [
      const GroupInfo(id: '1', name: 'Amigos da Faculdade', memberCount: 12),
      const GroupInfo(id: '2', name: 'Família', memberCount: 8),
      const GroupInfo(id: '3', name: 'Trabalho', memberCount: 15),
    ];
  }
}
