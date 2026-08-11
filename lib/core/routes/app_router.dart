import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/toast_service.dart';
import '../../presentation/pages/landing/landing_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/reset_password_page.dart';
import '../../presentation/pages/auth/change_password_page.dart';
import '../../presentation/pages/doctor/doctor_homepage.dart';
import '../../presentation/pages/admin/admin_homepage.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class AppRouter {
  final AuthViewModel authViewModel;

  AppRouter(this.authViewModel);

  late final GoRouter router = GoRouter(
    navigatorKey: AppToast.navigatorKey,
    initialLocation: '/',
    refreshListenable: authViewModel,
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) =>
            ResetPasswordPage(email: state.extra as String?),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/doctor',
        name: 'doctor',
        builder: (context, state) => const DoctorHomepage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminHomepage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final user = authViewModel.currentUser;
      final isLoggedIn = user != null;
      final isFirstTimeLogin = authViewModel.isFirstTimeLogin;
      final loc = state.matchedLocation;

      // Các trang public — không cần đăng nhập
      final isPublicRoute =
          loc == '/' ||
          loc == '/login' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/change-password';

      // Đang ở change-password — cho phép nếu đang trong luồng first-time login
      if (loc == '/change-password') {
        if (isFirstTimeLogin) return null; // OK
        if (!isLoggedIn) return '/login'; // Không có context → về login
        return null;
      }

      // Nếu backend yêu cầu đổi mật khẩu lần đầu → bắt buộc redirect
      if (isFirstTimeLogin && loc != '/change-password') {
        return '/change-password';
      }

      if (!isLoggedIn && !isPublicRoute) return '/login';

      if (isLoggedIn && loc == '/login') {
        if (user.isAdmin) return '/admin';
        return '/doctor';
      }

      if (isLoggedIn && loc.startsWith('/admin') && !user.isAdmin) {
        return '/doctor';
      }

      if (isLoggedIn && loc.startsWith('/doctor') && user.isAdmin) {
        return '/admin';
      }

      return null;
    },
  );
}
