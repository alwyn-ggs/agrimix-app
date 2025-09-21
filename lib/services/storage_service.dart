import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _storage = FirebaseStorage.instance;
  
  FirebaseStorage get storage => _storage;

  // Upload file to user's folder
  Future<String> uploadFile({
    required File file,
    required String userId,
    String? folder,
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ?? path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      final ref = _storage.ref().child('user_uploads/$userId/${folder ?? 'general'}/$uniqueFileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload bytes data
  Future<String> uploadBytes({
    required Uint8List data,
    required String userId,
    required String fileName,
    String? folder,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      final ref = _storage.ref().child('user_uploads/$userId/${folder ?? 'general'}/$uniqueFileName');
      
      final uploadTask = ref.putData(data);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload bytes: $e');
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String userId,
    String? folder,
  }) async {
    final urls = <String>[];
    
    for (final file in files) {
      final url = await uploadFile(file: file, userId: userId, folder: folder);
      urls.add(url);
    }
    
    return urls;
  }

  // Upload image for posts
  Future<String> uploadPostImage({
    required File imageFile,
    required String userId,
  }) async {
    return uploadFile(file: imageFile, userId: userId, folder: 'posts');
  }

  // Upload images for fermentation logs
  Future<List<String>> uploadFermentationImages({
    required List<File> imageFiles,
    required String userId,
  }) async {
    return uploadFiles(files: imageFiles, userId: userId, folder: 'fermentation');
  }

  // Convenience: Upload a single image, inferring userId and using a default folder
  Future<String> uploadImage(
    File imageFile, {
    String folder = 'ingredients',
    String? userId,
  }) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    return uploadFile(file: imageFile, userId: resolvedUserId, folder: folder);
  }

  // Upload recipe images
  Future<String> uploadRecipeImage({
    required File imageFile,
    required String userId,
    required String recipeId,
  }) async {
    return uploadFile(
      file: imageFile, 
      userId: userId, 
      folder: 'recipes',
      customFileName: '${recipeId}_${path.basename(imageFile.path)}',
    );
  }

  // Upload profile image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    return uploadFile(
      file: imageFile, 
      userId: userId, 
      folder: 'profiles',
      customFileName: 'profile_${path.basename(imageFile.path)}',
    );
  }

  // Get download URL from storage path
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Get download URL with custom expiration
  Future<String> getDownloadUrlWithExpiration(String storagePath, {Duration? expiration}) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Delete file by download URL
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Delete multiple files by URLs
  Future<void> deleteFilesByUrls(List<String> downloadUrls) async {
    try {
      for (final url in downloadUrls) {
        await deleteFileByUrl(url);
      }
    } catch (e) {
      throw Exception('Failed to delete files: $e');
    }
  }

  // List files in user's folder
  Future<List<Reference>> listUserFiles(String userId, {String? folder}) async {
    try {
      final ref = _storage.ref().child('user_uploads/$userId/${folder ?? 'general'}');
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  // Update file metadata
  Future<void> updateFileMetadata(String storagePath, SettableMetadata metadata) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.updateMetadata(metadata);
    } catch (e) {
      throw Exception('Failed to update file metadata: $e');
    }
  }

  // Get file size
  Future<int> getFileSize(String storagePath) async {
    try {
      final metadata = await getFileMetadata(storagePath);
      return metadata.size ?? 0;
    } catch (e) {
      throw Exception('Failed to get file size: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Copy file
  Future<String> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceRef = _storage.ref().child(sourcePath);
      final destinationRef = _storage.ref().child(destinationPath);
      
      await destinationRef.putFile(File(await sourceRef.getDownloadURL()));
      return await destinationRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  // Move file (copy and delete)
  Future<String> moveFile(String sourcePath, String destinationPath) async {
    try {
      final newUrl = await copyFile(sourcePath, destinationPath);
      await deleteFile(sourcePath);
      return newUrl;
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }
}