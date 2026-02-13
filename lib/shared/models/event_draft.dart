import 'package:flutter/material.dart';
import '../../features/create_event/presentation/widgets/location_section.dart';

/// Model para rascunho de evento
/// Usado para salvar e carregar estados parciais de criação de eventos
class EventDraft {
  final String eventName;
  final String? eventEmoji;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final LocationInfo? selectedLocation;
  final DateTime createdAt;

  const EventDraft({
    required this.eventName,
    this.eventEmoji,
    this.selectedDate,
    this.selectedTime,
    this.endDate,
    this.endTime,
    this.selectedLocation,
    required this.createdAt,
  });

  /// Verifica se o rascunho tem alterações
  bool get hasChanges {
    return eventName.isNotEmpty ||
        eventEmoji != null ||
        selectedDate != null ||
        selectedTime != null ||
        selectedLocation != null;
  }

  /// Verifica se o rascunho é válido para criação
  bool get isValid {
    // Nome é obrigatório
    if (eventName.trim().isEmpty) return false;

    // Date/time optional but if partially set, both needed
    if ((selectedDate != null) != (selectedTime != null)) return false;

    // Se tem data/hora de fim, validar que fim > início
    if (selectedDate != null &&
        selectedTime != null &&
        endDate != null &&
        endTime != null) {
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

    return true;
  }

  /// Converte para Map para serialização
  Map<String, dynamic> toJson() {
    return {
      'eventName': eventName,
      'eventEmoji': eventEmoji,
      'selectedDate': selectedDate?.millisecondsSinceEpoch,
      'selectedTime': selectedTime != null
          ? {'hour': selectedTime!.hour, 'minute': selectedTime!.minute}
          : null,
      'endDate': endDate?.millisecondsSinceEpoch,
      'endTime': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'selectedLocation': selectedLocation?.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Cria instância a partir de Map
  factory EventDraft.fromJson(Map<String, dynamic> json) {
    return EventDraft(
      eventName: json['eventName'] ?? '',
      eventEmoji: json['eventEmoji'] ?? '🍖',
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  /// Cria cópia com alterações
  EventDraft copyWith({
    String? eventName,
    String? eventEmoji,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    LocationInfo? selectedLocation,
  }) {
    return EventDraft(
      eventName: eventName ?? this.eventName,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      createdAt: createdAt,
    );
  }
}
