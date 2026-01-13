import 'package:get_it/get_it.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/timecard_repository.dart'; // ← NEW
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../../presentation/messages/bloc/messages_bloc.dart';
import '../../presentation/timecard/bloc/timecard_bloc.dart'; // ← NEW

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

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(
      storageProvider: getIt<StorageProvider>(),
    ),
  );

  getIt.registerLazySingleton<ClientRepository>(
    () => ClientRepository(
      getIt<ApiProvider>(),
    ),
  );

  // ← NEW: Timecard Repository
  getIt.registerLazySingleton<TimecardRepository>(
    () => TimecardRepository(
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

  // ← NEW: Timecard BLoC
  getIt.registerFactory<TimecardBloc>(
    () => TimecardBloc(
      timecardRepository: getIt<TimecardRepository>(),
    ),
  );
}