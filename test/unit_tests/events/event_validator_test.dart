// test/unit/event_validator_test.dart
import 'package:flutter_test/flutter_test.dart';

// ===== Modelo e Validador mínimos para o teste =====
class EventDraft {
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? maxAttendees; // opcional
  final double? price; // opcional
  final int photoCount; // anexadas no rascunho
  EventDraft({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.maxAttendees,
    this.price,
    this.photoCount = 0,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  const ValidationResult(this.isValid, this.errors);
}

class EventValidator {
  static const int titleMin = 3;
  static const int titleMax = 80;
  static const int maxPhotosPerEvent = 20;
  static const int maxAttendeesAbs = 100000; // limite de segurança

  ValidationResult validate(EventDraft d) {
    final errors = <String>[];

    final title = d.title.trim();
    if (title.length < titleMin)
      errors.add('Título demasiado curto (min $titleMin).');
    if (title.length > titleMax)
      errors.add('Título demasiado longo (max $titleMax).');

    if (!d.startsAt.isBefore(d.endsAt)) {
      errors.add('Data de início deve ser antes da data de fim.');
    }

    if (d.maxAttendees != null) {
      if (d.maxAttendees! <= 0) errors.add('Capacidade deve ser > 0.');
      if (d.maxAttendees! > maxAttendeesAbs) {
        errors.add('Capacidade excede limite ($maxAttendeesAbs).');
      }
    }

    if (d.price != null && d.price! < 0) {
      errors.add('Preço não pode ser negativo.');
    }

    if (d.photoCount > maxPhotosPerEvent) {
      errors.add('Excesso de fotos (máx $maxPhotosPerEvent por evento).');
    }

    return ValidationResult(errors.isEmpty, errors);
  }
}

void main() {
  final validator = EventValidator();
  final now = DateTime(2025, 1, 1, 20, 0);

  test('evento válido passa', () {
    final draft = EventDraft(
      title: 'Jantar Amigos',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 3)),
      maxAttendees: 10,
      price: 0,
      photoCount: 0,
    );
    final res = validator.validate(draft);
    expect(res.isValid, true);
    expect(res.errors, isEmpty);
  });

  test('título curto e longo geram erros específicos', () {
    final draftShort = EventDraft(
      title: 'oi',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
    );
    final draftLong = EventDraft(
      title: 'A' * 200,
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
    );

    final s = validator.validate(draftShort);
    final l = validator.validate(draftLong);

    expect(s.isValid, false);
    expect(s.errors, contains('Título demasiado curto (min 3).'));

    expect(l.isValid, false);
    expect(l.errors, contains('Título demasiado longo (max 80).'));
  });

  test('início >= fim falha', () {
    final draft = EventDraft(
      title: 'Test',
      startsAt: now,
      endsAt: now, // igual → inválido
    );
    final res = validator.validate(draft);
    expect(res.isValid, false);
    expect(
      res.errors,
      contains('Data de início deve ser antes da data de fim.'),
    );
  });

  test('capacidade <= 0 e > limite falham', () {
    final d1 = EventDraft(
      title: 'Cap test',
      startsAt: now,
      endsAt: now.add(const Duration(minutes: 30)),
      maxAttendees: 0,
    );
    final d2 = EventDraft(
      title: 'Cap test',
      startsAt: now,
      endsAt: now.add(const Duration(minutes: 30)),
      maxAttendees: EventValidator.maxAttendeesAbs + 1,
    );

    final r1 = validator.validate(d1);
    final r2 = validator.validate(d2);

    expect(r1.isValid, false);
    expect(r1.errors, contains('Capacidade deve ser > 0.'));

    expect(r2.isValid, false);
    expect(r2.errors, contains('Capacidade excede limite (100000).'));
  });

  test('preço negativo falha', () {
    final d = EventDraft(
      title: 'Pago',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
      price: -1,
    );
    final r = validator.validate(d);
    expect(r.isValid, false);
    expect(r.errors, contains('Preço não pode ser negativo.'));
  });

  test('excesso de fotos falha', () {
    final d = EventDraft(
      title: 'Fotos',
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
      photoCount: EventValidator.maxPhotosPerEvent + 1,
    );
    final r = validator.validate(d);
    expect(r.isValid, false);
    expect(r.errors, contains('Excesso de fotos (máx 20 por evento).'));
  });
}
