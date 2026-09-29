import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/lead_repository.dart';
import '../../../data/models/lead_model.dart';
import 'lead_tracker_event.dart';
import 'lead_tracker_state.dart';

class LeadTrackerBloc extends Bloc<LeadTrackerEvent, LeadTrackerState> {
  final LeadRepository _leadRepository;
  List<LeadModel> _leads = [];
  // True once a lead list (fresh or cached) has been shown, so failures can
  // keep it on screen instead of replacing it with the full error view.
  bool _hasData = false;

  LeadTrackerBloc({required LeadRepository leadRepository})
      : _leadRepository = leadRepository,
        super(_initialState(leadRepository)) {
    final initial = state;
    if (initial is LeadTrackerLoaded) {
      _leads = List.from(initial.leads);
      _hasData = true;
    }
    on<LeadTrackerLoadRequested>(_onLoad);
    on<LeadTrackerCreateRequested>(_onCreate);
    on<LeadTrackerUpdateRequested>(_onUpdate);
    on<LeadTrackerDeleteRequested>(_onDelete);
    on<LeadTrackerImportRequested>(_onImport);
  }

  /// Start from the repository's last known list (if any) so a revisit renders
  /// data on the very first frame instead of an empty body.
  static LeadTrackerState _initialState(LeadRepository repository) {
    final cached = repository.cachedLeads;
    return cached != null ? LeadTrackerLoaded(leads: cached) : const LeadTrackerInitial();
  }

  void _emitLoaded(Emitter<LeadTrackerState> emit, {String? message}) {
    _hasData = true;
    emit(LeadTrackerLoaded(leads: List.from(_leads), actionMessage: message));
  }

  /// Emits [message] (shown as a snackbar) and, when there is data to show,
  /// immediately restores the loaded view.
  void _emitError(Emitter<LeadTrackerState> emit, String message) {
    emit(LeadTrackerError(message));
    if (_hasData) _emitLoaded(emit);
  }

  Future<void> _onLoad(LeadTrackerLoadRequested event, Emitter<LeadTrackerState> emit) async {
    // Show the last known list instantly (this bloc is re-created per visit,
    // the repository cache survives), then refresh in the background.
    // The spinner only appears on the very first load.
    if (state is! LeadTrackerLoaded) {
      final cached = _leadRepository.cachedLeads;
      if (cached != null) {
        _leads = cached;
        _emitLoaded(emit);
      } else if (!_hasData) {
        emit(const LeadTrackerLoading());
      }
    }
    try {
      _leads = await _leadRepository.getLeads();
      _emitLoaded(emit);
    } catch (e) {
      _emitError(emit, 'Failed to load leads: $e');
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
      _emitError(emit, 'Failed to create lead: $e');
    }
  }

  Future<void> _onDelete(LeadTrackerDeleteRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      await _leadRepository.deleteLead(event.id);
      _leads = _leads.where((l) => l.id != event.id).toList();
      _emitLoaded(emit, message: 'Lead deleted');
    } catch (e) {
      _emitError(emit, 'Failed to delete lead: $e');
    }
  }

  Future<void> _onImport(LeadTrackerImportRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      final count = await _leadRepository.importLeads(event.leads);
      _leads = await _leadRepository.getLeads();
      _emitLoaded(emit, message: 'Imported $count lead${count == 1 ? '' : 's'}');
    } catch (e) {
      _emitError(emit, 'Failed to import leads: $e');
    }
  }

  Future<void> _onUpdate(LeadTrackerUpdateRequested event, Emitter<LeadTrackerState> emit) async {
    try {
      final updated = await _leadRepository.updateLead(event.id, event.data);
      _leads = _leads.map((l) => l.id == event.id ? updated : l).toList();
      _emitLoaded(emit);
    } catch (e) {
      _emitError(emit, 'Failed to update lead: $e');
    }
  }
}
