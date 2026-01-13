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

class HoursLoggedSuccess extends TimecardState {
  final TimeEntry entry;

  const HoursLoggedSuccess({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class TimeEntryDeleted extends TimecardState {
  const TimeEntryDeleted();
}