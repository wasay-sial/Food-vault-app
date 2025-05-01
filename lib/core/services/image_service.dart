import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);

  @override
  String toString() => message;
}

class ImageService {
  static const String imgbbApiKey = '520f83bc75ec741f693b7632fa11ddfd';
  static const String imgbbApiUrl = 'https://api.imgbb.com/1/upload';
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      throw ImageUploadException('Failed to pick image: $e');
    }
  }

  // Upload image to ImgBB with progress tracking
  Future<String?> uploadImage(
    XFile imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(imgbbApiUrl),
        body: {'key': imgbbApiKey, 'image': base64Image},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['url'];
        } else {
          final errorMessage =
              responseData['error']?.toString() ?? 'Unknown error occurred';
          throw ImageUploadException('Failed to upload image: $errorMessage');
        }
      } else {
        throw ImageUploadException(
          'Failed to upload image: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ImageUploadException('Failed to upload image: $e');
    }
  }

  // Helper method to handle both picking and uploading
  Future<String?> pickAndUploadImage(
    ImageSource source, {
    Function(double)? onProgress,
  }) async {
    try {
      // Pick image
      final XFile? pickedImage = await pickImage(source);
      if (pickedImage == null) return null;

      // Upload image
      return await uploadImage(pickedImage, onProgress: onProgress);
    } catch (e) {
      rethrow;
    }
  }
}
