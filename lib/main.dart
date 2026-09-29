import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/di/service_locator.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/auth/bloc/auth_state.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/messages/bloc/messages_bloc.dart';
import 'presentation/notes/bloc/notes_bloc.dart';
import 'presentation/notes/bloc/notes_event.dart';
import 'presentation/notes/bloc/notes_state.dart';
import 'presentation/announcements/screens/announcements_screen.dart';
import 'presentation/dashboard/screens/dashboard_screen.dart';
import 'presentation/dashboard/widgets/my_clients_section.dart';
import 'presentation/tasks/screens/my_tasks_screen.dart';
import 'data/repositories/announcement_repository.dart';
import 'presentation/shared/layouts/main_layout.dart';
import 'presentation/shared/widgets/connecting_banner.dart';
import 'presentation/notifications/bloc/notification_bloc.dart';
import 'presentation/notifications/bloc/notification_event.dart';
import 'presentation/splash/splash_screen.dart';
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

  // Read the last visited screen once, up front, instead of in a
  // FutureBuilder that re-ran on every rebuild of the home route.
  String? lastRoute;
  try {
    final prefs = await SharedPreferences.getInstance();
    lastRoute = prefs.getString('last_route');
  } catch (_) {}

  runApp(CovenantVAApp(initialLastRoute: lastRoute));
}

class CovenantVAApp extends StatelessWidget {
  /// Screen to restore after sign-in (from `last_route`), if any.
  final String? initialLastRoute;

  const CovenantVAApp({super.key, this.initialLastRoute});

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
      child: _AppContent(initialLastRoute: initialLastRoute),
    );
  }
}

class _AppContent extends StatefulWidget {
  final String? initialLastRoute;

  const _AppContent({this.initialLastRoute});

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
  static const _restorableRoutes = {
    'tasks', 'notes', 'messages', 'timecard', 'crm', 'lead-tracker',
    'archive', 'announcements', 'profile',
  };

  /// `last_route` as read at startup. Consumed by the first authenticated
  /// home build; cleared on logout so the next sign-in starts on the dashboard.
  String? _pendingLastRoute;

  /// Screen the current signed-in session's shell opened on (stable across
  /// rebuilds of the home route).
  String? _homeRoute;

  @override
  void initState() {
    super.initState();
    _pendingLastRoute = widget.initialLastRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  /// Warms the notes + announcements caches after sign-in. On a cold backend
  /// the first attempt can fail; retry with exponential backoff (5s, 10s).
  /// An empty notes list is a valid result, not a failure.
  Future<void> _preloadData({int attempt = 1}) async {
    const maxAttempts = 3;
    const baseRetryDelay = Duration(seconds: 5);

    final notesBloc = getIt<NotesBloc>();
    bool notesOk() {
      final s = notesBloc.state;
      return s is NotesLoaded && s.errorMessage == null;
    }

    // Pre-load notes (only if a previous attempt didn't already succeed)
    if (!notesOk()) {
      notesBloc.add(const NotesLoadRequested());
    }

    // Pre-load announcements
    bool announcementsOk = !AnnouncementsScreen.isCacheStale(const Duration(minutes: 5));
    if (!announcementsOk) {
      try {
        final announcements = await getIt<AnnouncementRepository>().getPublishedAnnouncements();
        AnnouncementsScreen.updateCache(announcements);
        announcementsOk = true;
      } catch (_) {
        // Will retry below
      }
    }

    // Wait for the notes request to settle (success or error).
    if (!notesOk()) {
      try {
        await notesBloc.stream
            .firstWhere((s) => s is NotesLoaded || s is NotesError)
            .timeout(const Duration(seconds: 35));
      } catch (_) {}
    }

    if ((!notesOk() || !announcementsOk) && attempt < maxAttempts && mounted) {
      await Future.delayed(baseRetryDelay * (1 << (attempt - 1)));
      if (mounted && _hasLoadedNotifications) {
        _preloadData(attempt: attempt + 1);
      }
    }
  }

  void _setupAuthListener() {
    final authBloc = context.read<AuthBloc>();

    authBloc.stream.listen((authState) {
      if (!mounted) return;
      if (authState is AuthAuthenticated && !_hasLoadedNotifications) {
        _hasLoadedNotifications = true;

        context.read<NotificationBloc>()
          ..add(LoadNotifications())
          ..add(LoadUnreadCount());

        final userId = authState.user.id;
        _socketService.connect(userId, authState.token);

        // Initialize CallService with auth token
        final apiProvider = getIt<ApiProvider>();
        final token = apiProvider.authToken;
        if (token != null) {
          _callService.setAuthToken(token);
        }
        _callService.initialize();

        // Only endpoints whose cache keys match what the screens actually
        // request (same URL, no forceRefresh) — anything else is wasted work.
        apiProvider.warmUp([
          '/tasks',
          '/tasks/stats',
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
        // Screen-level caches must not leak into the next user's session.
        DashboardScreen.clearCache();
        MyTasksScreen.clearCache();
        MyClientsSection.clearCache();
        AnnouncementsScreen.clearCache();

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
      // Switch theme instantly. The default 200ms animated cross-fade rebuilds
      // the whole screen for ~12 frames, which on web reads as a page reload/flash.
      themeAnimationDuration: Duration.zero,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            CallOverlay(
              callService: _callService,
              child: child ?? const SizedBox.shrink(),
            ),
            // Cold-start hint; non-blocking (ignores pointer events).
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: ConnectingBanner()),
            ),
          ],
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
        // Deep links / direct named routes: each opens the persistent shell on
        // that screen. In-app navigation switches the shell's content instead
        // of pushing these (see MainLayout.navigateTo).
        for (final route in MainLayout.routes)
          '/$route': (context) => MainLayout(currentRoute: route),
      },
    );
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Only rebuild when the *kind* of auth state changes. A refreshed user
      // (AuthAuthenticated -> AuthAuthenticated) must not rebuild the home
      // route and remount the whole app shell.
      buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          // On (web) reload the app restarts at /home. Restore the last screen
          // the user was on instead of always dropping them on the dashboard.
          _homeRoute ??= _takeRestoredRoute();
          return MainLayout(currentRoute: _homeRoute!);
        }

        // Not authenticated (e.g. after logout) — forget the saved screen.
        _homeRoute = null;
        _pendingLastRoute = null;
        SharedPreferences.getInstance().then((p) => p.remove('last_route')).ignore();
        return const LoginScreen();
      },
    );
  }

  /// The screen to open the shell on for this session: the saved
  /// `last_route` (once), otherwise the dashboard.
  String _takeRestoredRoute() {
    final last = _pendingLastRoute;
    _pendingLastRoute = null;
    if (last != null && _restorableRoutes.contains(last)) return last;
    return 'dashboard';
  }
}
