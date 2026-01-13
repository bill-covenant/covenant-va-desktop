// lib/presentation/timecard/bloc/timecard_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/timecard_repository.dart';
import 'timecard_event.dart';
import 'timecard_state.dart';

class TimecardBloc extends Bloc<TimecardEvent, TimecardState> {
  final TimecardRepository timecardRepository;

  TimecardBloc({required this.timecardRepository}) 
      : super(const TimecardInitial()) {  // ← Added const
    on<LoadTimecardData>(_onLoadTimecardData);
    on<LogHours>(_onLogHours);
    on<DeleteTimeEntry>(_onDeleteTimeEntry);
    on<RefreshTimecard>(_onRefreshTimecard);
  }

  Future<void> _onLoadTimecardData(
    LoadTimecardData event,
    Emitter<TimecardState> emit,
  ) async {
    emit(const TimecardLoading());  // ← Added const
    
    try {
      // Load time entries
      final entries = await timecardRepository.getTimeEntries(
        clientId: event.clientId,
        month: event.month,
      );

      // Load monthly summary
      final summary = await timecardRepository.getMonthlySummary(
        month: event.month,
        clientId: event.clientId,
      );

      emit(TimecardLoaded(
        timeEntries: entries,
        summary: summary,
      ));
    } catch (e) {
      emit(TimecardError(message: 'Failed to load timecard data: ${e.toString()}'));  // ← Added message:
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

      emit(HoursLoggedSuccess(entry: entry));  // ← Added entry:
      
      // Reload data after logging hours
      final currentMonth = '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}';
      add(LoadTimecardData(
        clientId: event.clientId,
        month: currentMonth,
      ));
    } catch (e) {
      emit(TimecardError(message: 'Failed to log hours: ${e.toString()}'));  // ← Added message:
    }
  }

  Future<void> _onDeleteTimeEntry(
    DeleteTimeEntry event,
    Emitter<TimecardState> emit,
  ) async {
    try {
      await timecardRepository.deleteTimeEntry(event.entryId);
      emit(const TimeEntryDeleted());  // ← Added const
    } catch (e) {
      emit(TimecardError(message: 'Failed to delete entry: ${e.toString()}'));  // ← Added message:
    }
  }

  Future<void> _onRefreshTimecard(
    RefreshTimecard event,
    Emitter<TimecardState> emit,
  ) async {
    // Same as load, but without showing loading state
    try {
      final entries = await timecardRepository.getTimeEntries(
        clientId: event.clientId,
        month: event.month,
      );

      final summary = await timecardRepository.getMonthlySummary(
        month: event.month,
        clientId: event.clientId,
      );

      emit(TimecardLoaded(
        timeEntries: entries,
        summary: summary,
      ));
    } catch (e) {
      emit(TimecardError(message: 'Failed to refresh timecard: ${e.toString()}'));  // ← Added message:
    }
  }
}