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
    String? industry,
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
        if (industry != null) 'industry': industry,
        if (department != null) 'department': department,
        'phone': phone,
        if (email != null) 'email': email,
        'status': status,
      },
      requiresAuth: true,
    );
    return LeadModel.fromJson(response['lead'] as Map<String, dynamic>);
  }

  Future<void> submitIntake({
    required String name,
    required String email,
    required String phone,
    required String servicesNeeded,
    String? businessName,
    String? businessAddress,
    String? vaCount,
    String? aboutBusiness,
    String? needSuggestions,
    String? startTimeline,
    String? paymentAcknowledgment,
    String? softwareTools,
    String? vaExperience,
    String? anythingElse,
    String? leadId,
  }) async {
    await _apiProvider.post(
      '/va-leads/intake',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'servicesNeeded': servicesNeeded,
        if (businessName != null) 'businessName': businessName,
        if (businessAddress != null) 'businessAddress': businessAddress,
        if (vaCount != null) 'vaCount': vaCount,
        if (aboutBusiness != null) 'aboutBusiness': aboutBusiness,
        if (needSuggestions != null) 'needSuggestions': needSuggestions,
        if (startTimeline != null) 'startTimeline': startTimeline,
        if (paymentAcknowledgment != null) 'paymentAcknowledgment': paymentAcknowledgment,
        if (softwareTools != null) 'softwareTools': softwareTools,
        if (vaExperience != null) 'vaExperience': vaExperience,
        if (anythingElse != null) 'anythingElse': anythingElse,
        if (leadId != null) 'leadId': leadId,
      },
      requiresAuth: true,
    );
  }

  Future<int> importLeads(List<Map<String, dynamic>> leads) async {
    final response = await _apiProvider.post(
      '/va-leads/bulk',
      {'leads': leads},
      requiresAuth: true,
    );
    return (response['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteLead(String id) async {
    await _apiProvider.delete('/va-leads/$id', requiresAuth: true);
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
