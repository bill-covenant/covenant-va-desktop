import 'package:flutter/material.dart';
import '../widgets/log_hours_dialog.dart';

class TimecardHeader extends StatelessWidget {
  final String selectedMonth;
  final List<String> monthOptions;
  final Function(String) onMonthChanged;
  final VoidCallback onLogHours;
  final VoidCallback? onRefresh;
  final Widget? trailing;

  const TimecardHeader({
    super.key,
    required this.selectedMonth,
    required this.monthOptions,
    required this.onMonthChanged,
    required this.onLogHours,
    this.onRefresh,
    this.trailing,
  });

  String _formatMonthDisplay(String month) {
    final parts = month.split('-');
    final year = parts[0];
    final monthNum = int.parse(parts[1]);

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${monthNames[monthNum - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.5),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      offset: const Offset(-2, -2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 20,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'My Timecard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildMonthSelector(),
              const SizedBox(width: 12),
              _buildLogHoursButton(),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          dropdownColor: const Color(0xFF1F2937),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: monthOptions.map((month) {
            return DropdownMenuItem(
              value: month,
              child: Text(_formatMonthDisplay(month)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onMonthChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return _RefreshButton(onRefresh: onRefresh);
  }

  Widget _buildLogHoursButton() {
    return ElevatedButton.icon(
      onPressed: onLogHours,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Log Hours',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF7C3AED),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 8,
        shadowColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final VoidCallback? onRefresh;
  const _RefreshButton({this.onRefresh});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _spinController.repeat();

    widget.onRefresh?.call();

    // Stop spinning after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _spinController.stop();
        setState(() => _isRefreshing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh',
      child: GestureDetector(
        onTap: _handleRefresh,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: RotationTransition(
                turns: _spinController,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}