import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'report_pdf_preview/report_pdf_preview_stub.dart'
    if (dart.library.html) 'report_pdf_preview/report_pdf_preview_web.dart'
    as preview;

Future<void> showReportPdfPreviewDialog(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  Future<void> Function()? onDownload,
}) {
  return preview.showReportPdfPreviewDialog(
    context,
    bytes: bytes,
    fileName: fileName,
    onDownload: onDownload,
  );
}
