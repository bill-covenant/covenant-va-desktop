import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'core/constants/app_theme.dart';
import 'core/di/service_locator.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/dashboard/bloc/dashboard_event.dart';
import 'presentation/dashboard/screens/dashboard_screen.dart';
import 'presentation/tasks/screens/my_tasks_screen.dart';
import 'presentation/messages/screens/messages_screen.dart';
import 'presentation/messages/bloc/messages_bloc.dart';
import 'presentation/messages/bloc/messages_event.dart';
import 'presentation/notes/screens/notes_screen.dart';
import 'presentation/notes/bloc/notes_bloc.dart';
import 'presentation/profile/screens/profile_screen.dart';
import 'presentation/shared/layouts/main_layout.dart';
import 'presentation/notifications/bloc/notification_bloc.dart';
import 'presentation/notifications/bloc/notification_event.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/timecard/bloc/timecard_bloc.dart';
import 'presentation/timecard/screens/timecard_screen.dart';
import 'data/repositories/notification_repository.dart';
import 'data/providers/api_provider.dart';
import 'services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SocketService().initNotifications();
  await setupServiceLocator();
  
  runApp(const CovenantVAApp());
}

class CovenantVAApp extends StatelessWidget {
  const CovenantVAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) {
            final apiProvider = getIt<ApiProvider>();
            final notificationRepo = NotificationRepository(apiProvider);
            return NotificationBloc(notificationRepo);
          },
        ),
        // ✅ Global MessagesBloc — stays alive across screen navigations
        BlocProvider(
          create: (context) => getIt<MessagesBloc>(),
        ),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  Timer? _notificationTimer;
  bool _hasLoadedNotifications = false;
  bool _splashComplete = false;
  final SocketService _socketService = SocketService();
  OverlayEntry? _overlayEntry;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  void _showNotificationBanner(String title, String body) {
    _overlayEntry?.remove();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 70,
        right: 16,
        width: 380,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset((1 - value) * 400, 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      
      Future.delayed(const Duration(seconds: 5), () {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  void _setupAuthListener() {
    final authBloc = context.read<AuthBloc>();
    
    authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated && !_hasLoadedNotifications) {
        _hasLoadedNotifications = true;
        
        _socketService.onNotification = _showNotificationBanner;
        
        context.read<NotificationBloc>()
          ..add(LoadNotifications())
          ..add(LoadUnreadCount());
        
        final userId = authState.user.id;
        _socketService.connect(userId);
        
        final apiProvider = getIt<ApiProvider>();
        apiProvider.warmUp([
          '/dashboard/va',
          '/tasks/my-tasks',
          '/timecard/entries',
          '/messages',
          '/notifications',
        ]);
        
        _notificationTimer = Timer.periodic(
          const Duration(seconds: 30),
          (timer) {
            if (mounted) {
              context.read<NotificationBloc>().add(LoadUnreadCount());
            }
          },
        );
      } else if (authState is! AuthAuthenticated) {
        _hasLoadedNotifications = false;
        _notificationTimer?.cancel();
        _notificationTimer = null;
        _socketService.disconnect();
        
        final apiProvider = getIt<ApiProvider>();
        apiProvider.clearCache();
        
        if (_splashComplete) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _socketService.disconnect();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CVA Desktop',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) {
          _splashComplete = true;
          return _buildHome(context);
        },
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => BlocProvider(
              create: (context) => getIt<DashboardBloc>()
                ..add(const DashboardLoadRequested()),
              child: const MainLayout(
                currentRoute: 'dashboard',
                child: DashboardScreen(),
              ),
            ),
        '/tasks': (context) => BlocProvider(
              create: (context) => getIt<DashboardBloc>()
                ..add(const DashboardLoadRequested()),
              child: const MainLayout(
                currentRoute: 'tasks',
                child: MyTasksScreen(),
              ),
            ),
        // ✅ NEW: Notes route
        '/notes': (context) => BlocProvider(
              create: (context) => getIt<NotesBloc>(),
              child: const MainLayout(
                currentRoute: 'notes',
                child: NotesScreen(),
              ),
            ),
        '/messages': (context) {
          context.read<MessagesBloc>().add(const MessagesLoadRequested());
          return const MainLayout(
            currentRoute: 'messages',
            child: MessagesScreen(),
          );
        },
        '/timecard': (context) {
          return BlocProvider(
            create: (context) => getIt<TimecardBloc>(),
            child: const MainLayout(
              currentRoute: 'timecard',
              child: TimecardScreen(
                clientId: '',
              ),
            ),
          );
        },
        '/profile': (context) => const MainLayout(
              currentRoute: 'profile',
              child: ProfileScreen(),
            ),
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (state is AuthAuthenticated) {
          return BlocProvider(
            create: (context) => getIt<DashboardBloc>()
              ..add(const DashboardLoadRequested()),
            child: const MainLayout(
              currentRoute: 'dashboard',
              child: DashboardScreen(),
            ),
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}