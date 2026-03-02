import 'package:equatable/equatable.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NotesEvent {
  const NotesLoadRequested();
}

class NotesCategoryFilterChanged extends NotesEvent {
  final String? categoryId;
  const NotesCategoryFilterChanged(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class NoteCreateRequested extends NotesEvent {
  final String title;
  final String content;
  final String? categoryId;
  const NoteCreateRequested({required this.title, this.content = '', this.categoryId});
  @override
  List<Object?> get props => [title, content, categoryId];
}

class NoteUpdateRequested extends NotesEvent {
  final String noteId;
  final String? title;
  final String? content;
  final String? categoryId;
  const NoteUpdateRequested({required this.noteId, this.title, this.content, this.categoryId});
  @override
  List<Object?> get props => [noteId, title, content, categoryId];
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

class CategoryCreateRequested extends NotesEvent {
  final String name;
  final String? color;
  const CategoryCreateRequested({required this.name, this.color});
  @override
  List<Object?> get props => [name, color];
}

class CategoryUpdateRequested extends NotesEvent {
  final String categoryId;
  final String? name;
  final String? color;
  const CategoryUpdateRequested({required this.categoryId, this.name, this.color});
  @override
  List<Object?> get props => [categoryId, name, color];
}

class CategoryDeleteRequested extends NotesEvent {
  final String categoryId;
  const CategoryDeleteRequested(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}