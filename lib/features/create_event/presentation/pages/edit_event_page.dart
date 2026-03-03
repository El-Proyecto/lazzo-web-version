import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../widgets/event_name_selector.dart';
import '../widgets/date_time_section.dart';
import '../widgets/location_section.dart'; // Use original version from commit 6641830
import '../widgets/description_section.dart';
import '../../../../shared/components/nav/common_app_bar.dart'; // Import CommonAppBar
// import '../../../../shared/models/event_draft.dart'; // Commented for P1 - conflicts with Google Maps
// import '../../../../services/draft_service.dart'; // Commented for P1
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../domain/entities/event.dart';
import '../../../../shared/components/dialogs/confirmation_dialog.dart';
import '../providers/event_providers.dart';
import '../../../event/presentation/providers/event_providers.dart'
    as event_providers;
import '../../../event/domain/entities/rsvp.dart' show RsvpStatus;
import '../../../home/presentation/providers/home_event_providers.dart'
    as home_providers;
import '../../../../routes/app_router.dart';
import '../../../../services/analytics_service.dart';

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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  LocationInfo? _selectedLocation;
  String? _description;

  // Serviços
  // final DraftService _draftService = DraftService(); // Commented for P1

  // Controle de estado
  bool _showValidationErrors = false;

  // Valores iniciais para detectar alterações
  late String _initialEventName;
  late String _initialEventEmoji;
  late DateTime? _initialSelectedDate;
  late TimeOfDay? _initialSelectedTime;
  late DateTime? _initialEndDate;
  late TimeOfDay? _initialEndTime;
  late LocationInfo? _initialSelectedLocation;
  late String? _initialDescription;

  // Validation errors
  String? _nameError;

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

    if (event.startDateTime != null) {
      _selectedDate = DateTime(
        event.startDateTime!.year,
        event.startDateTime!.month,
        event.startDateTime!.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(event.startDateTime!);
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
    }

    _description = event.description;

    // Armazenar valores iniciais após todas as inicializações
    _storeInitialValues();
  }

  /// Armazena os valores iniciais para detectar alterações
  void _storeInitialValues() {
    _initialEventName = _eventName;
    _initialEventEmoji = _eventEmoji;
    _initialSelectedDate = _selectedDate;
    _initialSelectedTime = _selectedTime;
    _initialEndDate = _endDate;
    _initialEndTime = _endTime;
    _initialSelectedLocation = _selectedLocation;
    _initialDescription = _description;
  }

  /// Detecta se há alterações não salvas
  bool _hasChanges() {
    return _eventName != _initialEventName ||
        _eventEmoji != _initialEventEmoji ||
        _selectedDate != _initialSelectedDate ||
        _selectedTime != _initialSelectedTime ||
        _endDate != _initialEndDate ||
        _endTime != _initialEndTime ||
        _selectedLocation?.id != _initialSelectedLocation?.id ||
        _description != _initialDescription;
  }

  /// Cria o rascunho atual (Commented for P1)
  // EventDraft _createCurrentDraft() {
  //   return EventDraft(
  //     eventName: _eventName,
  //     eventEmoji: _eventEmoji,
  //     selectedDate: _selectedDate,
  //     selectedTime: _selectedTime,
  //     endDate: _endDate,
  //     endTime: _endTime,
  //     selectedLocation: _selectedLocation,
  //     createdAt: DateTime.now(),
  //   );
  // }

  /// Valida os campos obrigatórios
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _nameError = null;
    });

    if (_eventName.trim().isEmpty) {
      setState(() {
        _nameError = 'Nome do evento é obrigatório';
      });
      isValid = false;
    }

    // Date/time is mandatory: both start and end required
    if (_selectedDate == null ||
        _selectedTime == null ||
        _endDate == null ||
        _endTime == null) {
      isValid = false;
    }

    // Location is mandatory
    if (_selectedLocation == null) {
      isValid = false;
    }

    return isValid;
  }

  /// Verifica se o formulário é válido (sem mostrar erros)
  bool _isFormValid() {
    // Nome é obrigatório
    bool nameValid = _eventName.trim().isNotEmpty;

    // Data/hora é obrigatória: start e end
    bool dateTimeValid = _selectedDate != null &&
        _selectedTime != null &&
        _endDate != null &&
        _endTime != null;

    // Localização é obrigatória (name or address)
    bool locationValid = false;
    if (_selectedLocation != null) {
      final hasAddress = _selectedLocation!.formattedAddress.isNotEmpty;
      final hasName = _selectedLocation!.displayName != null &&
          _selectedLocation!.displayName!.isNotEmpty;
      locationValid = hasAddress || hasName;
    }

    return nameValid && dateTimeValid && locationValid;
  }

  /// Obtém o erro de validação de localização
  String? _getLocationValidationError() {
    if (!_showValidationErrors) return null;
    if (_selectedLocation == null) return 'Location is required';
    return null;
  }

  /// Verifica se data e hora são válidas
  bool get _isDateTimeValid {
    // Date/time is mandatory — both start and end required
    if (_selectedDate == null || _selectedTime == null) return false;
    if (_endDate == null || _endTime == null) return false;

    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Check if start date/time is in the past
    if (startDateTime.isBefore(now)) {
      return false;
    }

    // End must be after start
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    return endDateTime.isAfter(startDateTime);
  }

  /// Obtém o erro de validação de data e hora
  String? _getDateTimeValidationError() {
    if (!_showValidationErrors) return null;

    // Start date and time are mandatory
    if (_selectedDate == null || _selectedTime == null) {
      return 'Start date and time are required';
    }

    // End date and time are mandatory
    if (_endDate == null || _endTime == null) {
      return 'End date and time are required';
    }

    // Check if start date/time is in the past
    final now = DateTime.now();
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (startDateTime.isBefore(now)) {
      return 'Event date cannot be in the past';
    }

    if (!_isDateTimeValid) {
      return 'End time must be after start time';
    }

    return null;
  }

  /// Lida com a tentativa de salvar o evento
  void _handleSaveEvent() {
    // Se não há alterações, mostrar topBanner
    if (!_hasChanges()) {
      TopBanner.showInfo(
        context,
        message: 'No changes made',
      );
      return;
    }

    // Se há alterações e são válidas, salva diretamente
    if (_isFormValid() && _hasChanges()) {
      _updateEvent();
      return;
    }

    // Se há alterações mas são inválidas, mostrar erros de validação
    setState(() {
      _showValidationErrors = true;
    });
    _validateForm();
  }

  /// Atualiza o evento
  Future<void> _updateEvent() async {
    final controller = ref.read(editEventControllerProvider.notifier);

    // Construct DateTime objects from date/time components
    DateTime? startDateTime;
    DateTime? endDateTime;

    if (_selectedDate != null && _selectedTime != null) {
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
    if (_selectedLocation != null) {
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
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: eventLocation,
      description: _description,
    );

    // CRITICAL: Invalidate providers to force UI refresh across the app
    // 1. Event detail page (shows updated date/time/location)
    ref.invalidate(event_providers.eventDetailProvider(widget.event.id));

    // Host auto-vote: ensure host always has "Can" vote after editing
    // isAutoVote: true to skip analytics tracking (not a user-initiated RSVP)
    await ref
        .read(event_providers.userRsvpProvider(widget.event.id).notifier)
        .submitVote(RsvpStatus.going, isAutoVote: true);

    // 2. Home page providers (shows updated event in lists)
    ref.invalidate(home_providers.nextEventControllerProvider);
    ref.invalidate(home_providers.confirmedEventsControllerProvider);
    ref.invalidate(home_providers.homeEventsControllerProvider);
    ref.invalidate(home_providers.todosControllerProvider);

    // Reset initial values after successful update
    setState(() {
      _storeInitialValues();
    });

    // Track event_edited with changed fields
    final fieldsChanged = <String>[
      if (_eventName != _initialEventName) 'name',
      if (_eventEmoji != _initialEventEmoji) 'emoji',
      if (_selectedDate != _initialSelectedDate ||
          _selectedTime != _initialSelectedTime)
        'start_datetime',
      if (_endDate != _initialEndDate || _endTime != _initialEndTime)
        'end_datetime',
      if (_selectedLocation?.id != _initialSelectedLocation?.id) 'location',
      if (_description != _initialDescription) 'description',
    ];
    AnalyticsService.track('event_edited', properties: {
      'event_id': widget.event.id,
      'fields_changed': fieldsChanged,
      'platform': 'ios',
    });

    // Pop back to the existing event page (providers already invalidated)
    if (mounted) {
      Navigator.of(context).pop();
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

    try {
      // Call delete through controller
      await controller.deleteEvent(widget.event.id);

      // Invalidate providers to refresh home page
      ref.invalidate(home_providers.nextEventControllerProvider);
      ref.invalidate(home_providers.confirmedEventsControllerProvider);
      ref.invalidate(home_providers.homeEventsControllerProvider);
      ref.invalidate(home_providers.todosControllerProvider);

      // Invalidate event detail if coming from it
      ref.invalidate(event_providers.eventDetailProvider(widget.event.id));

      // Show success banner
      if (mounted) {
        TopBanner.showSuccess(
          context,
          message: 'Event deleted successfully',
        );
      }

      // Navigate to home after delete
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
        );
      }
    } catch (e) {
      // Show error banner with detailed message
      if (mounted) {
        TopBanner.showError(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
      // Close dialog but stay on edit page
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close dialog only
      }
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
    final bool isValid = _isFormValid();

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Unsaved Changes',
        message: isValid
            ? 'You have unsaved changes. Do you want to save them before leaving?'
            : 'You have unsaved changes but they are not valid. Discard them?',
        confirmText: isValid ? 'Save' : null,
        cancelText: 'Discard',
        isDestructive: false,
        onConfirm: isValid
            ? () {
                _updateEvent(); // This already navigates back
              }
            : null,
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

    return PopScope(
      canPop: !_hasChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges()) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CommonAppBar(
          title: 'Edit Event',
          leading: GestureDetector(
            onTap: _handleBackPressed,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios,
                color: BrandColors.text1,
                size: 20,
              ),
            ),
          ),
          trailing: GestureDetector(
            onTap: _showDeleteConfirmationDialog,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline,
                color: BrandColors.cantVote,
                size: 20,
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Insets.screenH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Gaps.lg),

                      // Seletor de nome do evento
                      EventNameSelector(
                        eventName: _eventName,
                        eventEmoji: _eventEmoji,
                        onEventNameChanged: (value) {
                          setState(() {
                            _eventName = value;
                          });

                          // Clear name error if valid
                          if (_showValidationErrors &&
                              value.trim().isNotEmpty) {
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
                        nameError: _showValidationErrors ? _nameError : null,
                      ),

                      const SizedBox(height: Gaps.md),

                      // Seção de Date & Time
                      DateTimeSection(
                        startDate: _selectedDate,
                        startTime: _selectedTime,
                        endDate: _endDate,
                        endTime: _endTime,
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
                        validationError: _getDateTimeValidationError(),
                      ),

                      const SizedBox(height: Gaps.md),

                      // Seção de Localização
                      LocationSection(
                        selectedLocation: _selectedLocation,
                        onLocationChanged: (location) {
                          setState(() {
                            _selectedLocation = location;
                          });
                        },
                        validationError: _getLocationValidationError(),
                      ),

                      const SizedBox(height: Gaps.md),

                      // Seção de Details
                      DescriptionSection(
                        description: _description,
                        onDescriptionChanged: (description) {
                          setState(() {
                            _description = description;
                          });
                        },
                      ),

                      const SizedBox(height: Gaps.lg),
                    ],
                  ),
                ),
              ),

              // Save Changes button - fixed at bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.screenH,
                  Gaps.sm,
                  Insets.screenH,
                  Insets.screenBottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSaveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isFormValid() && _hasChanges())
                          ? BrandColors.planning
                          : BrandColors.bg3,
                      padding: const EdgeInsets.symmetric(vertical: Pads.ctlV),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: AppText.titleMediumEmph.copyWith(
                        color: (_isFormValid() && _hasChanges())
                            ? BrandColors.text1
                            : BrandColors.text2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ), // GestureDetector
      ),
    );
  }
}
