import 'package:equatable/equatable.dart';
import '../../../data/models/time_entry.dart';

abstract class TimecardState extends Equatable {
  const TimecardState();

  @override
  List<Object?> get props => [];
}

class TimecardInitial extends TimecardState {
  const TimecardInitial();
}

class TimecardLoading extends TimecardState {
  const TimecardLoading();
}

class TimecardLoaded extends TimecardState {
  final List<TimeEntry> timeEntries;
  final MonthlySummary summary; // ← Changed from MonthlySummary? to MonthlySummary

  const TimecardLoaded({
    required this.timeEntries,
    required this.summary, // ← Now required and non-nullable
  });

  @override
  List<Object?> get props => [timeEntries, summary];
}

class TimecardError extends TimecardState {
  final String message;

  const TimecardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Saving an entry failed. The UI should roll back its optimistic entry and
/// keep any pending clock-in/clock-out so the shift isn't lost.
class LogHoursFailed extends TimecardError {
  // Distinguishes repeated failures with the same message (Equatable would
  // otherwise swallow the second emit and the UI would never roll back).
  final int attempt;

  const LogHoursFailed({required super.message, this.attempt = 0});

  @override
  List<Object?> get props => [message, attempt];
}

/// Deleting [entryId] failed. The UI should restore the entry it removed.
class DeleteEntryFailed extends TimecardError {
  final String entryId;
  final int attempt;

  const DeleteEntryFailed({required this.entryId, required super.message, this.attempt = 0});

  @override
  List<Object?> get props => [message, entryId, attempt];
}

class HoursLoggedSuccess extends TimecardState {
  final TimeEntry entry;

  const HoursLoggedSuccess({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class TimeEntryDeleted extends TimecardState {
  final String entryId;

  const TimeEntryDeleted({this.entryId = ''});

  @override
  List<Object?> get props => [entryId];
}