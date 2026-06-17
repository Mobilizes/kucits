import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/env.dart';

class StorageService {
  static const String _apiKey = Env.imgbbApiKey;

  Future<String?> uploadPostPhoto(String postId, File file, int index) async {
    return _uploadToImgBB(file);
  }

  Future<String?> uploadCatIcon(String catId, File file) async {
    return _uploadToImgBB(file);
  }

  Future<String?> _uploadToImgBB(File file) async {
    try {
      // Compress the image before uploading
      final compressedFile = await _compressImage(file);
      if (compressedFile == null) return null;

      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', compressedFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonDecoded = json.decode(responseData);
        final String? url = jsonDecoded['data']['url'];
        return url;
      }
      return null;
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
