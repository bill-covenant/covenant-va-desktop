import '../providers/api_provider.dart';

/// Reads admin-authored blog posts targeted to VAs.
class BlogRepository {
  final ApiProvider _apiProvider;

  BlogRepository(this._apiProvider);

  Future<List<Map<String, dynamic>>> getVaBlogs() async {
    final response = await _apiProvider.get(
      '/blog/va',
      requiresAuth: true,
      forceRefresh: true,
    );
    final list = response['posts'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
