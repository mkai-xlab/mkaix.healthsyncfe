import 'package:flutter/material.dart';

class ExaminationStatusUtils {
  static const String aiProcessing = 'AI_PROCESSING';
  static const String needVerify = 'NEED_VERIFY';
  static const String verified = 'VERIFIED';
  static const String reportGenerated = 'REPORT_GENERATED';
  static const String reportExported = 'REPORT_EXPORTED';

  static String normalize(String status) => status.trim().toUpperCase();

  static String display(String status) {
    switch (normalize(status)) {
      case aiProcessing:
        return 'Đang phân tích';
      case needVerify:
        return 'Cần xác nhận';
      case verified:
        return 'Đã xác nhận';
      case reportGenerated:
        return 'Đã tạo báo cáo';
      case reportExported:
        return 'Đã xuất báo cáo';
      default:
        return status.trim().isEmpty ? 'Không rõ' : status;
    }
  }

  static Color color(String status) {
    switch (normalize(status)) {
      case aiProcessing:
        return Colors.white;
      case needVerify:
        return const Color(0xFFFACC15);
      case verified:
        return const Color(0xFF38BDF8);
      case reportGenerated:
      case reportExported:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF718096);
    }
  }

  static Color foregroundColor(String status) {
    return normalize(status) == aiProcessing
        ? const Color(0xFF1A2B3C)
        : color(status);
  }

  static Color backgroundColor(String status) {
    final normalized = normalize(status);
    if (normalized == aiProcessing) return Colors.white;
    return color(status).withValues(alpha: 0.12);
  }

  static Border? border(String status) {
    return normalize(status) == aiProcessing
        ? Border.all(color: const Color(0xFFE2E8F0))
        : null;
  }
}
