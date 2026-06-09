import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String?> uploadPostPhoto(String postId, File file, int index) async {
    try {
      // Compress the image before uploading
      final compressedFile = await _compressImage(file);
      if (compressedFile == null) return null;

      final ref = _storage.ref().child('posts/$postId/$index.jpg');
      final uploadTask = await ref.putFile(compressedFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      // Return the original file if compression fails
      return file;
    }
  }
}
