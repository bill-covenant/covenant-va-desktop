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
import '../widgets/timecard_error_state.dart';
import '../widgets/timecard_loading_skeleton.dart';
import '../widgets/log_hours_dialog.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/repositories/timecard_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/pay_period.dart';
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

  // A shift that was clocked out but not yet saved as an entry.
  final TimecardRepository _timecardRepo = getIt<TimecardRepository>();
  ({DateTime clockIn, DateTime clockOut})? _pendingShift;
  String? _clockStatusError; // last clock-status fetch failed (offline?)

  // Data as it was before optimistic updates, restored if the server rejects them.
  ({List<TimeEntry>? entries, MonthlySummary? summary})? _preLogSnapshot;
  final Map<String, ({List<TimeEntry>? entries, MonthlySummary? summary})> _preDeleteSnapshots = {};

  // Data currently shown (incl. optimistic edits). Seeded from the repository's
  // per-view cache so revisits / switching back to a viewed period render
  // instantly while a fresh copy loads in the background.
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
    _seedFromCache();
    _loadData();
    _loadClockStatus();
  }

  /// Check the backend for a pending (clocked-out, unsaved) shift so we can nag
  /// the VA to save it before it's lost. On failure the last known state is
  /// kept and an offline banner is shown — a failed request must not look
  /// like "no pending shift".
  Future<void> _loadClockStatus() async {
    try {
      final status = await _timecardRepo.getClockStatus();
      if (!mounted) return;
      setState(() {
        _clockStatusError = null;
        _pendingShift = (status.pendingClockIn != null && status.pendingClockOut != null)
            ? (clockIn: status.pendingClockIn!, clockOut: status.pendingClockOut!)
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clockStatusError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================
  // PAY PERIOD HELPERS (Semi-monthly: cut-off on the 2nd & 4th Thursday of
  // each month, payday the following Friday. A period runs from the day after
  // the previous cut-off through the cut-off Thursday.) Math lives in
  // core/utils/pay_period.dart.
  // ============================================

  /// The 12 most recent pay periods, current (open) period first.
  List<Map<String, dynamic>> _getPayPeriodOptions() {
    return recentPayPeriods(DateTime.now()).map((p) => p.toOption()).toList();
  }

  Map<String, dynamic> _selectedPayPeriodOption() {
    final options = _getPayPeriodOptions();
    return options.firstWhere(
      (o) => o['key'] == _selectedPayPeriod,
      orElse: () => options.first,
    );
  }

  // ============================================
  // DATA LOADING
  // ============================================

  // Date filters are inclusive calendar days: the server filters with
  // gte startDate / lte endDate and entries are stored at midnight of their
  // date, so the cut-off (or range end) itself is sent — not end + 1 day,
  // which pulled the next day's entries into two periods.
  ({DateTime start, DateTime end})? _currentRange() {
    switch (_viewMode) {
      case TimecardViewMode.monthly:
        return null;
      case TimecardViewMode.payPeriod:
        final option = _selectedPayPeriodOption();
        return (start: option['start'] as DateTime, end: option['end'] as DateTime);
      case TimecardViewMode.dateRange:
        if (_rangeStart != null && _rangeEnd != null) {
          return (start: dateOnly(_rangeStart!), end: dateOnly(_rangeEnd!));
        }
        return null;
    }
  }

  void _loadData() {
    final range = _currentRange();
    if (_viewMode == TimecardViewMode.monthly) {
      context.read<TimecardBloc>().add(
        LoadTimecardData(clientId: widget.clientId, month: _selectedMonth),
      );
    } else if (range != null) {
      context.read<TimecardBloc>().add(
        LoadTimecardData(
          clientId: widget.clientId,
          startDate: range.start,
          endDate: range.end,
        ),
      );
    }
  }

  /// Show the last loaded data for the current selection (if any) instead of
  /// clearing the view. Call inside setState when the selection changes.
  void _seedFromCache() {
    final range = _currentRange();
    final hasQuery = _viewMode == TimecardViewMode.monthly || range != null;
    final cached = hasQuery
        ? _timecardRepo.cachedTimecardData(
            clientId: widget.clientId,
            month: _viewMode == TimecardViewMode.monthly ? _selectedMonth : null,
            startDate: range?.start,
            endDate: range?.end,
          )
        : null;
    _cachedEntries = cached?.entries;
    _cachedSummary = cached?.summary;
  }

  void _silentRefresh() {
    final range = _currentRange();
    if (_viewMode == TimecardViewMode.monthly) {
      context.read<TimecardBloc>().add(
        RefreshTimecard(clientId: widget.clientId, month: _selectedMonth),
      );
    } else if (range != null) {
      context.read<TimecardBloc>().add(
        RefreshTimecard(
          clientId: widget.clientId,
          startDate: range.start,
          endDate: range.end,
        ),
      );
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
      _seedFromCache();
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
      _seedFromCache();
    });
    _loadData();
  }

  void _handlePayPeriodChanged(String key) {
    setState(() {
      _selectedPayPeriod = key;
      _seedFromCache();
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

    if (picked != null && mounted) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
        _seedFromCache();
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
      // Keep _activeClockIn/_activeClockOut/_pendingShift until the server
      // confirms the save (HoursLoggedSuccess) so a failed save never loses
      // the shift. Snapshot the list so a failure can roll back the
      // optimistic entry.
      _preLogSnapshot = (entries: _cachedEntries, summary: _cachedSummary);

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
    } else if (mounted) {
      // Dialog dismissed without saving — refresh in case a shift was clocked
      // out inside the dialog (now pending) or discarded.
      _loadClockStatus();
    }
  }

  void _handleDelete(String entryId) {
    TimeEntry? deletedEntry;

    // Optimistic entries don't exist on the server yet — nothing to delete.
    if (entryId.startsWith('temp_')) {
      _showErrorMessage('This entry is still being saved. Please try again in a moment.');
      return;
    }

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
                  // Keep a copy so a failed server delete can be rolled back
                  _preDeleteSnapshots[entryId] =
                      (entries: _cachedEntries, summary: _cachedSummary);
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

  Widget _buildClockStatusErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 12, 48, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Couldn\'t check your clock status — showing the last known state. $_clockStatusError',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5, height: 1.3),
              ),
            ),
            TextButton(
              onPressed: _loadClockStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    final p = _pendingShift!;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String fmt(DateTime dt) {
      final t = TimeOfDay.fromDateTime(dt.toLocal());
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
    }
    final inL = p.clockIn.toLocal();
    final dateLabel = '${months[inL.month - 1]} ${inL.day}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 16, 48, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogHours,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unsaved shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '$dateLabel · ${fmt(p.clockIn)} → ${fmt(p.clockOut)} hasn\'t been saved yet. Tap to review and save it.',
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Save now', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
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
              // Server confirmed the save — only now drop the local shift.
              setState(() {
                _activeClockIn = null;
                _activeClockOut = null;
                _pendingShift = null;
                _preLogSnapshot = null;
              });
              _showSuccessMessage('Hours logged successfully!');
              // The server clears the pending shift only when the entry date
              // matches the pending clock-in date — re-check to be sure.
              _loadClockStatus();
            } else if (state is LogHoursFailed) {
              // Roll back the optimistic entry; pending shift/clock state were
              // never cleared, so the VA can retry.
              final snap = _preLogSnapshot;
              if (snap != null) {
                setState(() {
                  _cachedEntries = snap.entries;
                  _cachedSummary = snap.summary;
                  _preLogSnapshot = null;
                });
              }
              _showErrorMessage(state.message);
              _loadClockStatus();
            } else if (state is DeleteEntryFailed) {
              final snap = _preDeleteSnapshots.remove(state.entryId);
              if (snap != null) {
                setState(() {
                  _cachedEntries = snap.entries;
                  _cachedSummary = snap.summary;
                });
              }
              _showErrorMessage(state.message);
            } else if (state is TimecardError) {
              // Load/refresh failed (e.g. offline) — keep showing cached data.
              _showErrorMessage(state.message);
            } else if (state is TimeEntryDeleted) {
              _preDeleteSnapshots.remove(state.entryId);
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
                if (_pendingShift != null) _buildPendingBanner(),
                if (_clockStatusError != null) _buildClockStatusErrorBanner(),
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
                      // Slivers so the entries list is built lazily (only
                      // visible cards are laid out).
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(50, 32, 48, 40),
                            sliver: _buildContent(state),
                          ),
                        ],
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

  /// Returns a sliver.
  Widget _buildContent(TimecardState state) {
    final entries = _cachedEntries;
    final summary = _cachedSummary;

    if (entries != null && summary != null) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show appropriate summary card based on view mode
                if (_viewMode == TimecardViewMode.payPeriod) ...[
                  Builder(builder: (context) {
                    final option = _selectedPayPeriodOption();
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
              ],
            ),
          ),
          TimeEntriesList(
            entries: entries,
            onDelete: (entryId) => _handleDelete(entryId),
          ),
        ],
      );
    }

    if (state is TimecardError) {
      return SliverToBoxAdapter(
        child: TimecardErrorState(
          message: state.message,
          onRetry: _loadData,
        ),
      );
    }

    // Custom range mode before a range has been picked: nothing to load.
    if (_viewMode == TimecardViewMode.dateRange && _currentRange() == null) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    // First load for this view — no data yet.
    return const SliverToBoxAdapter(child: TimecardLoadingSkeleton());
  }
}
