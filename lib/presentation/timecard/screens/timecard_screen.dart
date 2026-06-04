import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../bloc/timecard_bloc.dart';
import '../bloc/timecard_event.dart';
import '../bloc/timecard_state.dart';
import '../widgets/timecard_header.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/pay_period_summary_card.dart';
import '../widgets/time_entries_list.dart';
import '../widgets/timecard_loading_skeleton.dart';
import '../widgets/timecard_error_state.dart';
import '../widgets/log_hours_dialog.dart';
import '../../../data/models/time_entry.dart';
import '../widgets/date_range_picker_dialog.dart' as custom;
import '../../shared/widgets/refresh_fab.dart';

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
  TimecardViewMode _viewMode = TimecardViewMode.monthly;
  String _selectedMonth = _getCurrentMonth();
  String _selectedPayPeriod = '';

  // Date range mode
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

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
    _selectedPayPeriod = _getPayPeriodOptions().first['key'] as String;
    _loadData();
  }

  // ============================================
  // PAY PERIOD HELPERS (Weekly: Mon–Fri, payday following Friday)
  // ============================================

  /// Returns the Monday of the week containing [date].
  static DateTime _getMondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Builds a pay period option map from a Monday start date.
  static Map<String, dynamic> _weeklyPeriod(DateTime monday) {
    final friday = monday.add(const Duration(days: 4));   // same-week Friday
    final payday = monday.add(const Duration(days: 11));  // following Friday
    final key =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final label = '${_fmtShort(monday)} – ${_fmtShort(friday)}, ${monday.year}  •  Payday ${_fmtShort(payday)}';
    return {
      'key': key,
      'label': label,
      'start': monday,
      'end': friday,
      'payday': payday,
    };
  }

  /// Returns the 12 most recent weekly periods (current week first).
  List<Map<String, dynamic>> _getPayPeriodOptions() {
    final now = DateTime.now();
    final currentMonday = _getMondayOf(now);
    final options = <Map<String, dynamic>>[];
    for (int i = 0; i < 12; i++) {
      final monday = currentMonday.subtract(Duration(days: i * 7));
      options.add(_weeklyPeriod(monday));
    }
    return options;
  }

  static String _fmtShort(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  // ============================================
  // DATA LOADING
  // ============================================

  void _loadData() {
    switch (_viewMode) {
      case TimecardViewMode.monthly:
        context.read<TimecardBloc>().add(
          LoadTimecardData(clientId: widget.clientId, month: _selectedMonth),
        );
        break;
      case TimecardViewMode.payPeriod:
        final option = _getPayPeriodOptions().firstWhere(
          (o) => o['key'] == _selectedPayPeriod,
          orElse: () => _getPayPeriodOptions().first,
        );
        context.read<TimecardBloc>().add(
          LoadTimecardData(
            clientId: widget.clientId,
            startDate: option['start'] as DateTime,
            endDate: (option['end'] as DateTime).add(const Duration(days: 1)),
          ),
        );
        break;
      case TimecardViewMode.dateRange:
        if (_rangeStart != null && _rangeEnd != null) {
          context.read<TimecardBloc>().add(
            LoadTimecardData(
              clientId: widget.clientId,
              startDate: _rangeStart!,
              endDate: _rangeEnd!.add(const Duration(days: 1)),
            ),
          );
        }
        break;
    }
  }

  void _silentRefresh() {
    switch (_viewMode) {
      case TimecardViewMode.monthly:
        context.read<TimecardBloc>().add(
          RefreshTimecard(clientId: widget.clientId, month: _selectedMonth),
        );
        break;
      case TimecardViewMode.payPeriod:
        final option = _getPayPeriodOptions().firstWhere(
          (o) => o['key'] == _selectedPayPeriod,
          orElse: () => _getPayPeriodOptions().first,
        );
        context.read<TimecardBloc>().add(
          RefreshTimecard(
            clientId: widget.clientId,
            startDate: option['start'] as DateTime,
            endDate: (option['end'] as DateTime).add(const Duration(days: 1)),
          ),
        );
        break;
      case TimecardViewMode.dateRange:
        if (_rangeStart != null && _rangeEnd != null) {
          context.read<TimecardBloc>().add(
            RefreshTimecard(
              clientId: widget.clientId,
              startDate: _rangeStart!,
              endDate: _rangeEnd!.add(const Duration(days: 1)),
            ),
          );
        }
        break;
    }
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

  void _handleViewModeChanged(TimecardViewMode mode) {
    setState(() {
      _viewMode = mode;
      _cachedEntries = null;
      _cachedSummary = null;
    });
    if (mode == TimecardViewMode.dateRange && _rangeStart == null) {
      _pickDateRange();
    } else {
      _loadData();
    }
  }

  void _handleMonthChanged(String month) {
    setState(() {
      _selectedMonth = month;
      _cachedEntries = null;
      _cachedSummary = null;
    });
    _loadData();
  }

  void _handlePayPeriodChanged(String key) {
    setState(() {
      _selectedPayPeriod = key;
      _cachedEntries = null;
      _cachedSummary = null;
    });
    _loadData();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => custom.DateRangePickerDialog(
        initialStart: _rangeStart,
        initialEnd: _rangeEnd,
      ),
    );

    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
        _cachedEntries = null;
        _cachedSummary = null;
      });
      _loadData();
    }
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
    TimeEntry? deletedEntry;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Time Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this time entry?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              if (_cachedEntries != null) {
                deletedEntry = _cachedEntries!.cast<TimeEntry?>().firstWhere(
                    (e) => e!.id == entryId, orElse: () => null);

                if (deletedEntry != null) {
                  final hours = deletedEntry!.hoursWorked;
                  setState(() {
                    _cachedEntries = _cachedEntries!.where((e) => e.id != entryId).toList();

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
                        entries: _cachedSummary!.entries.where((e) => e.id != entryId).toList(),
                      );
                    }
                  });
                }
              }

              context.read<TimecardBloc>().add(DeleteTimeEntry(entryId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            } else if (state is TimecardLoaded) {
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
                  viewMode: _viewMode,
                  onViewModeChanged: _handleViewModeChanged,
                  selectedMonth: _selectedMonth,
                  monthOptions: _getMonthOptions(),
                  onMonthChanged: _handleMonthChanged,
                  selectedPayPeriod: _selectedPayPeriod,
                  payPeriodOptions: _getPayPeriodOptions(),
                  onPayPeriodChanged: _handlePayPeriodChanged,
                  startDate: _rangeStart,
                  endDate: _rangeEnd,
                  onPickDateRange: _pickDateRange,
                  onLogHours: _handleLogHours,
                  onRefresh: _silentRefresh,
                  trailing: RefreshFAB(onRefresh: () async => _silentRefresh()),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _silentRefresh(),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(50, 32, 48, 40),
                        child: _buildContent(state),
                      ),
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
    final entries = _cachedEntries;
    final summary = _cachedSummary;

    if (entries != null && summary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show appropriate summary card based on view mode
          if (_viewMode == TimecardViewMode.payPeriod) ...[
            Builder(builder: (context) {
              final option = _getPayPeriodOptions().firstWhere(
                (o) => o['key'] == _selectedPayPeriod,
                orElse: () => _getPayPeriodOptions().first,
              );
              return PayPeriodSummaryCard(
                summary: summary,
                periodStart: option['start'] as DateTime,
                periodEnd: option['end'] as DateTime,
                payday: option['payday'] as DateTime,
              );
            }),
          ] else ...[
            MonthlySummaryCard(summary: summary),
          ],
          const SizedBox(height: 32),
          TimeEntriesList(
            entries: entries,
            onDelete: (entryId) => _handleDelete(entryId),
          ),
        ],
      );
    }

    if (state is TimecardError) {
      return TimecardErrorState(
        message: state.message,
        onRetry: _loadData,
      );
    }

    return const SizedBox();
  }
}
