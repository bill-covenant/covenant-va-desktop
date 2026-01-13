// lib/data/repositories/timecard_repository.dart

import '../models/time_entry.dart';
import '../providers/api_provider.dart';

class TimecardRepository {
  final ApiProvider apiProvider;

  TimecardRepository({required this.apiProvider});

  Future<TimeEntry> logHours({
    required String clientId,
    required DateTime date,
    required double hoursWorked,
    String? description,
  }) async {
    final response = await apiProvider.post(
      '/timecard/log-hours',
      {
        'clientId': clientId,
        'date': date.toIso8601String(),
        'hoursWorked': hoursWorked,
        'description': description,
      },
      requiresAuth: true,
    );

    print('📦 logHours response: $response'); // ← DEBUG

    return TimeEntry.fromJson(response['timeEntry']);
  }

  Future<List<TimeEntry>> getTimeEntries({
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
    String? month,
  }) async {
    Map<String, String>? queryParams;
    
    if (clientId != null && clientId.isNotEmpty ||
        month != null ||
        startDate != null ||
        endDate != null) {
      queryParams = {};
      
      if (clientId != null && clientId.isNotEmpty) {
        queryParams['clientId'] = clientId;
      }
      if (month != null) queryParams['month'] = month;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
    }

    print('🔍 getTimeEntries queryParams: $queryParams'); // ← DEBUG

    final response = await apiProvider.get(
      '/timecard/entries',
      queryParams: queryParams,
      requiresAuth: true,
    );

    print('📦 getTimeEntries response: $response'); // ← DEBUG
    print('📦 Response type: ${response.runtimeType}'); // ← DEBUG
    print('📦 Has timeEntries key: ${response.containsKey("timeEntries")}'); // ← DEBUG

    return (response['timeEntries'] as List)
        .map((e) => TimeEntry.fromJson(e))
        .toList();
  }

  Future<MonthlySummary> getMonthlySummary({
    required String month,
    String? clientId,
  }) async {
    Map<String, String>? queryParams;
    
    if (clientId != null && clientId.isNotEmpty) {
      queryParams = {'clientId': clientId};
    }

    print('🔍 getMonthlySummary month: $month, clientId: $clientId'); // ← DEBUG

    final response = await apiProvider.get(
      '/timecard/summary/$month',
      queryParams: queryParams,
      requiresAuth: true,
    );

    print('📦 getMonthlySummary response: $response'); // ← DEBUG

    return MonthlySummary.fromJson(response);
  }

  Future<void> deleteTimeEntry(String entryId) async {
    print('🗑️ Deleting entry: $entryId'); // ← DEBUG
    
    await apiProvider.delete(
      '/timecard/entries/$entryId',
      requiresAuth: true,
    );
    
    print('✅ Entry deleted successfully'); // ← DEBUG
  }
}