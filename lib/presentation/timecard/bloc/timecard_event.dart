// lib/presentation/timecard/bloc/timecard_event.dart

import 'package:equatable/equatable.dart';

abstract class TimecardEvent extends Equatable {
  const TimecardEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimecardData extends TimecardEvent {
  final String clientId;
  final String month;

  const LoadTimecardData({
    required this.clientId,
    required this.month,
  });

  @override
  List<Object?> get props => [clientId, month];
}

class LogHours extends TimecardEvent {
  final String clientId;
  final DateTime date;
  final double hoursWorked;
  final String? description;

  const LogHours({
    required this.clientId,
    required this.date,
    required this.hoursWorked,
    this.description,
  });

  @override
  List<Object?> get props => [clientId, date, hoursWorked, description];
}

class DeleteTimeEntry extends TimecardEvent {
  final String entryId;

  const DeleteTimeEntry(this.entryId);

  @override
  List<Object?> get props => [entryId];
}

class RefreshTimecard extends TimecardEvent {
  final String clientId;
  final String month;

  const RefreshTimecard({
    required this.clientId,
    required this.month,
  });

  @override
  List<Object?> get props => [clientId, month];
}