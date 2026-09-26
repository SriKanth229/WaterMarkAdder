import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request appropriate storage/media permissions based on Android SDK level
  static Future<bool> requestMediaPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 13+ (API 33+)
      final videoStatus = await Permission.videos.status;
      if (videoStatus.isGranted) return true;

      final requestedVideo = await Permission.videos.request();
      if (requestedVideo.isGranted) return true;

      // Fallback for Android 12 and below
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final requestedStorage = await Permission.storage.request();
      return requestedStorage.isGranted;
    } catch (e) {
      // In case of permission check errors, fallback to true if picker still functions
      return true;
    }
  }

  /// Check if permission is granted
  static Future<bool> hasMediaPermission() async {
    if (!Platform.isAndroid) return true;
    final video = await Permission.videos.isGranted;
    final storage = await Permission.storage.isGranted;
    return video || storage;
  }
}
