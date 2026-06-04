import 'package:equatable/equatable.dart';
import '../../../data/models/lead_model.dart';

abstract class LeadTrackerState extends Equatable {
  const LeadTrackerState();
  @override
  List<Object?> get props => [];
}

class LeadTrackerInitial extends LeadTrackerState {
  const LeadTrackerInitial();
}

class LeadTrackerLoading extends LeadTrackerState {
  const LeadTrackerLoading();
}

class LeadTrackerLoaded extends LeadTrackerState {
  final List<LeadModel> leads;
  final String? actionMessage;

  const LeadTrackerLoaded({required this.leads, this.actionMessage});

  LeadTrackerLoaded copyWith({List<LeadModel>? leads, String? actionMessage}) {
    return LeadTrackerLoaded(
      leads: leads ?? this.leads,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [leads, actionMessage];
}

class LeadTrackerError extends LeadTrackerState {
  final String message;
  const LeadTrackerError(this.message);
  @override
  List<Object?> get props => [message];
}
