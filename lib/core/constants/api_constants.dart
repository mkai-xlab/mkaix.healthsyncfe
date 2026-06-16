class ApiConstants {
  static const String baseUrl = 'https://api.vietnguyendang.xyz/api/v1';
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String forgotPasswordEndpoint = '$baseUrl/auth/forgot-password';
  static const String resetPasswordEndpoint = '$baseUrl/auth/reset-password';
  static const String changePasswordEndpoint = '$baseUrl/auth/change-password';
  static const String patientsEndpoint = '$baseUrl/patients';
  static const String userAccountsEndpoint = '$baseUrl/users';

  // doctors endpoints
  static const String doctorsEndpoint = '$baseUrl/doctors';
  static const String createDoctorsEndpoint = '$baseUrl/doctors';
}
