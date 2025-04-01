import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;
  static final _uuid = Uuid();

  static Future<String> uploadFile(dynamic file) async {
    if (file == null) throw Exception('No file provided');

    try {
      // Generate a unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('uploads/$fileName');
      
      late final UploadTask uploadTask;
      
      if (kIsWeb) {
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          
          // Set minimal metadata for web uploads
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=3600'
          );
          
          uploadTask = ref.putData(bytes, metadata);
        } else {
          throw Exception('Unsupported file type for web');
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is XFile) {
          uploadTask = ref.putFile(File(file.path));
        } else {
          throw Exception('Unsupported file type for mobile');
        }
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  static Future<List<String>> uploadMultipleFiles(List<dynamic> files) async {
    if (files.isEmpty) return [];

    final List<String> urls = [];
    for (final file in files) {
      try {
        final url = await uploadFile(file);
        if (url.isNotEmpty) {
          urls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        // Continue with other files even if one fails
      }
    }
    return urls;
  }

  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      throw Exception('Failed to delete file: $e');
    }
  }
} 