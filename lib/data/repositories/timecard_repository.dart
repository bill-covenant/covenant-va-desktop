// lib/data/repositories/timecard_repository.dart

import '../models/time_entry.dart';
import '../providers/api_provider.dart';

class TimecardRepository {
  final ApiProvider apiProvider;

  TimecardRepository({required this.apiProvider});

  // ============================================
  // CLOCK IN / OUT (persisted to backend)
  // ============================================

  /// Get active clock-in status
  Future<DateTime?> getActiveClock() async {
    try {
      final response = await apiProvider.get(
        '/timecard/clock',
        requiresAuth: true,
      );
      final clockIn = response['activeClockIn'];
      if (clockIn != null) {
        return DateTime.parse(clockIn);
      }
      return null;
    } catch (e) {
      print('❌ getActiveClock error: $e');
      return null;
    }
  }

  /// Clock in — saves timestamp to backend
  Future<DateTime> clockIn() async {
    final response = await apiProvider.post(
      '/timecard/clock-in',
      {},
      requiresAuth: true,
    );
    return DateTime.parse(response['activeClockIn']);
  }

  /// Clock out — clears backend clock-in, returns calculated hours
  Future<Map<String, dynamic>> clockOut() async {
    final response = await apiProvider.post(
      '/timecard/clock-out',
      {},
      requiresAuth: true,
    );
    return {
      'clockInTime': DateTime.parse(response['clockInTime']),
      'clockOutTime': DateTime.parse(response['clockOutTime']),
      'hoursWorked': (response['hoursWorked'] as num).toDouble(),
    };
  }

  // ============================================
  // EXISTING METHODS
  // ============================================

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

    final response = await apiProvider.get(
      '/timecard/entries',
      queryParams: queryParams,
      requiresAuth: true,
    );

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

    final response = await apiProvider.get(
      '/timecard/summary/$month',
      queryParams: queryParams,
      requiresAuth: true,
    );

    return MonthlySummary.fromJson(response);
  }

  Future<void> deleteTimeEntry(String entryId) async {
    await apiProvider.delete(
      '/timecard/entries/$entryId',
      requiresAuth: true,
    );
  }
}