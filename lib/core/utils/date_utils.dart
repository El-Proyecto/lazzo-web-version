/// Helpers for serializing [DateTime] values to Postgres `timestamptz` (Supabase).
///
/// Dart's [DateTime.toIso8601String] omits `Z` / offset for **local** values
/// (e.g. `2026-04-06T20:30:00.000`). PostgREST then treats that string as UTC,
/// shifting the stored instant by the device's UTC offset (e.g. +1h in Lisbon
/// summer). Always send an unambiguous UTC instant with [toSupabaseIso8601String].
extension DateTimeSupabaseIso on DateTime {
  String toSupabaseIso8601String() => toUtc().toIso8601String();
}

String? dateTimeToSupabaseIso8601String(DateTime? value) =>
    value?.toSupabaseIso8601String();
