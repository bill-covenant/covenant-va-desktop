import 'package:equatable/equatable.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NotesEvent {
  const NotesLoadRequested();
}

class NoteCreateRequested extends NotesEvent {
  final String title;
  final String content;
  const NoteCreateRequested({required this.title, this.content = ''});
  @override
  List<Object?> get props => [title, content];
}

class NoteUpdateRequested extends NotesEvent {
  final String noteId;
  final String? title;
  final String? content;
  const NoteUpdateRequested({required this.noteId, this.title, this.content});
  @override
  List<Object?> get props => [noteId, title, content];
}

class NotePinToggled extends NotesEvent {
  final String noteId;
  const NotePinToggled(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class NoteDeleteRequested extends NotesEvent {
  final String noteId;
  const NoteDeleteRequested(this.noteId);
  @override
  List<Object?> get props => [noteId];
}