import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:fe/core/constants/app_colors.dart';
import 'package:fe/core/routes/app_router.dart';
import 'package:fe/data/datasources/auth_remote_datasource.dart';
import 'package:fe/data/repositories/auth_repository_impl.dart';
import 'package:fe/data/datasources/patient_remote_datasource.dart';
import 'package:fe/data/repositories/patient_repository_impl.dart';
import 'package:fe/data/datasources/examination_remote_datasource.dart';
import 'package:fe/data/repositories/examination_repository_impl.dart';
import 'package:fe/domain/usecases/login_usecase.dart';
import 'package:fe/domain/usecases/get_all_patients_usecase.dart';
import 'package:fe/domain/usecases/get_patient_examinations_usecase.dart';
import 'package:fe/presentation/viewmodels/auth_viewmodel.dart';
import 'package:fe/presentation/viewmodels/doctor_viewmodel.dart';
import 'package:fe/presentation/viewmodels/examination_viewmodel.dart';
import 'package:fe/data/datasources/admin_remote_datasource.dart';
import 'package:fe/data/datasources/dicom_remote_datasource.dart';
import 'package:fe/data/datasources/doctor_profile_remote_datasource.dart';
import 'package:fe/data/datasources/notification_remote_datasource.dart';
import 'package:fe/presentation/viewmodels/admin_account_viewmodel.dart';
import 'package:fe/presentation/viewmodels/dicom_upload_viewmodel.dart';
import 'package:fe/presentation/viewmodels/doctor_profile_viewmodel.dart';
import 'package:fe/presentation/viewmodels/notification_viewmodel.dart';

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
  final adminAccountViewModel = AdminAccountViewModel(adminRemoteDataSource);

  // DICOM upload
  final dicomRemoteDataSource = DicomRemoteDataSourceImpl(httpClient);
  final dicomUploadViewModel = DicomUploadViewModel(dicomRemoteDataSource);

  // Doctor profile
  final doctorProfileRemoteDataSource = DoctorProfileRemoteDataSource(
    httpClient,
  );
  final doctorProfileViewModel = DoctorProfileViewModel(
    doctorProfileRemoteDataSource,
  );

  // Notifications
  final notificationRemoteDataSource = NotificationRemoteDataSource(httpClient);
  final notificationViewModel = NotificationViewModel(
    notificationRemoteDataSource,
  );

  // ViewModels
  final authViewModel = AuthViewModel(
    loginUseCase: loginUseCase,
    authRepository: authRepository,
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
        ChangeNotifierProvider.value(value: dicomUploadViewModel),
        ChangeNotifierProvider.value(value: doctorProfileViewModel),
        ChangeNotifierProvider.value(value: notificationViewModel),
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
          child: child ?? const SizedBox.shrink(),
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
