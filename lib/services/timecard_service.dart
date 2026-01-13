// lib/presentation/timecard/services/timecard_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/time_entry.dart'; // ← ADD THIS IMPORT

class TimecardService {
  final String baseUrl;
  final String Function() getToken;

  TimecardService({
    required this.baseUrl,
    required this.getToken,
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Log hours for a specific day
  Future<TimeEntry> logHours({
    required String clientId,
    required DateTime date,
    required double hoursWorked,
    String? description,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/timecard/log-hours'),
      headers: headers,
      body: jsonEncode({
        'clientId': clientId,
        'date': date.toIso8601String(),
        'hoursWorked': hoursWorked,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return TimeEntry.fromJson(data['timeEntry']);
    } else {
      throw Exception('Failed to log hours: ${response.body}');
    }
  }

  // Get time entries for a date range
  Future<List<TimeEntry>> getTimeEntries({
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
    String? month,
  }) async {
    final headers = await _getHeaders();
    
    // Build query parameters
    final queryParams = <String, String>{};
    if (clientId != null) queryParams['clientId'] = clientId;
    if (month != null) queryParams['month'] = month;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    
    final uri = Uri.parse('$baseUrl/timecard/entries').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['timeEntries'] as List)
          .map((e) => TimeEntry.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to get time entries: ${response.body}');
    }
  }

  // Get monthly summary
  Future<MonthlySummary> getMonthlySummary({
    required String month, // Format: "2026-02"
    String? clientId,
  }) async {
    final headers = await _getHeaders();
    
    final queryParams = <String, String>{};
    if (clientId != null) queryParams['clientId'] = clientId;
    
    final uri = Uri.parse('$baseUrl/timecard/summary/$month').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MonthlySummary.fromJson(data);
    } else {
      throw Exception('Failed to get monthly summary: ${response.body}');
    }
  }

  // Delete a time entry
  Future<void> deleteTimeEntry(String entryId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/timecard/entries/$entryId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete time entry: ${response.body}');
    }
  }
}