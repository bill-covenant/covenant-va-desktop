import '../models/lead_model.dart';
import '../providers/api_provider.dart';

class LeadRepository {
  final ApiProvider _apiProvider;

  LeadRepository(this._apiProvider);

  Future<List<LeadModel>> getLeads() async {
    final response = await _apiProvider.get(
      '/va-leads',
      requiresAuth: true,
      forceRefresh: true,
    );
    final list = response['leads'] as List<dynamic>? ?? [];
    return list.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeadModel> createLead({
    required String name,
    required String company,
    String? department,
    required String phone,
    String? email,
    String status = 'New',
  }) async {
    final response = await _apiProvider.post(
      '/va-leads',
      {
        'name': name,
        'company': company,
        if (department != null) 'department': department,
        'phone': phone,
        if (email != null) 'email': email,
        'status': status,
      },
      requiresAuth: true,
    );
    return LeadModel.fromJson(response['lead'] as Map<String, dynamic>);
  }

  Future<LeadModel> updateLead(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put(
      '/va-leads/$id',
      data,
      requiresAuth: true,
    );
    return LeadModel.fromJson(response['lead'] as Map<String, dynamic>);
  }
}
