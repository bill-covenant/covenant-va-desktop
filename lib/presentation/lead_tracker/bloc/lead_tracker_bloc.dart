import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/lead_repository.dart';
import '../../../data/models/lead_model.dart';
import 'lead_tracker_event.dart';
import 'lead_tracker_state.dart';

class LeadTrackerBloc extends Bloc<LeadTrackerEvent, LeadTrackerState> {
  final LeadRepository _leadRepository;
  List<LeadModel> _leads = [];

  LeadTrackerBloc({required LeadRepository leadRepository})
      : _leadRepository = leadRepository,
        super(const LeadTrackerInitial()) {
    on<LeadTrackerLoadRequested>(_onLoad);
    on<LeadTrackerCreateRequested>(_onCreate);
    on<LeadTrackerUpdateRequested>(_onUpdate);
    on<LeadTrackerDeleteRequested>(_onDelete);
    on<LeadTrackerImportRequested>(_onImport);
  }

  void _emitLoaded(Emitter<LeadTrackerState> emit, {String? message}) {
    emit(LeadTrackerLoaded(leads: List.from(_leads), actionMessage: message));
  }

  Future<void> _onLoad(LeadTrackerLoadRequested event, Emitter<LeadTrackerState> emit) async {
    emit(const LeadTrackerLoading());
    try {
      _leads = await _leadRepository.getLeads();
      _emitLoaded(emit);
    } catch (e) {
      emit(LeadTrackerError('Failed to load leads: $e'));
    }
  }

  Future<void> _onCreate(LeadTrackerCreateRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      final lead = await _leadRepository.createLead(
        name: event.name,
        company: event.company,
        industry: event.industry,
        department: event.department,
        phone: event.phone,
        email: event.email,
        status: event.status,
      );
      _leads.add(lead);
      _emitLoaded(emit, message: 'Lead added');
    } catch (e) {
      emit(LeadTrackerError('Failed to create lead: $e'));
    }
  }

  Future<void> _onDelete(LeadTrackerDeleteRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      await _leadRepository.deleteLead(event.id);
      _leads = _leads.where((l) => l.id != event.id).toList();
      _emitLoaded(emit, message: 'Lead deleted');
    } catch (e) {
      emit(LeadTrackerError('Failed to delete lead: $e'));
    }
  }

  Future<void> _onImport(LeadTrackerImportRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      final count = await _leadRepository.importLeads(event.leads);
      _leads = await _leadRepository.getLeads();
      _emitLoaded(emit, message: 'Imported $count lead${count == 1 ? '' : 's'}');
    } catch (e) {
      emit(LeadTrackerError('Failed to import leads: $e'));
    }
  }

  Future<void> _onUpdate(LeadTrackerUpdateRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      final updated = await _leadRepository.updateLead(event.id, event.data);
      _leads = _leads.map((l) => l.id == event.id ? updated : l).toList();
      _emitLoaded(emit);
    } catch (e) {
      emit(LeadTrackerError('Failed to update lead: $e'));
    }
  }
}
