import 'dart:typed_data';

import 'report_file/report_file_stub.dart'
    if (dart.library.html) 'report_file/report_file_web.dart'
    as report_file;

class ReportFileService {
  Future<void> previewPdf(Uint8List bytes, {required String fileName}) {
    return report_file.previewPdf(bytes, fileName: fileName);
  }

  Future<void> downloadPdf(Uint8List bytes, {required String fileName}) {
    return report_file.downloadPdf(bytes, fileName: fileName);
  }
}
