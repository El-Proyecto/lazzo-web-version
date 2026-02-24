import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../data_sources/calendar_remote_data_source.dart';

/// Real implementation of CalendarRepository
/// Uses Supabase via CalendarRemoteDataSource
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _dataSource;
  final String _userId;

  CalendarRepositoryImpl(this._dataSource, this._userId);

  @override
  Future<List<CalendarEventEntity>> getEventsForMonth(
      int year, int month) async {
    return _dataSource.fetchEventsForMonth(_userId, year, month);
  }

  @override
  Future<List<CalendarEventEntity>> getAllUpcomingEvents() async {
    return _dataSource.fetchAllUpcomingEvents(_userId);
  }
}
