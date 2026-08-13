import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:fe/core/constants/app_colors.dart';
import 'package:fe/core/routes/app_router.dart';
import 'package:fe/data/datasources/auth_remote_datasource.dart';
import 'package:fe/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:fe/data/repositories/admin_repository_impl.dart';
import 'package:fe/data/repositories/audit_log_repository_impl.dart';
import 'package:fe/data/repositories/auth_repository_impl.dart';
import 'package:fe/data/repositories/chat_repository_impl.dart';
import 'package:fe/data/repositories/dicom_repository_impl.dart';
import 'package:fe/data/repositories/doctor_profile_repository_impl.dart';
import 'package:fe/data/repositories/knowledge_document_repository_impl.dart';
import 'package:fe/data/repositories/notification_repository_impl.dart';
import 'package:fe/data/datasources/patient_remote_datasource.dart';
import 'package:fe/data/repositories/patient_repository_impl.dart';
import 'package:fe/data/datasources/examination_remote_datasource.dart';
import 'package:fe/data/repositories/examination_repository_impl.dart';
import 'package:fe/domain/usecases/create_doctor_usecase.dart';
import 'package:fe/domain/usecases/ask_chat_usecase.dart';
import 'package:fe/domain/usecases/change_password_usecase.dart';
import 'package:fe/domain/usecases/create_chat_session_usecase.dart';
import 'package:fe/domain/usecases/create_user_usecase.dart';
import 'package:fe/domain/usecases/forgot_password_usecase.dart';
import 'package:fe/domain/usecases/get_admin_dashboard_stats_usecase.dart';
import 'package:fe/domain/usecases/get_admin_roles_usecase.dart';
import 'package:fe/domain/usecases/get_audit_logs_usecase.dart';
import 'package:fe/domain/usecases/get_chat_session_messages_usecase.dart';
import 'package:fe/domain/usecases/get_chat_sessions_usecase.dart';
import 'package:fe/domain/usecases/login_usecase.dart';
import 'package:fe/domain/usecases/logout_usecase.dart';
import 'package:fe/domain/usecases/get_all_patients_usecase.dart';
import 'package:fe/domain/usecases/get_doctor_accounts_usecase.dart';
import 'package:fe/domain/usecases/get_doctor_profile_usecase.dart';
import 'package:fe/domain/usecases/get_patient_examinations_usecase.dart';
import 'package:fe/domain/usecases/get_knowledge_documents_usecase.dart';
import 'package:fe/domain/usecases/get_notifications_usecase.dart';
import 'package:fe/domain/usecases/get_unread_notifications_usecase.dart';
import 'package:fe/domain/usecases/mark_all_notifications_as_read_usecase.dart';
import 'package:fe/domain/usecases/mark_notification_as_read_usecase.dart';
import 'package:fe/domain/usecases/reset_password_usecase.dart';
import 'package:fe/domain/usecases/toggle_doctor_status_usecase.dart';
import 'package:fe/domain/usecases/update_chat_session_usecase.dart';
import 'package:fe/domain/usecases/update_doctor_profile_usecase.dart';
import 'package:fe/domain/usecases/upload_dicom_batch_usecase.dart';
import 'package:fe/domain/usecases/upload_dicom_zip_batch_usecase.dart';
import 'package:fe/domain/usecases/upload_doctor_avatar_usecase.dart';
import 'package:fe/domain/usecases/upload_knowledge_document_usecase.dart';
import 'package:fe/domain/usecases/upload_knowledge_documents_batch_usecase.dart';
import 'package:fe/domain/usecases/verify_dicom_upload_session_usecase.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/doctor_viewmodel.dart';
import 'package:fe/presentation/viewmodels/examination_viewmodel.dart';
import 'package:fe/data/datasources/admin_remote_datasource.dart';
import 'package:fe/data/datasources/admin_dashboard_remote_datasource.dart';
import 'package:fe/data/datasources/audit_log_remote_datasource.dart';
import 'package:fe/data/datasources/chat_remote_datasource.dart';
import 'package:fe/data/datasources/dicom_remote_datasource.dart';
import 'package:fe/data/datasources/doctor_profile_remote_datasource.dart';
import 'package:fe/data/datasources/knowledge_document_remote_datasource.dart';
import 'package:fe/data/datasources/notification_remote_datasource.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/presentation/viewmodels/admin_dashboard_viewmodel.dart';
import 'package:fe/presentation/viewmodels/audit_log_viewmodel.dart';
import 'package:fe/presentation/viewmodels/dicom_upload_viewmodel.dart';
import 'package:fe/presentation/viewmodels/doctor_profile_viewmodel.dart';
import 'package:fe/presentation/viewmodels/knowledge_document_viewmodel.dart';
import 'package:fe/presentation/viewmodels/notification_viewmodel.dart';
import 'package:fe/presentation/viewmodels/chat_viewmodel.dart';
import 'package:fe/presentation/widgets/ai_chat/ai_chat_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final httpClient = http.Client();

  // Auth
  final remoteDataSource = AuthRemoteDataSource(httpClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
  final loginUseCase = LoginUseCase(authRepository);

  // Patient
  final patientRemoteDataSource = PatientRemoteDataSourceImpl(httpClient);
  final patientRepository = PatientRepositoryImpl(
    remoteDataSource: patientRemoteDataSource,
  );
  final getAllPatientsUseCase = GetAllPatientsUseCase(patientRepository);

  // Examination
  final examinationRemoteDataSource = ExaminationRemoteDataSourceImpl(
    httpClient,
  );
  final examinationRepository = ExaminationRepositoryImpl(
    remoteDataSource: examinationRemoteDataSource,
  );
  final getPatientExaminationsUseCase = GetPatientExaminationsUseCase(
    examinationRepository,
  );

  // Admin
  final adminRemoteDataSource = AdminRemoteDataSourceImpl(httpClient);
  final adminRepository = AdminRepositoryImpl(
    remoteDataSource: adminRemoteDataSource,
  );
  final adminAccountViewModel = AdminAccountViewModel(
    getDoctorAccountsUseCase: GetDoctorAccountsUseCase(adminRepository),
    createDoctorUseCase: CreateDoctorUseCase(adminRepository),
    createUserUseCase: CreateUserUseCase(adminRepository),
    getRolesUseCase: GetAdminRolesUseCase(adminRepository),
    toggleDoctorStatusUseCase: ToggleDoctorStatusUseCase(adminRepository),
  );
  final adminDashboardRemoteDataSource = AdminDashboardRemoteDataSource(
    httpClient,
  );
  final adminDashboardRepository = AdminDashboardRepositoryImpl(
    remoteDataSource: adminDashboardRemoteDataSource,
  );
  final adminDashboardViewModel = AdminDashboardViewModel(
    GetAdminDashboardStatsUseCase(adminDashboardRepository),
  );

  // Audit logs
  final auditLogRemoteDataSource = AuditLogRemoteDataSource(httpClient);
  final auditLogRepository = AuditLogRepositoryImpl(
    remoteDataSource: auditLogRemoteDataSource,
  );
  final auditLogViewModel = AuditLogViewModel(
    GetAuditLogsUseCase(auditLogRepository),
  );

  // DICOM upload
  final dicomRemoteDataSource = DicomRemoteDataSourceImpl(httpClient);
  final dicomRepository = DicomRepositoryImpl(
    remoteDataSource: dicomRemoteDataSource,
  );
  final dicomUploadViewModel = DicomUploadViewModel(
    uploadBatchUseCase: UploadDicomBatchUseCase(dicomRepository),
    uploadZipBatchUseCase: UploadDicomZipBatchUseCase(dicomRepository),
    verifyUploadSessionUseCase: VerifyDicomUploadSessionUseCase(
      dicomRepository,
    ),
  );

  // Doctor profile
  final doctorProfileRemoteDataSource = DoctorProfileRemoteDataSource(
    httpClient,
  );
  final doctorProfileRepository = DoctorProfileRepositoryImpl(
    remoteDataSource: doctorProfileRemoteDataSource,
  );
  final doctorProfileViewModel = DoctorProfileViewModel(
    getProfileUseCase: GetDoctorProfileUseCase(doctorProfileRepository),
    updateProfileUseCase: UpdateDoctorProfileUseCase(doctorProfileRepository),
    uploadAvatarUseCase: UploadDoctorAvatarUseCase(doctorProfileRepository),
  );

  // Notifications
  final notificationRemoteDataSource = NotificationRemoteDataSource(httpClient);
  final notificationRepository = NotificationRepositoryImpl(
    remoteDataSource: notificationRemoteDataSource,
  );
  final notificationViewModel = NotificationViewModel(
    getNotificationsUseCase: GetNotificationsUseCase(notificationRepository),
    getUnreadNotificationsUseCase: GetUnreadNotificationsUseCase(
      notificationRepository,
    ),
    markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(
      notificationRepository,
    ),
    markAllNotificationsAsReadUseCase: MarkAllNotificationsAsReadUseCase(
      notificationRepository,
    ),
  );
  final chatRemoteDataSource = ChatRemoteDataSource(httpClient);
  final chatRepository = ChatRepositoryImpl(
    remoteDataSource: chatRemoteDataSource,
  );
  final chatViewModel = ChatViewModel(
    askChatUseCase: AskChatUseCase(chatRepository),
    getSessionsUseCase: GetChatSessionsUseCase(chatRepository),
    createSessionUseCase: CreateChatSessionUseCase(chatRepository),
    updateSessionUseCase: UpdateChatSessionUseCase(chatRepository),
    getSessionMessagesUseCase: GetChatSessionMessagesUseCase(chatRepository),
  );
  final knowledgeDocumentRemoteDataSource = KnowledgeDocumentRemoteDataSource(
    httpClient,
  );
  final knowledgeDocumentRepository = KnowledgeDocumentRepositoryImpl(
    remoteDataSource: knowledgeDocumentRemoteDataSource,
  );
  final knowledgeDocumentViewModel = KnowledgeDocumentViewModel(
    getDocumentsUseCase: GetKnowledgeDocumentsUseCase(
      knowledgeDocumentRepository,
    ),
    uploadDocumentUseCase: UploadKnowledgeDocumentUseCase(
      knowledgeDocumentRepository,
    ),
    uploadDocumentsBatchUseCase: UploadKnowledgeDocumentsBatchUseCase(
      knowledgeDocumentRepository,
    ),
  );

  // ViewModels
  final authViewModel = AuthViewModel(
    loginUseCase: loginUseCase,
    logoutUseCase: LogoutUseCase(authRepository),
    changePasswordUseCase: ChangePasswordUseCase(authRepository),
    forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
    resetPasswordUseCase: ResetPasswordUseCase(authRepository),
  );
  await authViewModel.restoreSession();
  final doctorViewModel = DoctorViewModel(
    getAllPatientsUseCase: getAllPatientsUseCase,
  );
  final examinationViewModel = ExaminationViewModel(
    getPatientExaminationsUseCase: getPatientExaminationsUseCase,
  );

  final appRouter = AppRouter(authViewModel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: doctorViewModel),
        ChangeNotifierProvider.value(value: examinationViewModel),
        ChangeNotifierProvider.value(value: adminAccountViewModel),
        ChangeNotifierProvider.value(value: adminDashboardViewModel),
        ChangeNotifierProvider.value(value: auditLogViewModel),
        ChangeNotifierProvider.value(value: dicomUploadViewModel),
        ChangeNotifierProvider.value(value: doctorProfileViewModel),
        ChangeNotifierProvider.value(value: notificationViewModel),
        ChangeNotifierProvider.value(value: chatViewModel),
        ChangeNotifierProvider.value(value: knowledgeDocumentViewModel),
      ],
      child: MyApp(appRouter: appRouter),
    ),
  );
}

