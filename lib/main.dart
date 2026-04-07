import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/di/service_locator.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/dashboard/bloc/dashboard_event.dart';
import 'presentation/dashboard/screens/dashboard_screen.dart';
import 'presentation/tasks/screens/my_tasks_screen.dart';
import 'presentation/tasks/screens/archive_screen.dart';
import 'presentation/messages/screens/messages_screen.dart';
import 'presentation/messages/bloc/messages_bloc.dart';
import 'presentation/messages/bloc/messages_event.dart';
import 'presentation/notes/screens/notes_screen.dart';
import 'presentation/notes/bloc/notes_bloc.dart';
import 'presentation/notes/bloc/notes_event.dart';
import 'presentation/notes/bloc/notes_state.dart';
import 'presentation/profile/screens/profile_screen.dart';
import 'presentation/announcements/screens/announcements_screen.dart';
import 'data/repositories/announcement_repository.dart';
import 'presentation/shared/layouts/main_layout.dart';
import 'presentation/notifications/bloc/notification_bloc.dart';
import 'presentation/notifications/bloc/notification_event.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/timecard/bloc/timecard_bloc.dart';
import 'presentation/timecard/screens/timecard_screen.dart';
import 'data/repositories/notification_repository.dart';
import 'data/providers/api_provider.dart';
import 'services/socket_service.dart';
import 'services/call_service.dart';
import 'presentation/call/widgets/call_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // usePathUrlStrategy(); // Using hash routing for reliable page refresh
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  final CallService _callService = CallService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  Future<void> _preloadData({int attempt = 1}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 5);

    // Pre-load notes
    getIt<NotesBloc>().add(const NotesLoadRequested());

    // Pre-load announcements
    try {
      final announcements = await getIt<AnnouncementRepository>().getPublishedAnnouncements();
      AnnouncementsScreen.updateCache(announcements);
    } catch (_) {
      // Will retry below
    }

    // Check if notes loaded successfully
    await Future.delayed(const Duration(seconds: 2));
    final notesState = getIt<NotesBloc>().state;
    final notesFailed = notesState is! NotesLoaded || (notesState as NotesLoaded).notes.isEmpty;

    if (notesFailed && attempt < maxRetries) {
      await Future.delayed(retryDelay);
      if (mounted) {
        _preloadData(attempt: attempt + 1);
      }
    }
  }

  void _setupAuthListener() {
    final authBloc = context.read<AuthBloc>();
    
    authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated && !_hasLoadedNotifications) {
        _hasLoadedNotifications = true;

        context.read<NotificationBloc>()
          ..add(LoadNotifications())
          ..add(LoadUnreadCount());

        final userId = authState.user.id;
        _socketService.connect(userId);

        // Initialize CallService with auth token
        final apiProvider = getIt<ApiProvider>();
        final token = apiProvider.authToken;
        if (token != null) {
          _callService.setAuthToken(token);
        }
        _callService.initialize();

        apiProvider.warmUp([
          '/tasks',
          '/tasks/stats',
          '/timecard/entries',
          '/conversations',
          '/notifications',
          '/notes',
          '/announcements/published',
        ]);

        // Pre-load data with retry on cold start failure
        _preloadData();
        
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider();
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CVA Desktop',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return CallOverlay(
          callService: _callService,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/home',
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
        // ✅ Notes route — uses global singleton BLoC
        '/notes': (context) => BlocProvider.value(
              value: getIt<NotesBloc>(),
              child: const MainLayout(
                currentRoute: 'notes',
                child: NotesScreen(),
              ),
            ),
        '/messages': (context) => const MainLayout(
              currentRoute: 'messages',
              child: MessagesScreen(),
            ),
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
        '/archive': (context) => const MainLayout(
              currentRoute: 'archive',
              child: ArchiveScreen(),
            ),
        '/announcements': (context) => const MainLayout(
              currentRoute: 'announcements',
              child: AnnouncementsScreen(),
            ),
      },
    );
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