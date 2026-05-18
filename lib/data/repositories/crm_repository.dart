import '../models/crm_branch_model.dart';
import '../models/crm_customer_model.dart';
import '../providers/api_provider.dart';

class CrmRepository {
  final ApiProvider _apiProvider;

  CrmRepository(this._apiProvider);

  Future<List<CrmBranchModel>> getBranches() async {
    final response = await _apiProvider.get('/crm/branches', requiresAuth: true, forceRefresh: true);
    final list = response['branches'] as List;
    return list.map((j) => CrmBranchModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<CrmCustomerModel>> getCustomers() async {
    final response = await _apiProvider.get('/crm/customers', requiresAuth: true, forceRefresh: true);
    final list = response['customers'] as List;
    return list.map((j) => CrmCustomerModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<CrmCustomerModel> createCustomer({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? branchId,
    String? orderDetails,
    String? notes,
  }) async {
    final response = await _apiProvider.post('/crm/customers', {
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (company != null) 'company': company,
      if (branchId != null) 'branchId': branchId,
      if (orderDetails != null) 'orderDetails': orderDetails,
      if (notes != null) 'notes': notes,
    }, requiresAuth: true);
    return CrmCustomerModel.fromJson(response['customer'] as Map<String, dynamic>);
  }

  Future<CrmCustomerModel> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/crm/customers/$id', data, requiresAuth: true);
    return CrmCustomerModel.fromJson(response['customer'] as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(String id) async {
    await _apiProvider.delete('/crm/customers/$id', requiresAuth: true);
  }

  Future<String> notifyBranch(String customerId) async {
    final response = await _apiProvider.post('/crm/customers/$customerId/notify', {}, requiresAuth: true);
    return response['message'] as String? ?? 'Notification sent';
  }
}
