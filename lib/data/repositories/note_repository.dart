import '../models/note_model.dart';
import '../providers/api_provider.dart';

class NoteRepository {
  final ApiProvider _apiProvider;

  NoteRepository(this._apiProvider);

  Future<List<NoteModel>> getNotes() async {
    final response = await _apiProvider.get('/notes', requiresAuth: true, forceRefresh: true);
    final notesJson = response['notes'] as List;
    return notesJson.map((j) => NoteModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<NoteModel> createNote({required String title, String? content}) async {
    final response = await _apiProvider.post('/notes', {
      'title': title,
      'content': content ?? '',
    }, requiresAuth: true);
    print('📝 NoteRepo: createNote response: $response');
    return NoteModel.fromJson(response['note'] as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote(String id, {String? title, String? content}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    print('📝 NoteRepo: updateNote $id with body: $body');
    final response = await _apiProvider.put('/notes/$id', body, requiresAuth: true);
    print('📝 NoteRepo: updateNote response: $response');
    return NoteModel.fromJson(response['note'] as Map<String, dynamic>);
  }

  Future<NoteModel> togglePin(String id) async {
    final response = await _apiProvider.put('/notes/$id/pin', {}, requiresAuth: true);
    return NoteModel.fromJson(response['note'] as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    await _apiProvider.delete('/notes/$id', requiresAuth: true);
  }
}