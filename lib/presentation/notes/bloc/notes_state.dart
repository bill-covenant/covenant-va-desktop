import 'package:equatable/equatable.dart';
import '../../../data/models/note_model.dart';

abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {
  const NotesInitial();
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  final List<NoteModel> notes;
  /// Set when a load/save failed but [notes] (the last known list) is still
  /// shown. The UI surfaces it as a snackbar instead of a full error view.
  final String? errorMessage;
  /// Distinguishes repeated failures with the same message (Equatable would
  /// otherwise swallow the second emit).
  final int errorId;
  const NotesLoaded({required this.notes, this.errorMessage, this.errorId = 0});
  @override
  List<Object?> get props => [notes, errorMessage, errorId];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}