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
    String? month,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // If date range provided, fetch entries by range and compute summary locally
    if (startDate != null && endDate != null) {
      final entries = await getTimeEntries(
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
      );
      final totalHours = entries.fold<double>(0, (s, e) => s + e.hoursWorked);
      final uniqueDays = entries.map((e) => '${e.date.year}-${e.date.month}-${e.date.day}').toSet().length;
      final summary = MonthlySummary(
        month: month ?? '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}',
        totalHours: double.parse(totalHours.toStringAsFixed(2)),
        daysLogged: uniqueDays,
        avgPerDay: uniqueDays > 0 ? double.parse((totalHours / uniqueDays).toStringAsFixed(2)) : 0,
        estimatedEarnings: 0, // Not applicable for date range view
        entries: entries,
      );
      return (entries: entries, summary: summary);
    }

    // Default: monthly fetch in parallel
    final effectiveMonth = month ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final results = await Future.wait([
      getTimeEntries(clientId: clientId, month: effectiveMonth),
      getMonthlySummary(month: effectiveMonth, clientId: clientId),
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