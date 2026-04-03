import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/timecard_repository.dart';
import 'timecard_event.dart';
import 'timecard_state.dart';

class TimecardBloc extends Bloc<TimecardEvent, TimecardState> {
  final TimecardRepository timecardRepository;

  TimecardBloc({required this.timecardRepository})
      : super(const TimecardInitial()) {
    on<LoadTimecardData>(_onLoadTimecardData);
    on<LogHours>(_onLogHours);
    on<DeleteTimeEntry>(_onDeleteTimeEntry);
    on<RefreshTimecard>(_onRefreshTimecard);
  }

  Future<void> _onLoadTimecardData(
    LoadTimecardData event,
    Emitter<TimecardState> emit,
  ) async {
    // Only show loading spinner if we don't have data yet
    if (state is! TimecardLoaded) {
      emit(const TimecardLoading());
    }

    try {
      // Fetch entries + summary in PARALLEL (was sequential before)
      final data = await timecardRepository.loadTimecardData(
        clientId: event.clientId,
        month: event.month,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(TimecardLoaded(
        timeEntries: data.entries,
        summary: data.summary,
      ));
    } catch (e) {
      emit(TimecardError(
          message: 'Failed to load timecard data: ${e.toString()}'));
    }
  }

  Future<void> _onLogHours(
    LogHours event,
    Emitter<TimecardState> emit,
  ) async {
    // Keep current data visible while logging
    final currentState = state;

    try {
      final entry = await timecardRepository.logHours(
        clientId: event.clientId,
        date: event.date,
        hoursWorked: event.hoursWorked,
        description: event.description,
      );

      emit(HoursLoggedSuccess(entry: entry));

      // Silent refresh — no loading spinner, data updates in background
      final currentMonth =
          '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}';
      add(RefreshTimecard(
        clientId: event.clientId,
        month: currentMonth,
      ));
    } catch (e) {
      // Restore previous state if we had data
      if (currentState is TimecardLoaded) {
        emit(currentState);
      }
      emit(TimecardError(
          message: 'Failed to log hours: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTimeEntry(
    DeleteTimeEntry event,
    Emitter<TimecardState> emit,
  ) async {
    // Emit success immediately — UI already updated optimistically
    emit(const TimeEntryDeleted());

    // Delete from server in background
    try {
      await timecardRepository.deleteTimeEntry(event.entryId);
    } catch (e) {
      emit(TimecardError(
          message: 'Failed to delete entry: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshTimecard(
    RefreshTimecard event,
    Emitter<TimecardState> emit,
  ) async {
    try {
      // Parallel fetch, no loading spinner
      final data = await timecardRepository.loadTimecardData(
        clientId: event.clientId,
        month: event.month,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(TimecardLoaded(
        timeEntries: data.entries,
        summary: data.summary,
      ));
    } catch (e) {
      emit(TimecardError(
          message: 'Failed to refresh timecard: ${e.toString()}'));
    }
  }
}