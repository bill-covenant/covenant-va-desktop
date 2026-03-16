import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/dashboard_content.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static DashboardLoaded? _cachedState;
  static DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    
    final bloc = context.read<DashboardBloc>();
    
    if (_lastFetchTime == null || 
        DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
      bloc.add(const DashboardLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        return BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardLoaded) {
              _cachedState = state;
              _lastFetchTime = DateTime.now();
            }
          },
          child: DashboardContent(
            cachedState: _cachedState,
          ),
        );
      },
    );
  }
}