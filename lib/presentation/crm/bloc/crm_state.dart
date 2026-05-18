import 'package:equatable/equatable.dart';
import '../../../data/models/crm_customer_model.dart';
import '../../../data/models/crm_branch_model.dart';

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
  final List<CrmBranchModel> branches;
  final String? actionMessage;
  final bool isNotifying;
  final String? notifyingCustomerId;

  const CrmLoaded({
    required this.customers,
    required this.branches,
    this.actionMessage,
    this.isNotifying = false,
    this.notifyingCustomerId,
  });

  CrmLoaded copyWith({
    List<CrmCustomerModel>? customers,
    List<CrmBranchModel>? branches,
    String? actionMessage,
    bool? isNotifying,
    String? notifyingCustomerId,
  }) {
    return CrmLoaded(
      customers: customers ?? this.customers,
      branches: branches ?? this.branches,
      actionMessage: actionMessage,
      isNotifying: isNotifying ?? this.isNotifying,
      notifyingCustomerId: notifyingCustomerId ?? this.notifyingCustomerId,
    );
  }

  @override
  List<Object?> get props => [customers, branches, actionMessage, isNotifying, notifyingCustomerId];
}

class CrmError extends CrmState {
  final String message;
  const CrmError(this.message);
  @override
  List<Object?> get props => [message];
}
