import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notes_event.dart';
import 'notes_state.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/models/note_model.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository _noteRepository;
  
  List<NoteModel> _cachedNotes = [];
  // True once a notes list has been emitted, so a later failed refresh keeps it
  // on screen (with a snackbar) instead of replacing it with the error view.
  bool _hasLoaded = false;
  int _errorSeq = 0;

  NotesBloc({required NoteRepository noteRepository})
      : _noteRepository = noteRepository,
        super(const NotesInitial()) {
    on<NotesLoadRequested>(_onLoadRequested);
    on<NoteCreateRequested>(_onNoteCreate);
    on<NoteUpdateRequested>(_onNoteUpdate);
    on<NotePinToggled>(_onPinToggle);
    on<NoteDeleteRequested>(_onNoteDelete);
  }

  void _emitLoaded(Emitter<NotesState> emit, {String? error}) {
    _hasLoaded = true;
    // Always emit a new list copy so Equatable detects the change
    emit(NotesLoaded(
      notes: List<NoteModel>.from(_cachedNotes),
      errorMessage: error,
      errorId: error != null ? ++_errorSeq : 0,
    ));
  }

  Future<void> _onLoadRequested(NotesLoadRequested event, Emitter<NotesState> emit) async {
    if (_cachedNotes.isEmpty) {
      emit(const NotesLoading());
    }
    try {
      debugPrint('📝 NotesBloc: Fetching notes...');
      _cachedNotes = await _noteRepository.getNotes();
      debugPrint('📝 NotesBloc: Got ${_cachedNotes.length} notes');
      _emitLoaded(emit);
    } catch (e) {
      debugPrint('❌ NotesBloc: Error loading notes: $e');
      if (_hasLoaded || _cachedNotes.isNotEmpty) {
        // Keep the notes we already have on screen; surface the error as a snackbar.
        _emitLoaded(emit, error: 'Couldn\'t refresh notes: ${e.toString().replaceFirst('Exception: ', '')}');
      } else {
        emit(NotesError(e.toString()));
      }
    }
  }

  Future<void> _onNoteCreate(NoteCreateRequested event, Emitter<NotesState> emit) async {
    // Optimistic: add instantly with temp ID
    final optimisticNote = NoteModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      content: event.content,
      isPinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _cachedNotes.insert(0, optimisticNote);
    _emitLoaded(emit);

    // Background: create on server and replace temp note
    try {
      debugPrint('📝 NotesBloc: Creating note on server...');
      final note = await _noteRepository.createNote(
        title: event.title,
        content: event.content,
      );
      debugPrint('📝 NotesBloc: Note created with id: ${note.id}');
      final idx = _cachedNotes.indexWhere((n) => n.id == optimisticNote.id);
      if (idx != -1) _cachedNotes[idx] = note;
      _emitLoaded(emit);
    } catch (e) {
      debugPrint('❌ NotesBloc: Error creating note: $e');
      _cachedNotes.removeWhere((n) => n.id == optimisticNote.id);
      _emitLoaded(emit, error: e.toString());
    }
  }

  Future<void> _onNoteUpdate(NoteUpdateRequested event, Emitter<NotesState> emit) async {
    if (_cachedNotes.isEmpty) return;
    
    final idx = _cachedNotes.indexWhere((n) => n.id == event.noteId);
    if (idx == -1) return;
    
    // Optimistic update
    final old = _cachedNotes[idx];
    _cachedNotes[idx] = old.copyWith(
      title: event.title,
      content: event.content,
    );
    _emitLoaded(emit);

    try {
      final updated = await _noteRepository.updateNote(
        event.noteId,
        title: event.title,
        content: event.content,
      );
      final currentIdx = _cachedNotes.indexWhere((n) => n.id == event.noteId);
      if (currentIdx != -1) _cachedNotes[currentIdx] = updated;
      _emitLoaded(emit);
    } catch (e) {
      final restoreIdx = _cachedNotes.indexWhere((n) => n.id == event.noteId);
      if (restoreIdx != -1) _cachedNotes[restoreIdx] = old;
      _emitLoaded(emit, error: e.toString());
    }
  }

  Future<void> _onPinToggle(NotePinToggled event, Emitter<NotesState> emit) async {
    final idx = _cachedNotes.indexWhere((n) => n.id == event.noteId);
    if (idx == -1) return;

    final old = _cachedNotes[idx];
    _cachedNotes[idx] = old.copyWith(isPinned: !old.isPinned);
    // Re-sort: pinned first, then by updatedAt
    _cachedNotes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    _emitLoaded(emit);

    try {
      await _noteRepository.togglePin(event.noteId);
    } catch (e) {
      _cachedNotes[_cachedNotes.indexWhere((n) => n.id == event.noteId)] = old;
      _emitLoaded(emit);
    }
  }

  Future<void> _onNoteDelete(NoteDeleteRequested event, Emitter<NotesState> emit) async {
    final deleted = _cachedNotes.firstWhere((n) => n.id == event.noteId);
    _cachedNotes.removeWhere((n) => n.id == event.noteId);
    _emitLoaded(emit);

    try {
      await _noteRepository.deleteNote(event.noteId);
    } catch (e) {
      _cachedNotes.add(deleted);
      _emitLoaded(emit);
    }
  }
}