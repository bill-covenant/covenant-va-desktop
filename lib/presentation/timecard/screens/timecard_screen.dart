import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timecard_bloc.dart';
import '../bloc/timecard_event.dart';
import '../bloc/timecard_state.dart';
import '../widgets/timecard_header.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/time_entries_list.dart';
import '../widgets/timecard_loading_skeleton.dart';
import '../widgets/timecard_error_state.dart';
import '../widgets/log_hours_dialog.dart';

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
          // Persist clock state even if dialog is dismissed
          setState(() {
            _activeClockIn = clockIn;
            _activeClockOut = clockOut;
          });
        },
      ),
    );

    if (result != null && mounted) {
      // Clear persisted clock state after successful save
      setState(() {
        _activeClockIn = null;
        _activeClockOut = null;
      });

      context.read<TimecardBloc>().add(
            LogHours(
              clientId: widget.clientId,
              date: result['date'] as DateTime,
              hoursWorked: result['hoursWorked'] as double,
              description: result['description'] as String?,
            ),
          );
    }
  }

  void _handleDelete(String entryId) {
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
    return BlocConsumer<TimecardBloc, TimecardState>(
      listener: (context, state) {
        if (state is HoursLoggedSuccess) {
          _showSuccessMessage('Hours logged successfully!');
          _loadData();
        } else if (state is TimecardError) {
          _showErrorMessage(state.message);
        } else if (state is TimeEntryDeleted) {
          _showSuccessMessage('Time entry deleted successfully!');
          _loadData();
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
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
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
  }

  Widget _buildContent(TimecardState state) {
    if (state is TimecardLoading) {
      return const TimecardLoadingSkeleton();
    } else if (state is TimecardLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlySummaryCard(summary: state.summary),
          const SizedBox(height: 32),
          TimeEntriesList(
            entries: state.timeEntries,
            onDelete: (entryId) {
              _handleDelete(entryId);
            },
          ),
        ],
      );
    } else if (state is TimecardError) {
      return TimecardErrorState(
        message: state.message,
        onRetry: _loadData,
      );
    }

    return const TimecardLoadingSkeleton();
  }
}