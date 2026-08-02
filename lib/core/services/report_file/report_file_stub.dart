import 'dart:typed_data';

Future<void> previewPdf(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('Preview báo cáo chỉ được hỗ trợ trên web.');
}

Future<void> downloadPdf(Uint8List bytes, {required String fileName}) async {
  throw UnsupportedError('Tải báo cáo chỉ được hỗ trợ trên web.');
}
