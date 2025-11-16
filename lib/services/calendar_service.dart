import 'package:add_2_calendar/add_2_calendar.dart';

/// Service to add events to device calendar
/// Supports both Android and iOS
class CalendarService {
  /// Add event to device calendar
  /// Returns true if successful, false otherwise
  static Future<bool> addEventToCalendar({
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? location,
  }) async {
    try {
      final Event event = Event(
        title: title,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate ?? startDate.add(const Duration(hours: 2)),
        // Android specific settings
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
        // iOS specific settings
        iosParams: const IOSParams(
          reminder: Duration(minutes: 30),
        ),
      );

      final result = await Add2Calendar.addEvent2Cal(event);
      return result;
    } catch (e) {
      // Log error but don't crash the app
      print('❌ Error adding event to calendar: $e');
      return false;
    }
  }
}
