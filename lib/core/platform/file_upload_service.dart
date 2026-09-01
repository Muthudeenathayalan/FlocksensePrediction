import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  FileUploadService._();

  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;

  /// Uploads raw bytes to Firebase Storage
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String pathPrefix,
    String? contentType,
  }) async {
    final user = _auth.currentUser;
    final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = user != null
        ? 'users/${user.uid}/$pathPrefix/$fileId-$safeFileName'
        : 'public/$pathPrefix/$fileId-$safeFileName';

    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType ?? _detectMimeType(fileName),
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'ownerUid': user?.uid ?? 'anonymous',
        },
      ),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads an XFile (from image_picker or file_picker) across any platform
  static Future<String> uploadXFile({
    required XFile xFile,
    required String pathPrefix,
  }) async {
    final bytes = await xFile.readAsBytes();
    final mimeType = xFile.mimeType ?? _detectMimeType(xFile.name);
    return uploadBytes(
      bytes: bytes,
      fileName: xFile.name,
      pathPrefix: pathPrefix,
      contentType: mimeType,
    );
  }

  static String _detectMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
