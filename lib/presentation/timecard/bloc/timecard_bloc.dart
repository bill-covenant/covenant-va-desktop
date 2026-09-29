import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/timecard_repository.dart';
import 'timecard_event.dart';
import 'timecard_state.dart';

/// Parameters of the most recent load, i.e. what the screen is showing
/// (month vs pay period vs custom date range).
class _TimecardQuery {
  final String clientId;
  final String? month;
  final DateTime? startDate;
  final DateTime? endDate;

  const _TimecardQuery({
    required this.clientId,
    this.month,
    this.startDate,
    this.endDate,
  });
}

class TimecardBloc extends Bloc<TimecardEvent, TimecardState> {
  final TimecardRepository timecardRepository;

  _TimecardQuery? _lastQuery;
  // Incremented per load so a slower, older response (e.g. a Refresh that
  // raced a Load for a different period) can never overwrite newer data.
  int _loadSeq = 0;
  int _failureSeq = 0;

  TimecardBloc({required this.timecardRepository})
      : super(const TimecardInitial()) {
    // restartable: switching period/month cancels the in-flight load
    on<LoadTimecardData>(_onLoadTimecardData, transformer: restartable());
    on<LogHours>(_onLogHours);
    on<DeleteTimeEntry>(_onDeleteTimeEntry);
    on<RefreshTimecard>(_onRefreshTimecard, transformer: restartable());
  }

  static String _errorText(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  Future<void> _onLoadTimecardData(
    LoadTimecardData event,
    Emitter<TimecardState> emit,
  ) async {
    final query = _TimecardQuery(
      clientId: event.clientId,
      month: event.month,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    _lastQuery = query;
    final seq = ++_loadSeq;

    // Only show loading spinner if we don't have data yet
    if (state is! TimecardLoaded) {
      emit(const TimecardLoading());
    }

    try {
      // Fetch entries + summary in PARALLEL (was sequential before)
      final data = await timecardRepository.loadTimecardData(
        clientId: query.clientId,
        month: query.month,
        startDate: query.startDate,
        endDate: query.endDate,
      );
      if (seq != _loadSeq) return; // superseded

      emit(TimecardLoaded(
        timeEntries: data.entries,
        summary: data.summary,
      ));
    } catch (e) {
      if (seq != _loadSeq) return;
      emit(TimecardError(
          message: 'Failed to load timecard data: ${_errorText(e)}'));
    }
  }

  Future<void> _onLogHours(
    LogHours event,
    Emitter<TimecardState> emit,
  ) async {
    try {
      final entry = await timecardRepository.logHours(
        clientId: event.clientId,
        date: event.date,
        hoursWorked: event.hoursWorked,
        description: event.description,
      );

      emit(HoursLoggedSuccess(entry: entry));

      // Silent refresh of whatever the screen is currently showing
      _refreshCurrentView(fallbackClientId: event.clientId, fallbackDate: event.date);
    } catch (e) {
      // The screen rolls back its optimistic entry and keeps the pending shift.
      emit(LogHoursFailed(
        message: 'Failed to log hours: ${_errorText(e)}',
        attempt: ++_failureSeq,
      ));
    }
  }

  Future<void> _onDeleteTimeEntry(
    DeleteTimeEntry event,
    Emitter<TimecardState> emit,
  ) async {
    // Optimistic entries (not yet confirmed by the server) have no server id.
    if (event.entryId.startsWith('temp_')) {
      emit(DeleteEntryFailed(
        entryId: event.entryId,
        message: 'This entry is still being saved. Please try again in a moment.',
        attempt: ++_failureSeq,
      ));
      return;
    }

    // UI already removed the entry optimistically; confirm with the server.
    try {
      await timecardRepository.deleteTimeEntry(event.entryId);
      emit(TimeEntryDeleted(entryId: event.entryId));
      _refreshCurrentView();
    } catch (e) {
      emit(DeleteEntryFailed(
        entryId: event.entryId,
        message: 'Failed to delete entry: ${_errorText(e)}',
        attempt: ++_failureSeq,
      ));
    }
  }

  Future<void> _onRefreshTimecard(
    RefreshTimecard event,
    Emitter<TimecardState> emit,
  ) async {
    final query = _TimecardQuery(
      clientId: event.clientId,
      month: event.month,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    _lastQuery = query;
    final seq = ++_loadSeq;

    try {
      // Parallel fetch, no loading spinner
      final data = await timecardRepository.loadTimecardData(
        clientId: query.clientId,
        month: query.month,
        startDate: query.startDate,
        endDate: query.endDate,
      );
      if (seq != _loadSeq) return; // superseded

      emit(TimecardLoaded(
        timeEntries: data.entries,
        summary: data.summary,
      ));
    } catch (e) {
      if (seq != _loadSeq) return;
      emit(TimecardError(
          message: 'Failed to refresh timecard: ${_errorText(e)}'));
    }
  }

  void _refreshCurrentView({String? fallbackClientId, DateTime? fallbackDate}) {
    final q = _lastQuery;
    if (q != null) {
      add(RefreshTimecard(
        clientId: q.clientId,
        month: q.month,
        startDate: q.startDate,
        endDate: q.endDate,
      ));
    } else if (fallbackClientId != null && fallbackDate != null) {
      add(RefreshTimecard(
        clientId: fallbackClientId,
        month:
            '${fallbackDate.year}-${fallbackDate.month.toString().padLeft(2, '0')}',
      ));
    }
  }
}
