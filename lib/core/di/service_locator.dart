import 'package:get_it/get_it.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/timecard_repository.dart';
import '../../data/repositories/stripe_repository.dart'; // ← NEW
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../../presentation/messages/bloc/messages_bloc.dart';
import '../../presentation/timecard/bloc/timecard_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Providers
  getIt.registerLazySingleton<ApiProvider>(() => ApiProvider());
  getIt.registerLazySingleton<StorageProvider>(() => StorageProvider());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiProvider: getIt<ApiProvider>(),
      storageProvider: getIt<StorageProvider>(),
    ),
  );

  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepository(
      apiProvider: getIt<ApiProvider>(),
    ),
  );

  getIt.registerLazySingleton<MessageRepository>(
    () => MessageRepository(
      apiProvider: getIt<ApiProvider>(),
    ),
  );

  // ✅ FIXED: Now includes ApiProvider!
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(
      apiProvider: getIt<ApiProvider>(),
      storageProvider: getIt<StorageProvider>(),
    ),
  );

  getIt.registerLazySingleton<ClientRepository>(
    () => ClientRepository(
      getIt<ApiProvider>(),
    ),
  );

  getIt.registerLazySingleton<TimecardRepository>(
    () => TimecardRepository(
      apiProvider: getIt<ApiProvider>(),
    ),
  );

  // ✅ NEW: Stripe Repository
  getIt.registerLazySingleton<StripeRepository>(
    () => StripeRepository(
      apiProvider: getIt<ApiProvider>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(taskRepository: getIt<TaskRepository>()),
  );

  getIt.registerFactory<MessagesBloc>(
    () => MessagesBloc(messageRepository: getIt<MessageRepository>()),
  );

  getIt.registerFactory<TimecardBloc>(
    () => TimecardBloc(
      timecardRepository: getIt<TimecardRepository>(),
    ),
  );
}