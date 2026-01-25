import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../widgets/event_group_selector.dart';
import '../widgets/date_time_section.dart';
import '../widgets/location_section.dart';
import '../widgets/event_history_dialog.dart';
import '../widgets/group_selection_dialog.dart';
import '../widgets/confirm_event_dialog.dart';
import '../widgets/exit_confirmation_dialog.dart';
import '../../../../shared/models/event_draft.dart';
import '../../../../services/draft_service.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../providers/event_history_provider.dart';
import '../../../home/presentation/providers/home_event_providers.dart';

/// Página principal para criação de eventos
/// Usa todos os widgets tokenizados e reutilizáveis
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  // Estado do evento
  String _eventName = '';
  String? _eventEmoji;
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

  /// Helper function to convert a single Group entity to GroupInfo with image URL
  Future<GroupInfo> _convertGroupToGroupInfo(Group group, WidgetRef ref) async {
    String? imageUrl;

    // Get image URL if the group has a photo
    if (group.photoPath != null && group.photoPath!.isNotEmpty) {
      try {
        imageUrl = await ref.read(
            groupCoverUrlProvider((group.photoPath, group.photoUpdatedAt))
                .future);
      } catch (e) {
        imageUrl = null;
      }
    }

    return GroupInfo(
      id: group.id,
      name: group.name,
      memberCount: group.memberCount,
      imageUrl: imageUrl,
    );
  }

  /// Helper function to convert Group entities to GroupInfo with image URLs
  Future<List<GroupInfo>> _loadGroupInfosWithImages(
      List<Group> groups, WidgetRef ref) async {
    final List<GroupInfo> groupInfos = [];

    for (final group in groups) {
      final groupInfo = await _convertGroupToGroupInfo(group, ref);
      groupInfos.add(groupInfo);
    }

    return groupInfos;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigationArguments();
      _loadDraftIfExists();
    });
  }

  /// Verifica se existe um grupo pré-selecionado nos argumentos de navegação
  void _handleNavigationArguments() async {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['groupId'] != null) {
      final groupId = arguments['groupId'] as String;

      // Buscar grupos reais do Supabase
      final groupsAsync = ref.read(groupsProvider);
      groupsAsync.when(
        data: (groups) async {
          final selectedGroup =
              groups.where((group) => group.id == groupId).firstOrNull;
          if (selectedGroup != null && mounted) {
            final groupInfo =
                await _convertGroupToGroupInfo(selectedGroup, ref);
            if (mounted) {
              setState(() {
                _selectedGroup = groupInfo;
              });
            }
          }
        },
        loading: () {
          // Groups are loading, we'll handle this in the group selection dialog
        },
        error: (error, stackTrace) {
          // Handle error if needed
        },
      );
    }
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
    final basicFieldsValid = _nameError == null &&
        _groupError == null &&
        _eventName.trim().isNotEmpty &&
        _eventName != 'Add Event Name' &&
        _selectedGroup != null;

    // All fields must be valid: basic fields + location + datetime
    // Location and DateTime are valid if "Decide Later" OR properly filled when "Set Now"
    return basicFieldsValid && _isLocationValid && _isDateTimeValid;
  }

  /// Verifica se a localização é válida
  bool get _isLocationValid {
    if (_locationState == LocationState.decideLater) {
      return true; // Decide later is always valid
    }

    // For "Set now", require at least one field:
    // Location object must exist AND have either formattedAddress OR displayName
    if (_selectedLocation != null) {
      final hasAddress = _selectedLocation!.formattedAddress.isNotEmpty;
      final hasName = _selectedLocation!.displayName != null &&
          _selectedLocation!.displayName!.isNotEmpty;
      return hasAddress || hasName;
    }

    // If no location is set when "Set Now" is selected, it's invalid
    return false;
  }

  /// Valida o estado atual da localização
  void _validateLocationState() {
    // Don't auto-switch to "Decide later" when user is actively editing location
    // This was causing the bug where clicking "Change" would disable the Continue button
    // The validation will handle the invalid state by showing an error message instead
  }

  /// Obtém o erro de validação da localização
  String? _getLocationValidationError() {
    if (!_showValidationErrors) return null;

    if (_locationState == LocationState.setNow && !_isLocationValid) {
      return 'Please fill in at least one field: Location name or Address';
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

    // If end date/time is set, validate that end > start
    if ((_endDate != null && _endTime != null)) {
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

      final endDateTime = startDateTime.add(const Duration(hours: 6));

      setState(() {
        _endDate = endDateTime;
        _endTime = TimeOfDay.fromDateTime(endDateTime);
      });
    }
  }

  /// Limpa erros de validação se os campos estão válidos
  void _clearValidationErrorsIfValid() {
    if (!_showValidationErrors) return;

    setState(() {
      // Clear name error if name is valid
      if (_nameError != null &&
          _eventName.trim().isNotEmpty &&
          _eventName != 'Add Event Name') {
        _nameError = null;
      }

      // Clear group error if group is selected
      if (_groupError != null && _selectedGroup != null) {
        _groupError = null;
      }
    });
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
          final navigator = Navigator.of(context);
          await _saveDraft();
          if (mounted) {
            navigator.pop(); // Exit Create Event page
          }
        },
        onDiscard: () async {
          final navigator = Navigator.of(context);
          await _draftService.clearDraft();
          if (mounted) {
            navigator.pop(); // Exit Create Event page
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CommonAppBar(
          title: 'Create Event',
          leading: GestureDetector(
            onTap: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                navigator.pop();
              }
            },
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
            onTap: _showEventHistory,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.history,
                color: BrandColors.text1,
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
                  children: [
                    const SizedBox(height: Gaps.lg),

                    // Seleção de grupo e nome do evento
                    EventGroupSelector(
                      key: const Key('createEvent:groupSelector'),
                      eventEmoji: _eventEmoji,
                      eventName:
                          _eventName.isEmpty ? 'Add Event Name' : _eventName,
                      nameFieldKey: const Key('createEvent:name'),
                      groupButtonKey: const Key('createEvent:groupButton'),
                      selectedGroup: _selectedGroup,
                      nameError: _showValidationErrors ? _nameError : null,
                      groupError: _showValidationErrors ? _groupError : null,
                      onGroupPressed: _showGroupSelection,
                      onEventNameChanged: (name) {
                        setState(() {
                          _eventName = name;
                          // Clear error if field is now valid
                          if (_showValidationErrors &&
                              name.trim().isNotEmpty &&
                              name != 'Add Event Name') {
                            _nameError = null;
                          }
                        });
                      },
                      onEmojiPressed: (emoji) {
                        setState(() {
                          _eventEmoji = emoji;
                        });
                      },
                    ),

                    const SizedBox(height: Gaps.md),

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
                        _clearValidationErrorsIfValid();
                      },
                      onStartTimeChanged: (time) {
                        setState(() {
                          _selectedTime = time;
                        });
                        _setDefaultEndTimeIfNeeded();
                        _clearValidationErrorsIfValid();
                      },
                      onEndDateChanged: (date) {
                        setState(() {
                          _endDate = date;
                        });
                        _clearValidationErrorsIfValid();
                      },
                      onEndTimeChanged: (time) {
                        setState(() {
                          _endTime = time;
                        });
                        _clearValidationErrorsIfValid();
                      },
                      onStateChanged: (state) {
                        setState(() {
                          _dateTimeState = state;
                        });
                        // Clear validation errors if state becomes valid
                        _clearValidationErrorsIfValid();
                      },
                      validationError: _getDateTimeValidationError(),
                    ),

                    const SizedBox(height: Gaps.md),

                    // Seção de localização
                    LocationSection(
                      selectedLocation: _selectedLocation,
                      initialState: _locationState,
                      onLocationChanged: (location) {
                        setState(() {
                          _selectedLocation = location;
                        });
                        // Clear validation errors if location becomes valid
                        _clearValidationErrorsIfValid();
                      },
                      onStateChanged: (state) {
                        setState(() {
                          _locationState = state;
                        });
                        _validateLocationState();
                        // Clear validation errors if state becomes valid
                        _clearValidationErrorsIfValid();
                      },
                      validationError: _getLocationValidationError(),
                    ),

                    const SizedBox(height: Gaps.lg),

                    // Continue button - inside scroll
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('continue_button'),
                        onPressed: _handleContinuePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid
                              ? BrandColors.planning
                              : BrandColors.bg3,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // User not authenticated, show empty history
      EventHistoryBottomSheet.show(
        context: context,
        events: const [],
        onEventSelected: _loadEventFromHistory,
      );
      return;
    }

    // Fetch event history
    try {
      final historyList = await ref.read(eventHistoryProvider(userId).future);

      // Convert EventHistory to EventHistoryItem
      final items = historyList.map((history) {
        // Extract TimeOfDay from DateTime
        final timeOfDay = TimeOfDay(
          hour: history.startDateTime.hour,
          minute: history.startDateTime.minute,
        );

        return EventHistoryItem(
          id: history.id,
          name: history.name,
          emoji: history.emoji,
          lastDate: history.startDateTime,
          lastTime: timeOfDay,
          location: history.locationName,
          groupId: history.groupId,
          groupName: history.groupName,
        );
      }).toList();

      if (mounted) {
        EventHistoryBottomSheet.show(
          context: context,
          events: items,
          onEventSelected: _loadEventFromHistory,
        );
      }
    } catch (e) {
      // On error, show empty history
      if (mounted) {
        EventHistoryBottomSheet.show(
          context: context,
          events: const [],
          onEventSelected: _loadEventFromHistory,
        );
      }
    }
  }

  void _showConfirmDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
        onEventCreated: _onEventCreated,
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
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final groupsAsync = ref.watch(groupsProvider);

          return groupsAsync.when(
            data: (groups) {
              // Convert Group entities to GroupInfo with image URLs
              return FutureBuilder<List<GroupInfo>>(
                  future: _loadGroupInfosWithImages(groups, ref),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 400,
                        decoration: const BoxDecoration(
                          color: BrandColors.bg1,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: BrandColors.planning),
                        ),
                      );
                    }

                    final groupInfos = snapshot.data ?? [];

                    return GroupSelectionBottomSheet(
                      groups: groupInfos,
                      onGroupSelected: (group) {
                        setState(() {
                          _selectedGroup = group;
                          // Clear error if group is now selected
                          if (_showValidationErrors) {
                            _groupError = null;
                          }
                        });
                      },
                      onCreateGroup: _createNewGroup,
                    );
                  });
            },
            loading: () => Container(
              height: 400,
              decoration: const BoxDecoration(
                color: BrandColors.bg1,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: BrandColors.planning),
              ),
            ),
            error: (error, stackTrace) => Container(
              height: 400,
              decoration: const BoxDecoration(
                color: BrandColors.bg1,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: BrandColors.cantVote),
                    const SizedBox(height: 16),
                    Text('Error loading groups',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: BrandColors.cantVote)),
                    const SizedBox(height: 8),
                    Text(error.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: BrandColors.text2),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _loadEventFromHistory(EventHistoryItem event) async {
    setState(() {
      _eventName = event.name;
      _eventEmoji = event.emoji;

      // Carregar data e hora: mesmo dia da semana, próxima ocorrência
      if (event.lastDate != null && event.lastTime != null) {
        final now = DateTime.now();
        final lastWeekday = event.lastDate!.weekday;
        var nextDate = now;

        // Encontrar próxima ocorrência do mesmo dia da semana
        while (nextDate.weekday != lastWeekday) {
          nextDate = nextDate.add(const Duration(days: 1));
        }

        // Se for hoje e já passou a hora, usar próxima semana
        if (nextDate.day == now.day &&
            TimeOfDay.now().hour >= event.lastTime!.hour) {
          nextDate = nextDate.add(const Duration(days: 7));
        }

        _selectedDate = nextDate;
        _selectedTime = event.lastTime;
        _endDate = nextDate; // End date igual ao start date
        _endTime = event.lastTime; // End time igual ao start time
        _dateTimeState = DateTimeState.setNow;
      }

      // Carregar localização se existir
      if (event.location != null && event.location!.isNotEmpty) {
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

    // Tentar pré-selecionar o grupo se existir
    if (event.groupId != null) {
      try {
        final groupsAsync = ref.read(groupsProvider);
        await groupsAsync.when(
          data: (groups) async {
            // Find matching group by ID
            final matchingGroup =
                groups.where((g) => g.id == event.groupId).firstOrNull;
            if (matchingGroup != null) {
              // Load group image URL
              final imageUrl = await ref.read(
                groupCoverUrlProvider(
                        (matchingGroup.photoPath, matchingGroup.photoUpdatedAt))
                    .future,
              );

              if (mounted) {
                setState(() {
                  _selectedGroup = GroupInfo(
                    id: matchingGroup.id,
                    name: matchingGroup.name,
                    imageUrl: imageUrl,
                    memberCount: matchingGroup.memberCount,
                  );
                  // Clear group error if validation is showing
                  if (_showValidationErrors) {
                    _groupError = null;
                  }
                });
              }
            }
          },
          loading: () {},
          error: (_, __) {},
        );
      } catch (e) {
        // Silently fail if group not found - user can select manually
      }
    }
  }

  void _createNewGroup() async {
    // Save current draft before navigating
    await _saveDraft();
    // Check mounted before using context after await
    if (!mounted) return;
    // Navigate to create group page and wait for result
    final result = await Navigator.of(context).pushNamed(
      AppRouter.createGroup,
      arguments: {'fromCreateEvent': true},
    );
    // Check mounted again after await
    if (!mounted) return;
    // Check if a group was created and returned
    if (result != null && result is Map<String, dynamic>) {
      final groupId = result['groupId'] as String?;
      final groupName = result['groupName'] as String?;
      final memberCount = result['memberCount'] as int?;
      if (groupId != null && groupName != null) {
        setState(() {
          _selectedGroup = GroupInfo(
            id: groupId,
            name: groupName,
            memberCount: memberCount ?? 1,
            imageUrl: result['imageUrl'] as String?,
          );
          // Clear error if group is now selected
          if (_showValidationErrors) {
            _groupError = null;
          }
        });
        // Show success message
        TopBanner.showSuccess(
          context,
          message: 'Group "$groupName" created!',
        );
      }
    }
  }

  void _onEventCreated(String eventId) async {
    // Clear draft since event is being created
    await _draftService.clearDraft();

    // Small delay to ensure RSVP is inserted in DB before navigation
    // The repository creates the RSVP asynchronously, so we wait a bit
    await Future.delayed(const Duration(milliseconds: 300));

    // Invalidate user RSVP provider to ensure fresh data load
    // This guarantees the creator's automatic "Yes" vote is shown
    ref.invalidate(userRsvpProvider(eventId));

    // Also invalidate event RSVPs provider for vote counts
    ref.invalidate(eventRsvpsProvider(eventId));

    // Also invalidate event detail provider to refresh counts
    ref.invalidate(eventDetailProvider(eventId));

    // Invalidate Home providers to show new event immediately
    ref.invalidate(nextEventControllerProvider);
    ref.invalidate(confirmedEventsControllerProvider);
    ref.invalidate(homeEventsControllerProvider);
    ref.invalidate(todosControllerProvider);

    // Navigate to event detail page with the created event ID
    // Use pushReplacementNamed to replace CreateEvent with Event page
    // This way, back button from Event goes to Home (which is still in the stack)
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (Route<dynamic> route) => false,
        arguments: {
          'eventId': eventId,
          'showSuccessBanner': true,
          'eventName': _eventName.isEmpty ? 'Untitled Event' : _eventName,
          'groupName': _selectedGroup?.name ?? 'No Group',
        },
      );
    }
  }
}
