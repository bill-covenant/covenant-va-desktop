import 'package:equatable/equatable.dart';

abstract class CrmEvent extends Equatable {
  const CrmEvent();
  @override
  List<Object?> get props => [];
}

class CrmLoadRequested extends CrmEvent {
  const CrmLoadRequested();
}

class CrmCustomerCreateRequested extends CrmEvent {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? branchId;
  final String? orderDetails;
  final String? notes;

  const CrmCustomerCreateRequested({
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.branchId,
    this.orderDetails,
    this.notes,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phone, company, branchId, orderDetails, notes];
}

class CrmCustomerUpdateRequested extends CrmEvent {
  final String id;
  final Map<String, dynamic> data;

  const CrmCustomerUpdateRequested({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class CrmCustomerDeleteRequested extends CrmEvent {
  final String id;
  const CrmCustomerDeleteRequested({required this.id});
  @override
  List<Object?> get props => [id];
}

class CrmNotifyBranchRequested extends CrmEvent {
  final String customerId;
  const CrmNotifyBranchRequested({required this.customerId});
  @override
  List<Object?> get props => [customerId];
}
