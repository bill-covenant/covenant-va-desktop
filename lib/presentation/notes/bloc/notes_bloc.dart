import 'package:flutter_bloc/flutter_bloc.dart';
import 'notes_event.dart';
import 'notes_state.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/models/note_model.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository _noteRepository;
  
  List<NoteModel> _cachedNotes = [];
  List<NoteCategory> _cachedCategories = [];
  String? _activeCategoryId;

  NotesBloc({required NoteRepository noteRepository})
      : _noteRepository = noteRepository,
        super(const NotesInitial()) {
    on<NotesLoadRequested>(_onLoadRequested);
    on<NotesCategoryFilterChanged>(_onCategoryFilterChanged);
    on<NoteCreateRequested>(_onNoteCreate);
    on<NoteUpdateRequested>(_onNoteUpdate);
    on<NotePinToggled>(_onPinToggle);
    on<NoteDeleteRequested>(_onNoteDelete);
    on<CategoryCreateRequested>(_onCategoryCreate);
    on<CategoryUpdateRequested>(_onCategoryUpdate);
    on<CategoryDeleteRequested>(_onCategoryDelete);
  }

  void _emitLoaded(Emitter<NotesState> emit) {
    emit(NotesLoaded(
      notes: _cachedNotes,
      categories: _cachedCategories,
      activeCategoryId: _activeCategoryId,
    ));
  }

  Future<void> _onLoadRequested(NotesLoadRequested event, Emitter<NotesState> emit) async {
    if (_cachedNotes.isEmpty && _cachedCategories.isEmpty) {
      emit(const NotesLoading());
    }
    try {
      final results = await Future.wait([
        _noteRepository.getNotes(categoryId: _activeCategoryId),
        _noteRepository.getCategories(),
      ]);
      _cachedNotes = results[0] as List<NoteModel>;
      _cachedCategories = results[1] as List<NoteCategory>;
      _emitLoaded(emit);
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onCategoryFilterChanged(NotesCategoryFilterChanged event, Emitter<NotesState> emit) async {
    _activeCategoryId = event.categoryId;
    try {
      _cachedNotes = await _noteRepository.getNotes(categoryId: _activeCategoryId);
      _emitLoaded(emit);
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onNoteCreate(NoteCreateRequested event, Emitter<NotesState> emit) async {
    // ✅ Optimistic: add instantly with temp ID
    final optimisticNote = NoteModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      content: event.content,
      categoryId: event.categoryId,
      isPinned: false,
      category: event.categoryId != null
          ? _cachedCategories.cast<NoteCategory?>().firstWhere(
              (c) => c!.id == event.categoryId, orElse: () => null)
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _cachedNotes.insert(0, optimisticNote);
    _emitLoaded(emit);

    // Background: create on server and replace temp note
    try {
      final note = await _noteRepository.createNote(
        title: event.title,
        content: event.content,
        categoryId: event.categoryId,
      );
      final idx = _cachedNotes.indexWhere((n) => n.id == optimisticNote.id);
      if (idx != -1) _cachedNotes[idx] = note;
      _cachedCategories = await _noteRepository.getCategories();
      _emitLoaded(emit);
    } catch (e) {
      _cachedNotes.removeWhere((n) => n.id == optimisticNote.id);
      emit(NotesError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onNoteUpdate(NoteUpdateRequested event, Emitter<NotesState> emit) async {
    // Optimistic update
    final idx = _cachedNotes.indexWhere((n) => n.id == event.noteId);
    NoteModel? old;
    if (idx != -1) {
      old = _cachedNotes[idx];
      _cachedNotes[idx] = old.copyWith(
        title: event.title,
        content: event.content,
        categoryId: event.categoryId,
      );
      _emitLoaded(emit);
    }
    try {
      final updated = await _noteRepository.updateNote(
        event.noteId,
        title: event.title,
        content: event.content,
        categoryId: event.categoryId,
      );
      if (idx != -1) _cachedNotes[idx] = updated;
      _cachedCategories = await _noteRepository.getCategories();
      _emitLoaded(emit);
    } catch (e) {
      if (old != null && idx != -1) _cachedNotes[idx] = old;
      emit(NotesError(e.toString()));
      _emitLoaded(emit);
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
      _cachedCategories = await _noteRepository.getCategories();
      _emitLoaded(emit);
    } catch (e) {
      _cachedNotes.add(deleted);
      _emitLoaded(emit);
    }
  }

  Future<void> _onCategoryCreate(CategoryCreateRequested event, Emitter<NotesState> emit) async {
    try {
      final cat = await _noteRepository.createCategory(name: event.name, color: event.color);
      _cachedCategories.add(cat);
      _emitLoaded(emit);
    } catch (e) {
      emit(NotesError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onCategoryUpdate(CategoryUpdateRequested event, Emitter<NotesState> emit) async {
    try {
      final updated = await _noteRepository.updateCategory(event.categoryId, name: event.name, color: event.color);
      final idx = _cachedCategories.indexWhere((c) => c.id == event.categoryId);
      if (idx != -1) _cachedCategories[idx] = updated;
      _emitLoaded(emit);
    } catch (e) {
      emit(NotesError(e.toString()));
      _emitLoaded(emit);
    }
  }

  Future<void> _onCategoryDelete(CategoryDeleteRequested event, Emitter<NotesState> emit) async {
    final deleted = _cachedCategories.firstWhere((c) => c.id == event.categoryId);
    _cachedCategories.removeWhere((c) => c.id == event.categoryId);
    if (_activeCategoryId == event.categoryId) _activeCategoryId = null;
    _emitLoaded(emit);

    try {
      await _noteRepository.deleteCategory(event.categoryId);
      // Refresh notes since some may have lost their category
      _cachedNotes = await _noteRepository.getNotes(categoryId: _activeCategoryId);
      _emitLoaded(emit);
    } catch (e) {
      _cachedCategories.add(deleted);
      _emitLoaded(emit);
    }
  }
}