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
  final List<NoteCategory> categories;
  final String? activeCategoryId;

  const NotesLoaded({
    required this.notes,
    required this.categories,
    this.activeCategoryId,
  });

  @override
  List<Object?> get props => [notes, categories, activeCategoryId];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}