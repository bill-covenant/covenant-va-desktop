import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../bloc/timecard_bloc.dart';
import '../bloc/timecard_event.dart';
import '../bloc/timecard_state.dart';
import '../widgets/timecard_header.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/time_entries_list.dart';
import '../widgets/timecard_loading_skeleton.dart';
import '../widgets/timecard_error_state.dart';
import '../widgets/log_hours_dialog.dart';
import '../../../data/models/time_entry.dart';

class TimecardScreen extends StatefulWidget {
  final String clientId;

  const TimecardScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<TimecardScreen> createState() => _TimecardScreenState();
}

class _TimecardScreenState extends State<TimecardScreen> {
  String _selectedMonth = _getCurrentMonth();

  // Persistent clock state — survives dialog dismiss
  TimeOfDay? _activeClockIn;
  TimeOfDay? _activeClockOut;

  // Cache last loaded data so we never flash a skeleton unnecessarily
  List<TimeEntry>? _cachedEntries;
  MonthlySummary? _cachedSummary;

  static String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<TimecardBloc>().add(
          LoadTimecardData(
            clientId: widget.clientId,
            month: _selectedMonth,
          ),
        );
  }

  void _silentRefresh() {
    context.read<TimecardBloc>().add(
          RefreshTimecard(
            clientId: widget.clientId,
            month: _selectedMonth,
          ),
        );
  }

  List<String> _getMonthOptions() {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(monthStr);
    }
    return months;
  }

  void _handleMonthChanged(String month) {
    setState(() {
      _selectedMonth = month;
      // Clear cache when switching months so we show skeleton for new data
      _cachedEntries = null;
      _cachedSummary = null;
    });
    _loadData();
  }

  Future<void> _handleLogHours() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LogHoursDialog(
        initialClockIn: _activeClockIn,
        initialClockOut: _activeClockOut,
        onClockStateChanged: (clockIn, clockOut) {
          setState(() {
            _activeClockIn = clockIn;
            _activeClockOut = clockOut;
          });
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _activeClockIn = null;
        _activeClockOut = null;
      });

      final date = result['date'] as DateTime;
      final hoursWorked = result['hoursWorked'] as double;
      final description = result['description'] as String?;

      // Optimistic update — add entry to list instantly
      if (_cachedEntries != null && _cachedSummary != null) {
        final optimisticEntry = TimeEntry(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          vaId: '',
          clientId: widget.clientId,
          assignmentId: '',
          date: date,
          hoursWorked: hoursWorked,
          description: description,
          status: 'SUBMITTED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        setState(() {
          _cachedEntries = [optimisticEntry, ..._cachedEntries!];
          // Update summary optimistically
          _cachedSummary = MonthlySummary(
            month: _cachedSummary!.month,
            totalHours: _cachedSummary!.totalHours + hoursWorked,
            daysLogged: _cachedSummary!.daysLogged + 1,
            avgPerDay: (_cachedSummary!.totalHours + hoursWorked) /
                (_cachedSummary!.daysLogged + 1),
            estimatedEarnings: _cachedSummary!.estimatedEarnings +
                (hoursWorked * (_cachedSummary!.estimatedEarnings /
                    (_cachedSummary!.totalHours > 0 ? _cachedSummary!.totalHours : 1))),
            entries: [optimisticEntry, ..._cachedSummary!.entries],
          );
        });
      }

      // Fire the actual API call (will silently refresh with real data)
      context.read<TimecardBloc>().add(
            LogHours(
              clientId: widget.clientId,
              date: date,
              hoursWorked: hoursWorked,
              description: description,
            ),
          );
    }
  }

  void _handleDelete(String entryId) {
    // Optimistic delete — remove immediately before even showing confirm dialog
    TimeEntry? deletedEntry;
    MonthlySummary? oldSummary;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Time Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this time entry?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Optimistic delete from entries + update summary instantly
              if (_cachedEntries != null) {
                deletedEntry = _cachedEntries!.cast<TimeEntry?>().firstWhere(
                    (e) => e!.id == entryId,
                    orElse: () => null);
                oldSummary = _cachedSummary;

                if (deletedEntry != null) {
                  final hours = deletedEntry!.hoursWorked;
                  setState(() {
                    _cachedEntries = _cachedEntries!
                        .where((e) => e.id != entryId)
                        .toList();

                    if (_cachedSummary != null) {
                      final newTotal = (_cachedSummary!.totalHours - hours).clamp(0.0, double.infinity);
                      final newDays = (_cachedSummary!.daysLogged - 1).clamp(0, 9999);
                      final rate = _cachedSummary!.totalHours > 0
                          ? _cachedSummary!.estimatedEarnings / _cachedSummary!.totalHours
                          : 0.0;
                      _cachedSummary = MonthlySummary(
                        month: _cachedSummary!.month,
                        totalHours: newTotal,
                        daysLogged: newDays,
                        avgPerDay: newDays > 0 ? newTotal / newDays : 0.0,
                        estimatedEarnings: newTotal * rate,
                        entries: _cachedSummary!.entries
                            .where((e) => e.id != entryId)
                            .toList(),
                      );
                    }
                  });
                }
              }

              // Fire API call in background
              context.read<TimecardBloc>().add(DeleteTimeEntry(entryId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
    return BlocConsumer<TimecardBloc, TimecardState>(
      listener: (context, state) {
        if (state is HoursLoggedSuccess) {
          _showSuccessMessage('Hours logged successfully!');
        } else if (state is TimecardError) {
          _showErrorMessage(state.message);
        } else if (state is TimeEntryDeleted) {
          _showSuccessMessage('Time entry deleted successfully!');
          // Don't refresh here — optimistic update already handled it
          // The next natural load (screen revisit, month change) will sync
        } else if (state is TimecardLoaded) {
          // Update cache with server data
          setState(() {
            _cachedEntries = state.timeEntries;
            _cachedSummary = state.summary;
          });
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimecardHeader(
              selectedMonth: _selectedMonth,
              monthOptions: _getMonthOptions(),
              onMonthChanged: _handleMonthChanged,
              onLogHours: _handleLogHours,
              onRefresh: _silentRefresh,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _silentRefresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(50, 32, 48, 40),
                  child: _buildContent(state),
                ),
              ),
            ),
          ],
        );
      },
    );
      },
    );
  }

  Widget _buildContent(TimecardState state) {
    // Always prefer cached data if available (includes optimistic updates)
    final entries = _cachedEntries;
    final summary = _cachedSummary;

    if (entries != null && summary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlySummaryCard(summary: summary),
          const SizedBox(height: 32),
          TimeEntriesList(
            entries: entries,
            onDelete: (entryId) {
              _handleDelete(entryId);
            },
          ),
        ],
      );
    }

    // No cached data — show skeleton only on first load
    if (state is TimecardLoading) {
      return const TimecardLoadingSkeleton();
    } else if (state is TimecardError) {
      return TimecardErrorState(
        message: state.message,
        onRetry: _loadData,
      );
    }

    return const TimecardLoadingSkeleton();
  }
}