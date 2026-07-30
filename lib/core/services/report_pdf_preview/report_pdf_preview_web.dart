// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Future<void> showReportPdfPreviewDialog(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  Future<void> Function()? onDownload,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final viewType =
      'report-pdf-preview-${DateTime.now().microsecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    return html.IFrameElement()
      ..src = url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;
  });

  try {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 980,
          height: 720,
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onDownload != null)
                      IconButton(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_outlined),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          hoverColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        tooltip: 'Tải báo cáo',
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
              ),
              Expanded(child: HtmlElementView(viewType: viewType)),
            ],
          ),
        ),
      ),
    );
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
