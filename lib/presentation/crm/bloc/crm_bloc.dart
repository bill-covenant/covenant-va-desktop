import 'package:flutter_bloc/flutter_bloc.dart';
import 'crm_event.dart';
import 'crm_state.dart';
import '../../../data/repositories/crm_repository.dart';
import '../../../data/models/crm_customer_model.dart';

class CrmBloc extends Bloc<CrmEvent, CrmState> {
  final CrmRepository _crmRepository;
  List<CrmCustomerModel> _customers = [];

  CrmBloc({required CrmRepository crmRepository})
      : _crmRepository = crmRepository,
        super(const CrmInitial()) {
    on<CrmLoadRequested>(_onLoad);
    on<CrmCustomerCreateRequested>(_onCreate);
    on<CrmCustomerUpdateRequested>(_onUpdate);
    on<CrmCustomerDeleteRequested>(_onDelete);
    on<CrmNotifyBranchRequested>(_onNotify);
  }

  void _emitLoaded(Emitter<CrmState> emit, {String? message}) {
    emit(CrmLoaded(customers: List.from(_customers), actionMessage: message));
  }

  Future<void> _onLoad(CrmLoadRequested event, Emitter<CrmState> emit) async {
    if (_customers.isEmpty) emit(const CrmLoading());
    try {
      _customers = await _crmRepository.getCustomers();
      _emitLoaded(emit);
    } catch (e) {
      emit(CrmError(e.toString()));
    }
  }

  Future<void> _onCreate(CrmCustomerCreateRequested event, Emitter<CrmState> emit) async {
    try {
      final customer = await _crmRepository.createCustomer(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
        company: event.company,
        branchName: event.branchName,
        branchEmail: event.branchEmail,
        orderDetails: event.orderDetails,
        notes: event.notes,
      );
      _customers.insert(0, customer);
      _emitLoaded(emit, message: 'Customer added');
    } catch (e) {
      emit(CrmError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onUpdate(CrmCustomerUpdateRequested event, Emitter<CrmState> emit) async {
    try {
      final updated = await _crmRepository.updateCustomer(event.id, event.data);
      final idx = _customers.indexWhere((c) => c.id == event.id);
      if (idx != -1) _customers[idx] = updated;
      _emitLoaded(emit, message: 'Customer updated');
    } catch (e) {
      emit(CrmError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onDelete(CrmCustomerDeleteRequested event, Emitter<CrmState> emit) async {
    final removed = _customers.firstWhere((c) => c.id == event.id, orElse: () => _customers.first);
    _customers.removeWhere((c) => c.id == event.id);
    _emitLoaded(emit);
    try {
      await _crmRepository.deleteCustomer(event.id);
    } catch (e) {
      _customers.add(removed);
      emit(CrmError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onNotify(CrmNotifyBranchRequested event, Emitter<CrmState> emit) async {
    if (state is CrmLoaded) {
      emit((state as CrmLoaded).copyWith(isNotifying: true, notifyingCustomerId: event.customerId));
    }
    try {
      final message = await _crmRepository.notifyBranch(event.customerId);
      _customers = await _crmRepository.getCustomers();
      _emitLoaded(emit, message: message);
    } catch (e) {
      _emitLoaded(emit);
      emit(CrmError(e.toString()));
      _emitLoaded(emit);
    }
  }
}
