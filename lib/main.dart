import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/usecases/login_usecase.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';

void main() {
  // Thực hiện Dependency Injection thủ công tại đây
  final httpClient = http.Client();
  final remoteDataSource = AuthRemoteDataSource(httpClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
  final loginUseCase = LoginUseCase(authRepository);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        loginUseCase: loginUseCase,
        authRepository: authRepository,
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginPage(),
    );
  }
}
