import 'dart:typed_data';

import 'file_download_mobile.dart'
    if (dart.library.html) 'file_download_web.dart' as platform;

/// Cross-platform download/export handler
class FileDownloadService {
  FileDownloadService._();

  static Future<void> downloadFile({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    await platform.downloadFileUniversal(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
