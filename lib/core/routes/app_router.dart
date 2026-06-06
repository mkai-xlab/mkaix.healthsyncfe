import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/doctor/doctor_homepage.dart';
import '../../presentation/pages/admin/admin_homepage.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class AppRouter {
  final AuthViewModel authViewModel;

  AppRouter(this.authViewModel);

  // Khởi tạo GoRouter
  late final GoRouter router = GoRouter(
    // 1. Trang đầu tiên xuất hiện khi mở app
    initialLocation: '/login',

    // 2. Lắng nghe AuthViewModel. Khi người dùng login/logout (notifyListeners được gọi),
    // GoRouter sẽ tự động chạy lại hàm redirect bên dưới để kiểm tra quyền.
    refreshListenable: authViewModel,

    // 3. Khai báo danh sách các tuyến đường (Routes) trong app
    routes: [
      GoRoute(
        path: '/login',
        name: 'login', // Đặt tên để điều hướng bằng tên nếu muốn
        builder: (context, state) => const LoginPage(),
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

    // 4. BỘ LỌC PHÂN QUYỀN (ROUTE GUARD / AUTHORIZATION)
    redirect: (BuildContext context, GoRouterState state) {
      final user = authViewModel.currentUser;
      final isLoggedIn = user != null;

      // Lấy đường dẫn hiện tại mà người dùng đang muốn truy cập
      final currentLocation = state.matchedLocation;

      final isGoingToLogin = currentLocation == '/login';
      final isGoingToDoctor = currentLocation.startsWith('/doctor');
      final isGoingToAdmin = currentLocation.startsWith('/admin');

      // TH 1: Nếu CHƯA đăng nhập mà cố tình vào các trang bên trong (doctor, admin...) -> Đá về /login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // TH 2: Nếu ĐÃ đăng nhập thành công rồi mà vẫn gõ URL /login
      if (isLoggedIn && isGoingToLogin) {
        // Điều hướng dựa trên vai trò của người dùng
        if (user!.isAdmin) {
          return '/admin';
        } else if (user.isDoctor) {
          return '/doctor';
        }
        return '/login';
      }

      // TH 3: PHÂN QUYỀN - Nếu là DOCTOR nhưng cố gắng truy cập /admin -> Đẩy về /doctor
      if (isLoggedIn && isGoingToAdmin && !user!.isAdmin) {
        return '/doctor';
      }

      // TH 4: PHÂN QUYỀN - Nếu là ADMIN nhưng cố gắng truy cập /doctor -> Đẩy về /admin
      if (isLoggedIn && isGoingToDoctor && !user!.isDoctor) {
        return '/admin';
      }

      // Trả về null nghĩa là hợp lệ, cho phép đi tiếp vào trang mong muốn
      return null;
    },
  );
}
