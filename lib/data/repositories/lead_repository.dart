import '../models/lead_model.dart';
import '../providers/api_provider.dart';

class LeadRepository {
  final ApiProvider _apiProvider;

  LeadRepository(this._apiProvider);

  // Last successful lead list, kept in memory so the Lead Tracker can show
  // data instantly on revisit while a fresh copy loads. Tied to the auth token
  // that fetched it so a different user never sees a previous user's data.
  List<LeadModel>? _cachedLeads;
  String? _cacheToken;

  /// Last successfully loaded leads, or null if nothing is cached yet
  /// (or the cache belongs to a different session).
  List<LeadModel>? get cachedLeads {
    if (_cachedLeads == null || _cacheToken != _apiProvider.authToken) return null;
    return List<LeadModel>.from(_cachedLeads!);
  }

  void clearCache() {
    _cachedLeads = null;
    _cacheToken = null;
  }

  void _updateCache(List<LeadModel> Function(List<LeadModel> current) update) {
    final current = cachedLeads;
    if (current == null) return;
    _cachedLeads = update(current);
  }

  Future<List<LeadModel>> getLeads() async {
    final response = await _apiProvider.get(
      '/va-leads',
      requiresAuth: true,
      forceRefresh: true,
    );
    final list = response['leads'] as List<dynamic>? ?? [];
    final leads = list.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
    _cachedLeads = List<LeadModel>.from(leads);
    _cacheToken = _apiProvider.authToken;
    return leads;
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
    final lead = LeadModel.fromJson(response['lead'] as Map<String, dynamic>);
    _updateCache((current) => [...current.where((l) => l.id != lead.id), lead]);
    return lead;
  }

  Future<void> submitIntake({
    required String name,
    required String email,
    required String phone,
    String? position,
    required String servicesNeeded,
    String? businessName,
    String? businessAddress,
    String? vaCount,
    String? hoursPerWeek,
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
        if (position != null) 'position': position,
        'servicesNeeded': servicesNeeded,
        if (businessName != null) 'businessName': businessName,
        if (businessAddress != null) 'businessAddress': businessAddress,
        if (vaCount != null) 'vaCount': vaCount,
        if (hoursPerWeek != null) 'hoursPerWeek': hoursPerWeek,
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

  Future<List<Map<String, dynamic>>> getSubmittedIntakes() async {
    final response = await _apiProvider.get(
      '/va-leads/intakes',
      requiresAuth: true,
      forceRefresh: true,
    );
    final list = response['intakes'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> importLeads(List<Map<String, dynamic>> leads) async {
    final response = await _apiProvider.post(
      '/va-leads/bulk',
      {'leads': leads},
      requiresAuth: true,
    );
    // Imported rows only exist server-side until the next getLeads().
    clearCache();
    return (response['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteLead(String id) async {
    await _apiProvider.delete('/va-leads/$id', requiresAuth: true);
    _updateCache((current) => current.where((l) => l.id != id).toList());
  }

  Future<LeadModel> updateLead(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put(
      '/va-leads/$id',
      data,
      requiresAuth: true,
    );
    final updated = LeadModel.fromJson(response['lead'] as Map<String, dynamic>);
    _updateCache((current) => current.map((l) => l.id == id ? updated : l).toList());
    return updated;
  }
}
