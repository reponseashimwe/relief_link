import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final cloudinary = CloudinaryPublic(
    'dxeepn9qa',  // Cloud name
    'ml_default', // Upload preset
    cache: false,
  );

  static Future<String> uploadImage(File image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> images) async {
    try {
      List<String> urls = [];
      for (var image in images) {
        String url = await uploadImage(image);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }
} 