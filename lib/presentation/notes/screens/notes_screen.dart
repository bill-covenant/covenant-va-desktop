import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../../../data/models/note_model.dart';
import '../widgets/notes_header.dart';
import '../widgets/notes_list_panel.dart';
import '../widgets/notes_editor_panel.dart';
import '../widgets/notes_dialogs.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  NoteModel? _selectedNote;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(const NotesLoadRequested());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectNote(NoteModel note) {
    _saveCurrentNote();
    setState(() {
      _selectedNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _isEditing = false;
    });
  }

  void _saveCurrentNote() {
    if (_selectedNote != null && _isEditing) {
      final title = _titleController.text.trim();
      if (title.isNotEmpty) {
        context.read<NotesBloc>().add(NoteUpdateRequested(
          noteId: _selectedNote!.id,
          title: title,
          content: _contentController.text,
        ));
      }
    }
  }

  bool _isCreatingNew = false;

  void _createNewNote() {
    // Save current note if editing
    if (_selectedNote != null && _isEditing && !_selectedNote!.id.startsWith('temp_')) {
      final title = _titleController.text.trim();
      if (title.isNotEmpty) {
        context.read<NotesBloc>().add(NoteUpdateRequested(
          noteId: _selectedNote!.id,
          title: title,
          content: _contentController.text,
        ));
      }
    }

    // Set flag so _onStateChanged doesn't override our selection
    _isCreatingNew = true;

    // Immediately show blank editor
    setState(() {
      _selectedNote = NoteModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Untitled Note',
        content: '',
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _titleController.text = 'Untitled Note';
      _contentController.text = '';
      _isEditing = false;
    });

    // Create note on server
    context.read<NotesBloc>().add(const NoteCreateRequested(
      title: 'Untitled Note',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NotesHeader(
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          onNewNote: _createNewNote,
        ),
        Expanded(
          child: BlocConsumer<NotesBloc, NotesState>(
            listener: _onStateChanged,
            builder: (context, state) {
              if (state is NotesLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (state is NotesError) {
                return _buildError(state.message);
              }
              if (state is NotesLoaded) {
                return _buildContent(state);
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  void _onStateChanged(BuildContext context, NotesState state) {
    if (state is NotesLoaded && state.notes.isNotEmpty) {
      if (_selectedNote != null && _selectedNote!.id.startsWith('temp_')) {
        // We're creating a new note — find the real one from the server
        final realNote = state.notes.firstWhere(
          (n) => !n.id.startsWith('temp_'),
          orElse: () => state.notes.first,
        );
        // Only swap the ID, don't touch the editor
        setState(() {
          _selectedNote = _selectedNote!.copyWith().copyWith();
          // Find the newest note (the one just created)
          final newest = state.notes.reduce((a, b) =>
              a.createdAt.isAfter(b.createdAt) ? a : b);
          _selectedNote = newest;
          _isCreatingNew = false;
        });
        return;
      }

      if (_isCreatingNew) return; // Don't override during creation

      if (_selectedNote == null) {
        _selectNote(state.notes.first);
      } else {
        final updated = state.notes.cast<NoteModel?>().firstWhere(
          (n) => n!.id == _selectedNote!.id,
          orElse: () => null,
        );
        if (updated != null) setState(() => _selectedNote = updated);
      }
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<NotesBloc>().add(const NotesLoadRequested()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NotesLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 48, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel - Notes list
          SizedBox(
            width: 340,
            child: NotesListPanel(
              notes: state.notes,
              searchQuery: _searchQuery,
              selectedNote: _selectedNote,
              onNoteSelected: _selectNote,
            ),
          ),
          const SizedBox(width: 24),
          // Right panel - Editor
          Expanded(
            child: NotesEditorPanel(
              selectedNote: _selectedNote,
              titleController: _titleController,
              contentController: _contentController,
              onContentChanged: () => setState(() => _isEditing = true),
              onSave: () {
                if (_selectedNote == null) return;
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                
                print('💾 Save clicked — noteId: ${_selectedNote!.id}, title: $title');
                
                if (!_selectedNote!.id.startsWith('temp_')) {
                  context.read<NotesBloc>().add(NoteUpdateRequested(
                    noteId: _selectedNote!.id,
                    title: title,
                    content: _contentController.text,
                  ));
                }
                _isEditing = false;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Note saved'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onDelete: () async {
                final confirm = await NotesDialogs.showDeleteConfirm(context);
                if (confirm == true && mounted) {
                  if (!_selectedNote!.id.startsWith('temp_')) {
                    context.read<NotesBloc>().add(NoteDeleteRequested(_selectedNote!.id));
                  }
                  setState(() => _selectedNote = null);
                }
              },
              onTogglePin: () {
                if (!_selectedNote!.id.startsWith('temp_')) {
                  context.read<NotesBloc>().add(NotePinToggled(_selectedNote!.id));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}