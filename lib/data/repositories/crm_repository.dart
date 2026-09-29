import '../models/crm_customer_model.dart';
import '../providers/api_provider.dart';

class CrmRepository {
  final ApiProvider _apiProvider;

  CrmRepository(this._apiProvider);

  // Last successful customer list, kept in memory so the CRM screen can show
  // data instantly on revisit while a fresh copy loads. Tied to the auth token
  // that fetched it so a different user never sees a previous user's data.
  List<CrmCustomerModel>? _cachedCustomers;
  String? _cacheToken;

  /// Last successfully loaded customers, or null if nothing is cached yet
  /// (or the cache belongs to a different session).
  List<CrmCustomerModel>? get cachedCustomers {
    if (_cachedCustomers == null || _cacheToken != _apiProvider.authToken) return null;
    return List<CrmCustomerModel>.from(_cachedCustomers!);
  }

  void clearCache() {
    _cachedCustomers = null;
    _cacheToken = null;
  }

  void _updateCache(List<CrmCustomerModel> Function(List<CrmCustomerModel> current) update) {
    final current = cachedCustomers;
    if (current == null) return;
    _cachedCustomers = update(current);
  }

  Future<List<CrmCustomerModel>> getCustomers() async {
    final response = await _apiProvider.get('/crm/customers', requiresAuth: true, forceRefresh: true);
    final list = response['customers'] as List;
    final customers = list.map((j) => CrmCustomerModel.fromJson(j as Map<String, dynamic>)).toList();
    _cachedCustomers = List<CrmCustomerModel>.from(customers);
    _cacheToken = _apiProvider.authToken;
    return customers;
  }

  Future<CrmCustomerModel> createCustomer({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? branchName,
    String? branchEmail,
    String? orderDetails,
    String? notes,
  }) async {
    final response = await _apiProvider.post('/crm/customers', {
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (company != null) 'company': company,
      if (branchName != null) 'branchName': branchName,
      if (branchEmail != null) 'branchEmail': branchEmail,
      if (orderDetails != null) 'orderDetails': orderDetails,
      if (notes != null) 'notes': notes,
    }, requiresAuth: true);
    final customer = CrmCustomerModel.fromJson(response['customer'] as Map<String, dynamic>);
    _updateCache((current) => [customer, ...current.where((c) => c.id != customer.id)]);
    return customer;
  }

  Future<CrmCustomerModel> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/crm/customers/$id', data, requiresAuth: true);
    final updated = CrmCustomerModel.fromJson(response['customer'] as Map<String, dynamic>);
    _updateCache((current) => current.map((c) => c.id == id ? updated : c).toList());
    return updated;
  }

  Future<void> deleteCustomer(String id) async {
    await _apiProvider.delete('/crm/customers/$id', requiresAuth: true);
    _updateCache((current) => current.where((c) => c.id != id).toList());
  }

  Future<String> notifyBranch(String customerId) async {
    final response = await _apiProvider.post('/crm/customers/$customerId/notify', {}, requiresAuth: true);
    return response['message'] as String? ?? 'Notification sent';
  }
}
