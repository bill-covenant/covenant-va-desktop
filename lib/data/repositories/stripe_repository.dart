import '../providers/api_provider.dart';

/// Stripe Connect status model
class StripeStatus {
  final String status;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final String? bankLast4;
  final String? bankName;
  final Map<String, dynamic>? requirements;
  final DateTime? connectedAt;

  StripeStatus({
    required this.status,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    this.bankLast4,
    this.bankName,
    this.requirements,
    this.connectedAt,
  });

  factory StripeStatus.fromJson(Map<String, dynamic> json) {
    return StripeStatus(
      status: json['status'] ?? 'not_connected',
      chargesEnabled: json['chargesEnabled'] ?? false,
      payoutsEnabled: json['payoutsEnabled'] ?? false,
      bankLast4: json['bankLast4'],
      bankName: json['bankName'],
      requirements: json['requirements'] as Map<String, dynamic>?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.tryParse(json['connectedAt'])
          : null,
    );
  }

  /// Account is fully active and can receive payouts
  bool get isActive => status == 'active';

  /// Onboarding started but not yet verified
  bool get isPending => status == 'pending';

  /// Stripe needs more info from the VA
  bool get needsAction =>
      status == 'restricted' ||
      (requirements != null &&
          (requirements!['currently_due'] as List?)?.isNotEmpty == true);

  /// VA hasn't started Stripe Connect at all
  bool get isNotConnected => status == 'not_connected';
}

class StripeRepository {
  final ApiProvider _apiProvider;

  StripeRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  /// Check if VA has connected their Stripe account
  Future<StripeStatus> getStripeStatus() async {
    try {
      final response = await _apiProvider.get(
        '/stripe-connect/status',
        requiresAuth: true,
      );
      return StripeStatus.fromJson(response);
    } catch (e) {
      print('❌ StripeRepository: getStripeStatus error - $e');
      rethrow;
    }
  }

  /// Get Stripe Connect onboarding link (creates account if needed)
  Future<String> getConnectLink() async {
    try {
      final response = await _apiProvider.post(
        '/stripe-connect/onboarding-link',
        {},
        requiresAuth: true,
      );
      return response['url'] as String;
    } catch (e) {
      print('❌ StripeRepository: getConnectLink error - $e');
      rethrow;
    }
  }

  /// Get Stripe Express dashboard link (for already-connected VAs)
  Future<String> getDashboardLink() async {
    try {
      final response = await _apiProvider.get(
        '/stripe-connect/dashboard-link',
        requiresAuth: true,
      );
      return response['url'] as String;
    } catch (e) {
      print('❌ StripeRepository: getDashboardLink error - $e');
      rethrow;
    }
  }

  /// Get VA's payout history
  Future<List<Map<String, dynamic>>> getPayoutHistory({int limit = 20}) async {
    try {
      final response = await _apiProvider.get(
        '/stripe-connect/payout-history',
        queryParams: {'limit': limit.toString()},
        requiresAuth: true,
      );
      return List<Map<String, dynamic>>.from(response['payouts'] ?? []);
    } catch (e) {
      print('❌ StripeRepository: getPayoutHistory error - $e');
      rethrow;
    }
  }
}