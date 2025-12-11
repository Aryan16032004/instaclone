import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  // INCREASED QUALITY settings to fix blurriness
  Future<XFile?> pickImage() => _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Full HD
        imageQuality: 85, // Good balance of size/quality
      );

  Future<XFile?> pickVideo() => _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

  Future<String> uploadFile(File file, String folderName) async {
    final fileName = '${const Uuid().v4()}';
    final path = '$folderName/$fileName';

    await _supabase.storage.from('posts').upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _supabase.storage.from('posts').getPublicUrl(path);
  }

  // UPDATED: Upload Profile Picture
  Future<void> updateProfilePic(String userId, File file) async {
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}';
    
    await _supabase.storage.from('posts').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true), // Overwrite old one
    );
    
    final url = _supabase.storage.from('posts').getPublicUrl(fileName);
    
    // Update the profile table
    await _supabase.from('profiles').update({'avatar_url': url}).eq('id', userId);
  }

  Future<void> createPostDoc({
    required String userId,
    required String mediaUrl,
    required bool isVideo,
    String caption = '',
  }) async {
    await _supabase.from('posts').insert({
      'user_id': userId,
      'media_url': mediaUrl,
      'is_video': isVideo,
      'caption': caption,
    });
  }
}