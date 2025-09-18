import 'package:flutter/material.dart';
import '../components/forms/event_group_selector.dart';
import '../components/sections/location_section.dart';
import '../components/sections/date_time_section.dart';

/// Model para rascunho de evento
/// Usado para salvar e carregar estados parciais de criação de eventos
class EventDraft {
  final String eventName;
  final String eventEmoji;
  final GroupInfo? selectedGroup;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final LocationInfo? selectedLocation;
  final DateTimeState dateTimeState;
  final LocationState locationState;
  final DateTime createdAt;

  const EventDraft({
    required this.eventName,
    required this.eventEmoji,
    this.selectedGroup,
    this.selectedDate,
    this.selectedTime,
    this.endDate,
    this.endTime,
    this.selectedLocation,
    required this.dateTimeState,
    required this.locationState,
    required this.createdAt,
  });

  /// Verifica se o rascunho tem alterações
  bool get hasChanges {
    return eventName.isNotEmpty ||
        eventEmoji != '🍖' || // Check if emoji changed from default
        selectedGroup != null ||
        selectedDate != null ||
        selectedTime != null ||
        selectedLocation != null ||
        dateTimeState != DateTimeState.decideLater ||
        locationState != LocationState.decideLater;
  }

  /// Verifica se o rascunho é válido para criação
  bool get isValid {
    // Nome é obrigatório
    if (eventName.trim().isEmpty) return false;

    // Grupo é obrigatório
    if (selectedGroup == null) return false;

    // Se location está em "Set now", precisa ter localização
    if (locationState == LocationState.setNow && selectedLocation == null) {
      return false;
    }

    // Se date/time está em "Set now", precisa ter data e hora de início
    if (dateTimeState == DateTimeState.setNow) {
      if (selectedDate == null || selectedTime == null) return false;

      // Se tem data/hora de fim, validar que fim > início
      if (endDate != null && endTime != null) {
        final startDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );
        final endDateTime = DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
          endTime!.hour,
          endTime!.minute,
        );
        if (!endDateTime.isAfter(startDateTime)) return false;
      }
    }

    return true;
  }

  /// Converte para Map para serialização
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'eventEmoji': eventEmoji,
      'selectedGroup': selectedGroup?.toJson(),
      'selectedDate': selectedDate?.millisecondsSinceEpoch,
      'selectedTime': selectedTime != null
          ? {'hour': selectedTime!.hour, 'minute': selectedTime!.minute}
          : null,
      'endDate': endDate?.millisecondsSinceEpoch,
      'endTime': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'selectedLocation': selectedLocation?.toJson(),
      'dateTimeState': dateTimeState.name,
      'locationState': locationState.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Cria instância a partir de Map
  factory EventDraft.fromJson(Map<String, dynamic> json) {
    return EventDraft(
      eventName: json['eventName'] ?? '',
      eventEmoji: json['eventEmoji'] ?? '🍖',
      selectedGroup: json['selectedGroup'] != null
          ? GroupInfo.fromJson(json['selectedGroup'])
          : null,
      selectedDate: json['selectedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['selectedDate'])
          : null,
      selectedTime: json['selectedTime'] != null
          ? TimeOfDay(
              hour: json['selectedTime']['hour'],
              minute: json['selectedTime']['minute'],
            )
          : null,
      endDate: json['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: json['endTime']['hour'],
              minute: json['endTime']['minute'],
            )
          : null,
      selectedLocation: json['selectedLocation'] != null
          ? LocationInfo.fromJson(json['selectedLocation'])
          : null,
      dateTimeState: DateTimeState.values.byName(
        json['dateTimeState'] ?? 'decideLater',
      ),
      locationState: LocationState.values.byName(
        json['locationState'] ?? 'decideLater',
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  /// Cria cópia com alterações
  EventDraft copyWith({
    String? eventName,
    String? eventEmoji,
    GroupInfo? selectedGroup,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    LocationInfo? selectedLocation,
    DateTimeState? dateTimeState,
    LocationState? locationState,
  }) {
    return EventDraft(
      eventName: eventName ?? this.eventName,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      dateTimeState: dateTimeState ?? this.dateTimeState,
      locationState: locationState ?? this.locationState,
      createdAt: createdAt,
    );
  }
}
