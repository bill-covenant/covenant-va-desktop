import '../models/announcement_model.dart';
import '../providers/api_provider.dart';

class AnnouncementRepository {
  final ApiProvider _apiProvider;

  AnnouncementRepository(this._apiProvider);

  Future<List<AnnouncementModel>> getPublishedAnnouncements() async {
    final response = await _apiProvider.get(
      '/announcements/published',
      requiresAuth: true,
      forceRefresh: true,
    );
    final list = response['announcements'] as List;
    return list
        .map((j) => AnnouncementModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Dismiss an announcement server-side so it never comes back
  Future<void> dismissAnnouncement(String id) async {
    await _apiProvider.post(
      '/announcements/$id/dismiss',
      {},
      requiresAuth: true,
    );
  }
}