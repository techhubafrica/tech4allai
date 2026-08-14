import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'tech4all image';

  /// Uploads an `XFile` from `image_picker` to Supabase Storage and returns the public URL.
  Future<String?> uploadSelfie(XFile file) async {
    try {
      String extension = p.extension(file.name).toLowerCase();
      if (extension.isEmpty) {
        extension = '.jpg';
      }
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName = 'headshots/${timestamp}_headshot$extension';
      
      final bytes = await file.readAsBytes();
      await _supabase.storage.from(_bucketName).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading selfie: $e');
      throw e;
    }
  }

  /// Uploads raw image bytes to Supabase Storage and returns the public URL.
  Future<String?> uploadReferenceImageBytes(Uint8List bytes) async {
    try {
      final String fileName = 'headshots/${DateTime.now().millisecondsSinceEpoch}_reference.jpg';
      
      await _supabase.storage.from(_bucketName).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading reference bytes: $e');
      return null;
    }
  }

  /// Optional: Clean up old uploaded images if necessary
  Future<void> deleteImage(String publicUrl) async {
     try {
        final uri = Uri.parse(publicUrl);
        final pathSegments = uri.pathSegments;
        
        final bucketIndex = pathSegments.indexOf(_bucketName);
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
           final filPathSegments = pathSegments.sublist(bucketIndex + 1);
           final relativePath = filPathSegments.join('/');
           await _supabase.storage.from(_bucketName).remove([relativePath]);
        }
     } catch (e) {
        print('Error deleting image from Supabase: $e');
     }
  }

  /// Uploads a generated ZIP file (as bytes) to Supabase Storage and returns the public URL.
  Future<String?> uploadZipBlob(Uint8List zipBytes) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName = 'datasets/${timestamp}_training_data.zip';
      
      await _supabase.storage.from(_bucketName).uploadBinary(
        fileName,
        zipBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'application/zip',
        ),
      );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading dataset ZIP: $e');
      throw e;
    }
  }
}

