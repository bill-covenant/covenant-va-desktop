import 'package:get_it/get_it.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/firebase_message_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/timecard_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/crm_repository.dart';
import '../../data/repositories/lead_repository.dart';
import '../../data/repositories/blog_repository.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/crm/bloc/crm_bloc.dart';
import '../../presentation/lead_tracker/bloc/lead_tracker_bloc.dart';
import '../../presentation/dashboard/bloc/dashboard_bloc.dart';
import '../../presentation/messages/bloc/messages_bloc.dart';
import '../../presentation/timecard/bloc/timecard_bloc.dart';
import '../../presentation/notes/bloc/notes_bloc.dart';

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

  getIt.registerLazySingleton<FirebaseMessageRepository>(
    () => FirebaseMessageRepository(),
  );

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

  // ✅ NEW: Note Repository
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepository(getIt<ApiProvider>()),
  );

  getIt.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepository(getIt<ApiProvider>()),
  );

  getIt.registerLazySingleton<CrmRepository>(
    () => CrmRepository(getIt<ApiProvider>()),
  );

  getIt.registerLazySingleton<LeadRepository>(
    () => LeadRepository(getIt<ApiProvider>()),
  );

  getIt.registerLazySingleton<BlogRepository>(
    () => BlogRepository(getIt<ApiProvider>()),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      taskRepository: getIt<TaskRepository>(),
      timecardRepository: getIt<TimecardRepository>(),
    ),
  );

  getIt.registerLazySingleton<MessagesBloc>(
    () => MessagesBloc(messageRepository: getIt<FirebaseMessageRepository>()),
  );

  getIt.registerFactory<TimecardBloc>(
    () => TimecardBloc(
      timecardRepository: getIt<TimecardRepository>(),
    ),
  );

  // ✅ Notes BLoC — singleton so cache persists across navigations
  getIt.registerLazySingleton<NotesBloc>(
    () => NotesBloc(noteRepository: getIt<NoteRepository>()),
  );

  getIt.registerFactory<CrmBloc>(
    () => CrmBloc(crmRepository: getIt<CrmRepository>()),
  );

  getIt.registerFactory<LeadTrackerBloc>(
    () => LeadTrackerBloc(leadRepository: getIt<LeadRepository>()),
  );
}