import '../models/time_entry.dart';
import '../providers/api_provider.dart';

class TimecardRepository {
  final ApiProvider apiProvider;

  TimecardRepository({required this.apiProvider});

  // ============================================
  // CLOCK IN / OUT
  // ============================================

  Future<DateTime?> getActiveClock() async {
    try {
      final response = await apiProvider.get(
        '/timecard/clock',
        requiresAuth: true,
        cacheDuration: const Duration(seconds: 10),
      );
      final clockIn = response['activeClockIn'];
      if (clockIn != null) {
        return DateTime.parse(clockIn);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DateTime> clockIn() async {
    final response = await apiProvider.post(
      '/timecard/clock-in',
      {},
      requiresAuth: true,
    );
    return DateTime.parse(response['activeClockIn']);
  }

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
  // COMBINED LOAD — parallel fetch
  // ============================================

  /// Fetch entries + summary in parallel instead of sequentially
  Future<({List<TimeEntry> entries, MonthlySummary summary})> loadTimecardData({
    String? clientId,
    required String month,
  }) async {
    final results = await Future.wait([
      getTimeEntries(clientId: clientId, month: month),
      getMonthlySummary(month: month, clientId: clientId),
    ]);

    return (
      entries: results[0] as List<TimeEntry>,
      summary: results[1] as MonthlySummary,
    );
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