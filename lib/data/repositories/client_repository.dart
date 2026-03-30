import '../models/client_model.dart';
import '../providers/api_provider.dart';

class ClientRepository {
  final ApiProvider _apiProvider;

  ClientRepository(this._apiProvider);

  /// Get all clients assigned to the current VA
  Future<List<ClientModel>> getAssignedClients({bool forceRefresh = false}) async {
    try {
      final response = await _apiProvider.get(
        '/va/assigned-clients',
        requiresAuth: true,
        forceRefresh: forceRefresh,
      );
      
      if (response['data'] != null) {
        final List<dynamic> clientsJson = response['data'] as List<dynamic>;
        return clientsJson
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching assigned clients: $e');
      rethrow;
    }
  }
}