import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/components/nav/create_event_app_bar.dart';
import '../../../../shared/components/forms/event_group_selector.dart';
import '../../../../shared/components/sections/date_time_section.dart';
import '../../../../shared/components/sections/location_section.dart';
import '../../../../shared/components/dialogs/event_history_dialog.dart';
import '../../../../shared/components/dialogs/group_selection_dialog.dart';
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
  String _eventName = 'Create Event';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CreateEventAppBar(
        title: _eventName,
        isEditable: true,
        onTitleChanged: (title) {
          setState(() {
            _eventName = title;
          });
        },
        onHistoryPressed: _showEventHistory,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Insets.screenH),
        child: Column(
          children: [
            SizedBox(height: Gaps.lg),

            // Seleção de grupo e nome do evento
            EventGroupSelector(
              eventEmoji: _eventEmoji,
              eventName: _eventName.isEmpty ? 'Event Name' : _eventName,
              selectedGroup: _selectedGroup,
              onGroupPressed: _showGroupSelection,
              onEventNameChanged: (name) {
                setState(() {
                  _eventName = name;
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
            ),

            SizedBox(height: Gaps.xl),

            // Espaço extra para scroll
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showEventHistory() {
    showDialog(
      context: context,
      builder: (context) => EventHistoryDialog(
        events: _getMockEventHistory(),
        onEventSelected: _loadEventFromHistory,
      ),
    );
  }

  void _showGroupSelection() {
    showDialog(
      context: context,
      builder: (context) => GroupSelectionDialog(
        groups: _getMockGroups(),
        onGroupSelected: (group) {
          setState(() {
            _selectedGroup = group;
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
