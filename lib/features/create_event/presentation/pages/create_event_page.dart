import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/components/nav/create_event_app_bar.dart';
import '../../../../shared/components/forms/event_group_selector.dart';
import '../../../../shared/components/sections/date_time_section.dart';
import '../../../../shared/components/sections/location_section.dart';
import '../../../../shared/components/dialogs/event_history_dialog.dart';
import '../../../../shared/components/dialogs/group_selection_dialog.dart';
import '../../../../shared/components/dialogs/confirm_event_dialog.dart';
import '../../../../shared/components/dialogs/exit_confirmation_dialog.dart';
import '../../../../shared/models/event_draft.dart';
import '../../../../services/draft_service.dart';
import '../../../../shared/themes/colors.dart';

/// Página principal para criação de eventos
/// Usa todos os widgets tokenizados e reutilizáveis
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
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
  final DraftService _draftService = DraftService();

  // Controle de estado
  bool _hasInitializedFromDraft = false;
  bool _showValidationErrors = false;

  // Validation errors
  String? _nameError;
  String? _groupError;

  @override
  void initState() {
    super.initState();
    _loadDraftIfExists();
  }

  /// Carrega rascunho se existir
  Future<void> _loadDraftIfExists() async {
    if (_hasInitializedFromDraft) return;

    final draft = await _draftService.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _eventName = draft.eventName;
        _eventEmoji = draft.eventEmoji;
        _selectedGroup = draft.selectedGroup;
        _selectedDate = draft.selectedDate;
        _selectedTime = draft.selectedTime;
        _endDate = draft.endDate;
        _endTime = draft.endTime;
        _selectedLocation = draft.selectedLocation;
        _dateTimeState = draft.dateTimeState;
        _locationState = draft.locationState;
        _hasInitializedFromDraft = true;
      });
    }
  }

  /// Cria o rascunho atual
  EventDraft _getCurrentDraft() {
    return EventDraft(
      eventName: _eventName,
      eventEmoji: _eventEmoji,
      selectedGroup: _selectedGroup,
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
      endDate: _endDate,
      endTime: _endTime,
      selectedLocation: _selectedLocation,
      dateTimeState: _dateTimeState,
      locationState: _locationState,
      createdAt: DateTime.now(),
    );
  }

  /// Salva o rascunho atual
  Future<void> _saveDraft() async {
    final draft = _getCurrentDraft();
    await _draftService.saveDraft(draft);
  }

  /// Valida todos os campos obrigatórios
  void _validateFields() {
    setState(() {
      _showValidationErrors = true;

      // Validate name
      if (_eventName.trim().isEmpty || _eventName == 'Add Event Name') {
        _nameError = 'Event name is required';
      } else {
        _nameError = null;
      }

      // Validate group
      if (_selectedGroup == null) {
        _groupError = 'Please select a group';
      } else {
        _groupError = null;
      }
    });
  }

  /// Manipula o pressionamento do botão Continue
  void _handleContinuePressed() {
    _validateFields();

    if (_isFormValid) {
      _showConfirmDialog();
    }
    // If form is invalid, errors are now visible due to _validateFields call
  }

  /// Verifica se o formulário é válido
  bool get _isFormValid {
    return _nameError == null &&
        _groupError == null &&
        _eventName.trim().isNotEmpty &&
        _eventName != 'Add Event Name' &&
        _selectedGroup != null &&
        _isLocationValid &&
        _isDateTimeValid;
  }

  /// Verifica se a localização é válida
  bool get _isLocationValid {
    if (_locationState == LocationState.decideLater) {
      return true; // Decide later is always valid
    }

    // For "Set now", require either location data or location name
    return _selectedLocation != null &&
        (_selectedLocation!.formattedAddress.isNotEmpty ||
            (_selectedLocation!.displayName != null &&
                _selectedLocation!.displayName!.isNotEmpty));
  }

  /// Valida o estado atual da localização
  void _validateLocationState() {
    if (_locationState == LocationState.setNow && !_isLocationValid) {
      // Auto-switch back to "Decide later" if no valid location data
      setState(() {
        _locationState = LocationState.decideLater;
      });
    }
  }

  /// Obtém o erro de validação da localização
  String? _getLocationValidationError() {
    if (!_showValidationErrors) return null;

    if (_locationState == LocationState.setNow && !_isLocationValid) {
      return 'Please set a location or switch to "Decide later"';
    }
    return null;
  }

  /// Verifica se data e hora são válidas
  bool get _isDateTimeValid {
    if (_dateTimeState == DateTimeState.decideLater) {
      return true; // Decide later is always valid
    }

    // For "Set now", require start date and time
    if (_selectedDate == null || _selectedTime == null) {
      return false;
    }

    // If end date/time is set, validate that end > start
    if ((_endDate != null && _endTime != null)) {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      return endDateTime.isAfter(startDateTime);
    }

    return true;
  }

  /// Obtém o erro de validação de data e hora
  String? _getDateTimeValidationError() {
    if (!_showValidationErrors) return null;

    if (_dateTimeState == DateTimeState.decideLater) {
      return null;
    }

    if (_selectedDate == null || _selectedTime == null) {
      return 'Please set start date and time';
    }

    if ((_endDate != null && _endTime != null) && !_isDateTimeValid) {
      return 'End time must be after start time';
    }

    return null;
  }

  /// Define horário final padrão (6 horas após o início) se necessário
  void _setDefaultEndTimeIfNeeded() {
    if (_dateTimeState == DateTimeState.setNow &&
        _selectedDate != null &&
        _selectedTime != null &&
        _endDate == null &&
        _endTime == null) {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final endDateTime = startDateTime.add(Duration(hours: 6));

      setState(() {
        _endDate = endDateTime;
        _endTime = TimeOfDay.fromDateTime(endDateTime);
      });
    }
  }

  /// Manuseia o botão de voltar
  Future<bool> _onWillPop() async {
    final draft = _getCurrentDraft();

    // Se não tem alterações, pode sair
    if (!draft.hasChanges) {
      return true;
    }

    // Mostra dialog de confirmação
    _showExitConfirmation();
    return false; // Não sai automaticamente
  }

  /// Mostra dialog de confirmação de saída
  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExitConfirmationDialog(
        onSaveDraft: () async {
          await _saveDraft();
          if (mounted) {
            Navigator.of(context).pop(); // Sai da página
          }
        },
        onDiscard: () async {
          await _draftService.clearDraft();
          if (mounted) {
            Navigator.of(context).pop(); // Sai da página
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CreateEventAppBar(
          title: 'Create Event',
          isEditable: false,
          onHistoryPressed: _showEventHistory,
          onBackPressed: () => _onWillPop(),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: Insets.screenH),
          child: Column(
            children: [
              SizedBox(height: Gaps.lg),

              // Seleção de grupo e nome do evento
              EventGroupSelector(
                eventEmoji: _eventEmoji,
                eventName: _eventName.isEmpty ? 'Add Event Name' : _eventName,
                selectedGroup: _selectedGroup,
                nameError: _showValidationErrors ? _nameError : null,
                groupError: _showValidationErrors ? _groupError : null,
                onGroupPressed: _showGroupSelection,
                onEventNameChanged: (name) {
                  setState(() {
                    _eventName = name;
                    // Don't validate immediately on text change
                  });
                },
                onEmojiPressed: (emoji) {
                  setState(() {
                    _eventEmoji = emoji;
                  });
                },
              ),

              SizedBox(height: Gaps.md),

              // Seção de data e hora
              DateTimeSection(
                startDate: _selectedDate,
                startTime: _selectedTime,
                endDate: _endDate,
                endTime: _endTime,
                initialState: _dateTimeState,
                onStartDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _setDefaultEndTimeIfNeeded();
                },
                onStartTimeChanged: (time) {
                  setState(() {
                    _selectedTime = time;
                  });
                  _setDefaultEndTimeIfNeeded();
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
                onStateChanged: (state) {
                  setState(() {
                    _dateTimeState = state;
                  });
                },
                validationError: _getDateTimeValidationError(),
              ),

              SizedBox(height: Gaps.md),

              // Seção de localização
              LocationSection(
                selectedLocation: _selectedLocation,
                initialState: _locationState,
                onLocationChanged: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                onStateChanged: (state) {
                  setState(() {
                    _locationState = state;
                  });
                  _validateLocationState();
                },
                validationError: _getLocationValidationError(),
              ),

              SizedBox(height: 24),

              // Continue button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleContinuePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? BrandColors.planning
                          : BrandColors.bg3,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: AppText.titleMediumEmph.copyWith(
                        color: _isFormValid
                            ? BrandColors.text1
                            : BrandColors.text2,
                      ),
                    ),
                  ),
                ),
              ),

              // Espaço extra para scroll
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventHistoryBottomSheet(
        events: _getMockEventHistory(),
        onEventSelected: _loadEventFromHistory,
      ),
    );
  }

  void _showConfirmDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmEventBottomSheet(
        eventName: _eventName,
        eventEmoji: _eventEmoji,
        selectedGroup: _selectedGroup,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        endDate: _endDate,
        endTime: _endTime,
        selectedLocation: _selectedLocation,
        onCreateEvent: _createEvent,
      ),
    );
  }

  void _showGroupSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupSelectionBottomSheet(
        groups: _getMockGroups(),
        onGroupSelected: (group) {
          setState(() {
            _selectedGroup = group;
            // Don't validate immediately on group selection
          });
        },
        onCreateGroup: _createNewGroup,
      ),
    );
  }

  void _loadEventFromHistory(EventHistoryItem event) {
    setState(() {
      _eventName = event.name;
      _eventEmoji = event.emoji;

      // Carregar data: mesmo dia da semana ou dia seguinte
      if (event.lastDate != null) {
        final now = DateTime.now();
        final lastWeekday = event.lastDate!.weekday;
        var nextDate = now;

        // Encontrar próxima ocorrência do mesmo dia da semana
        while (nextDate.weekday != lastWeekday) {
          nextDate = nextDate.add(const Duration(days: 1));
        }

        // Se for hoje e já passou a hora, usar próxima semana
        if (nextDate.day == now.day &&
            event.lastTime != null &&
            TimeOfDay.now().hour >= event.lastTime!.hour) {
          nextDate = nextDate.add(const Duration(days: 7));
        }

        _selectedDate = nextDate;
        _dateTimeState = DateTimeState.setNow;
      }

      // Manter a mesma hora
      if (event.lastTime != null) {
        _selectedTime = event.lastTime;
        _dateTimeState = DateTimeState.setNow;
      }

      // Carregar localização se existir
      if (event.location != null) {
        _selectedLocation = LocationInfo(
          id: 'history',
          displayName: event.location!,
          formattedAddress: event.location!,
          latitude: 0.0,
          longitude: 0.0,
        );
        _locationState = LocationState.setNow;
      }
    });
  }

  void _createNewGroup() {
    // Navegar para página de criação de grupo
    // Por enquanto, mostrar snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Group feature coming soon!')),
    );
  }

  void _createEvent() async {
    // Clear draft since event is being created
    await _draftService.clearDraft();

    // Navigate back to main layout (which includes home page with nav bar)
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (Route<dynamic> route) => false,
        arguments: {
          'showSuccessBanner': true,
          'eventName': _eventName.isEmpty ? 'Untitled Event' : _eventName,
          'groupName': _selectedGroup?.name ?? 'No Group',
        },
      );
    }
  }

  List<EventHistoryItem> _getMockEventHistory() {
    return [
      EventHistoryItem(
        id: '1',
        name: 'Baza ao Rio',
        emoji: '🍖',
        lastDate: DateTime.now().subtract(const Duration(days: 7)),
        lastTime: const TimeOfDay(hour: 19, minute: 30),
        location: 'Tascardoso, Lisboa',
        groupId: 'group1',
      ),
      EventHistoryItem(
        id: '2',
        name: 'Futebol',
        emoji: '⚽',
        lastDate: DateTime.now().subtract(const Duration(days: 14)),
        lastTime: const TimeOfDay(hour: 18, minute: 0),
        location: 'Campo do Jamor',
        groupId: 'group1',
      ),
      EventHistoryItem(
        id: '3',
        name: 'Cinema Night',
        emoji: '🎬',
        lastDate: DateTime.now().subtract(const Duration(days: 21)),
        lastTime: const TimeOfDay(hour: 21, minute: 0),
        location: 'Cinemas NOS Amoreiras',
        groupId: 'group2',
      ),
    ];
  }

  List<GroupInfo> _getMockGroups() {
    return [
      const GroupInfo(id: 'group1', name: 'Os Bros', memberCount: 8),
      const GroupInfo(id: 'group2', name: 'Família', memberCount: 5),
      const GroupInfo(id: 'group3', name: 'Work Squad', memberCount: 12),
      const GroupInfo(id: 'group4', name: 'Uni Friends', memberCount: 15),
      const GroupInfo(id: 'group5', name: 'Football Team', memberCount: 22),
      const GroupInfo(id: 'group6', name: 'Hiking Group', memberCount: 7),
    ];
  }
}
