import 'package:equatable/equatable.dart';
import '../../../data/models/crm_customer_model.dart';

abstract class CrmState extends Equatable {
  const CrmState();
  @override
  List<Object?> get props => [];
}

class CrmInitial extends CrmState {
  const CrmInitial();
}

class CrmLoading extends CrmState {
  const CrmLoading();
}

class CrmLoaded extends CrmState {
  final List<CrmCustomerModel> customers;
  final String? actionMessage;
  final bool isNotifying;
  final String? notifyingCustomerId;

  const CrmLoaded({
    required this.customers,
    this.actionMessage,
    this.isNotifying = false,
    this.notifyingCustomerId,
  });

  CrmLoaded copyWith({
    List<CrmCustomerModel>? customers,
    String? actionMessage,
    bool? isNotifying,
    String? notifyingCustomerId,
  }) {
    return CrmLoaded(
      customers: customers ?? this.customers,
      actionMessage: actionMessage,
      isNotifying: isNotifying ?? this.isNotifying,
      notifyingCustomerId: notifyingCustomerId ?? this.notifyingCustomerId,
    );
  }

  @override
  List<Object?> get props => [customers, actionMessage, isNotifying, notifyingCustomerId];
}

class CrmError extends CrmState {
  final String message;
  const CrmError(this.message);
  @override
  List<Object?> get props => [message];
}
