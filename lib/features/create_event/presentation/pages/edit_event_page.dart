import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../widgets/event_group_selector.dart';
import '../widgets/date_time_section.dart';
import '../widgets/location_section_p1.dart'; // Use P1 version without Google Maps
import '../widgets/create_event_app_bar.dart'; // Import CreateEventAppBar
// import '../../../../shared/models/event_draft.dart'; // Commented for P1 - conflicts with Google Maps
// import '../../../../services/draft_service.dart'; // Commented for P1
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/event.dart';

/// Página para edição de eventos existentes
/// Reutiliza todos os widgets tokenizados da criação de eventos
class EditEventPage extends StatefulWidget {
  final Event event;

  const EditEventPage({super.key, required this.event});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
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
  bool _hasUnsavedChanges = false;

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

    // TODO: Load group from groupId - for now using mock data
    _selectedGroup = _getMockGroups()
        .where((group) => group.id == event.groupId)
        .firstOrNull;

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

  /// Salva rascunho e marca mudanças (Commented for P1)
  Future<void> _saveDraftAndMarkChanged() async {
    // Commented for P1 - no draft functionality
    // final draft = _createCurrentDraft();
    // await _draftService.saveDraft(drift);
    _markUnsavedChanges();
  }

  /// Marca que há mudanças não salvas
  void _markUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

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
    return _eventName.trim().isNotEmpty &&
        _selectedGroup != null &&
        (_dateTimeState == DateTimeState.decideLater ||
            (_selectedDate != null && _selectedTime != null)) &&
        (_locationState == LocationState.decideLater ||
            _selectedLocation != null);
  }

  /// Lida com a tentativa de salvar o evento
  void _handleSaveEvent() {
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
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: Text(
          'Atualizar Evento',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
        content: Text(
          'Tem certeza que deseja salvar as alterações?',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppText.labelLarge.copyWith(color: BrandColors.text2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateEvent();
            },
            child: Text(
              'Salvar Alterações',
              style: AppText.labelLarge.copyWith(color: BrandColors.planning),
            ),
          ),
        ],
      ),
    );
  }

  /// Atualiza o evento
  void _updateEvent() {
    // TODO: Implement update event use case call
    print('Updating event: ${widget.event.id}');
    print('Name: $_eventName');
    print('Emoji: $_eventEmoji');
    print('Group: ${_selectedGroup?.name}');
    print('Date/Time State: $_dateTimeState');
    print('Location State: $_locationState');

    // Clear draft after successful update (Commented for P1)
    // _draftService.clearDraft();

    // Navigate back
    Navigator.of(context).pop();
  }

  /// Mostra dialog de confirmação de exclusão
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.bg2,
        title: Text(
          'Excluir Evento',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
        content: Text(
          'Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.',
          style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppText.labelLarge.copyWith(color: BrandColors.text2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent();
            },
            child: Text(
              'Excluir',
              style: AppText.labelLarge.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Exclui o evento
  void _deleteEvent() {
    // TODO: Implement delete event use case call
    print('Deleting event: ${widget.event.id}');

    // Navigate back
    Navigator.of(context).pop();
  }

  /// Lida com tentativa de sair da página
  Future<bool> _handleWillPop() async {
    if (_hasUnsavedChanges) {
      // TODO: Implement proper exit confirmation dialog
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: BrandColors.bg2,
          title: Text(
            'Descartar Alterações?',
            style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
          ),
          content: Text(
            'Você tem alterações não salvas. Deseja descartá-las?',
            style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: AppText.labelLarge.copyWith(color: BrandColors.text2),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Descartar',
                style: AppText.labelLarge.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        // await _draftService.clearDraft(); // Commented for P1
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _handleWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.bg1,
        appBar: CreateEventAppBar(
          title: 'Edit Event',
          onBackPressed: () => Navigator.of(context).pop(),
          trailingAction: GestureDetector(
            onTap: _showDeleteConfirmationDialog,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
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
                        _saveDraftAndMarkChanged();

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
                        _saveDraftAndMarkChanged();
                      },
                      onGroupPressed: null, // Disabled for edit mode
                      nameError: _showValidationErrors ? _nameError : null,
                      groupError: _showValidationErrors ? _groupError : null,
                    ),

                    const SizedBox(height: Gaps.xl),

                    // Seção de Data e Hora
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
                        _saveDraftAndMarkChanged();
                      },
                      onStartDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                        _saveDraftAndMarkChanged();
                      },
                      onStartTimeChanged: (time) {
                        setState(() {
                          _selectedTime = time;
                        });
                        _saveDraftAndMarkChanged();
                      },
                      onEndDateChanged: (date) {
                        setState(() {
                          _endDate = date;
                        });
                        _saveDraftAndMarkChanged();
                      },
                      onEndTimeChanged: (time) {
                        setState(() {
                          _endTime = time;
                        });
                        _saveDraftAndMarkChanged();
                      },
                    ),

                    const SizedBox(height: Gaps.xl),

                    // Seção de Localização
                    LocationSectionP1(
                      selectedLocation: _selectedLocation,
                      initialState: _locationState,
                      onStateChanged: (state) {
                        setState(() {
                          _locationState = state;
                          if (state == LocationState.decideLater) {
                            _selectedLocation = null;
                          }
                        });
                        _saveDraftAndMarkChanged();
                      },
                      onLocationChanged: (location) {
                        setState(() {
                          _selectedLocation = location;
                        });
                        _saveDraftAndMarkChanged();
                      },
                    ),

                    const SizedBox(height: Gaps.xl),
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
                  onPressed: _isFormValid() ? _handleSaveEvent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid()
                        ? BrandColors.planning
                        : BrandColors.bg3,
                    foregroundColor: _isFormValid()
                        ? Colors.white
                        : BrandColors.text2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Salvar Alterações',
                    style: AppText.labelLarge.copyWith(
                      color: _isFormValid() ? Colors.white : BrandColors.text2,
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
