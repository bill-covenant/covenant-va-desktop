import '../models/note_model.dart';
import '../providers/api_provider.dart';

class NoteRepository {
  final ApiProvider _apiProvider;

  NoteRepository(this._apiProvider);

  // ==================== CATEGORIES ====================

  Future<List<NoteCategory>> getCategories() async {
    final response = await _apiProvider.get('/notes/categories', requiresAuth: true);
    final categoriesJson = response['categories'] as List;
    return categoriesJson.map((j) => NoteCategory.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<NoteCategory> createCategory({required String name, String? color}) async {
    final response = await _apiProvider.post('/notes/categories', {
      'name': name,
      if (color != null) 'color': color,
    }, requiresAuth: true);
    return NoteCategory.fromJson(response['category'] as Map<String, dynamic>);
  }

  Future<NoteCategory> updateCategory(String id, {String? name, String? color}) async {
    final response = await _apiProvider.put('/notes/categories/$id', {
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    }, requiresAuth: true);
    return NoteCategory.fromJson(response['category'] as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _apiProvider.delete('/notes/categories/$id', requiresAuth: true);
  }

  // ==================== NOTES ====================

  Future<List<NoteModel>> getNotes({String? categoryId}) async {
    final query = categoryId != null ? '?categoryId=$categoryId' : '';
    final response = await _apiProvider.get('/notes$query', requiresAuth: true);
    final notesJson = response['notes'] as List;
    return notesJson.map((j) => NoteModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<NoteModel> createNote({required String title, String? content, String? categoryId}) async {
    final response = await _apiProvider.post('/notes', {
      'title': title,
      'content': content ?? '',
      if (categoryId != null) 'categoryId': categoryId,
    }, requiresAuth: true);
    return NoteModel.fromJson(response['note'] as Map<String, dynamic>);
  }

  Future<NoteModel> updateNote(String id, {String? title, String? content, String? categoryId}) async {
    final response = await _apiProvider.put('/notes/$id', {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      'categoryId': categoryId,
    }, requiresAuth: true);
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