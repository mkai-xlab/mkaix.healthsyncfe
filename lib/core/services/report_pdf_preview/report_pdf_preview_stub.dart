import 'dart:typed_data';

import 'package:flutter/material.dart';

Future<void> showReportPdfPreviewDialog(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  Future<void> Function()? onDownload,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xem báo cáo'),
      content: const Text('Xem trước PDF chỉ được hỗ trợ trên web.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}