class MyApp extends StatelessWidget {
  static const double _compactTextScale = 0.9;

  final AppRouter appRouter;

  const MyApp({required this.appRouter, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final currentTextScale = mediaQuery.textScaler.scale(1);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(currentTextScale * _compactTextScale),
          ),
          child: _RealtimeNotificationConnector(
            child: AiChatWidget(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface1,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surface1,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface3,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(34, 34),
            padding: const EdgeInsets.all(6),
          ),
        ),
      ),
    );
  }
}

class _RealtimeNotificationConnector extends StatefulWidget {
  final Widget child;

  const _RealtimeNotificationConnector({required this.child});

  @override
  State<_RealtimeNotificationConnector> createState() =>
      _RealtimeNotificationConnectorState();
}

class _RealtimeNotificationConnectorState
    extends State<_RealtimeNotificationConnector> {
  String? _connectedToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token ?? '';
    final notificationVm = context.read<NotificationViewModel>();

    if (token.trim().isEmpty) {
      if (_connectedToken != null) {
        _resetSessionScopedState();
        _connectedToken = null;
      }
      return;
    }

    if (_connectedToken == token) return;
    if (_connectedToken != null) {
      _resetSessionScopedState();
    }
    _connectedToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _connectedToken != token) return;
      notificationVm.connectRealtime(token);
    });
  }

  void _resetSessionScopedState() {
    context.read<DoctorViewModel>().reset();
    context.read<ExaminationViewModel>().clear();
    context.read<AdminAccountViewModel>().reset();
    context.read<AdminDashboardViewModel>().reset();
    context.read<AuditLogViewModel>().reset();
    context.read<DicomUploadViewModel>().clear();
    context.read<DicomUploadViewModel>().clearUploadedFiles();
    context.read<DoctorProfileViewModel>().clear();
    context.read<NotificationViewModel>().reset();
    context.read<ChatViewModel>().reset();
    context.read<KnowledgeDocumentViewModel>().reset();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
