import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/datasources/patient_remote_datasource.dart';
import 'data/repositories/patient_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/get_all_patients_usecase.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/doctor_viewmodel.dart';

void main() {
  // Thực hiện Dependency Injection thủ công tại đây
  final httpClient = http.Client();
  final remoteDataSource = AuthRemoteDataSource(httpClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
  final loginUseCase = LoginUseCase(authRepository);

  final patientRemoteDataSource = PatientRemoteDataSourceImpl(httpClient);
  final patientRepository = PatientRepositoryImpl(
    remoteDataSource: patientRemoteDataSource,
  );
  final getAllPatientsUseCase = GetAllPatientsUseCase(patientRepository);

  final authViewModel = AuthViewModel(
    loginUseCase: loginUseCase,
    authRepository: authRepository,
  );

  final doctorViewModel = DoctorViewModel(
    getAllPatientsUseCase: getAllPatientsUseCase,
  );

  final appRouter = AppRouter(authViewModel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: doctorViewModel),
      ],
      child: MyApp(appRouter: appRouter),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({required this.appRouter, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.router,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    );
  }
}
