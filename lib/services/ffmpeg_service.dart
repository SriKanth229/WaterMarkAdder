import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/session.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/watermark_config.dart';

class FFmpegService {
  Session? _currentSession;
  bool _isCancelled = false;

  /// Get total duration of a video file in milliseconds
  Future<double> getVideoDuration(String inputPath) async {
    try {
      final mediaInfoSession = await FFprobeKit.getMediaInformation(inputPath);
      final mediaInfo = mediaInfoSession.getMediaInformation();
      if (mediaInfo != null && mediaInfo.getDuration() != null) {
        final durationSeconds = double.tryParse(mediaInfo.getDuration()!) ?? 0.0;
        return durationSeconds * 1000.0; // convert to ms
      }
    } catch (e) {
      // Fallback
    }
    return 0.0;
  }

  /// Process video with watermark text
  Future<String?> processWatermark({
    required String inputPath,
    required WatermarkConfig config,
    required Function(double progress, String statusText) onProgress,
  }) async {
    _isCancelled = false;

    // 1. Get video duration for accurate progress calculation
    final totalDurationMs = await getVideoDuration(inputPath);

    // 2. Prepare output file path in cache
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(inputPath).isNotEmpty ? p.extension(inputPath) : '.mp4';
    final outputPath = p.join(tempDir.path, 'watermarked_$timestamp$extension');

    // Remove existing file if present
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    // 3. Build FFmpeg command
    final filterString = config.buildFfmpegFilter();
    
    // Command explanation:
    // -y: overwrite output
    // -i input: source video
    // -vf ...: apply drawtext video filter
    // -c:a copy: copy audio without re-encoding for high speed & zero audio quality loss
    // -c:v libx264: standard H.264 video codec
    // -preset ultrafast / faster: optimal encoding speed on mobile devices
    final command = '-y -i "$inputPath" -vf "$filterString" -c:v libx264 -preset faster -crf 22 -c:a copy "$outputPath"';

    onProgress(0.05, "Initializing video engine...");

    // 4. Register statistics listener for real-time progress
    FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
      if (_isCancelled) return;
      
      final timeMs = statistics.getTime();
      if (totalDurationMs > 0 && timeMs > 0) {
        final progress = (timeMs / totalDurationMs).clamp(0.0, 0.98);
        final currentSec = (timeMs / 1000).toStringAsFixed(1);
        final totalSec = (totalDurationMs / 1000).toStringAsFixed(1);
        onProgress(progress, 'Processing: $currentSec s / $totalSec s (${(progress * 100).toInt()}%)');
      } else {
        onProgress(0.45, 'Rendering frames with watermark...');
      }
    });

    // 5. Execute FFmpeg asynchronously
    _currentSession = await FFmpegKit.executeAsync(
      command,
      (Session session) async {
        // Complete callback
      },
      (log) {
        // Log stream for debugging
      },
    );

    // Wait for the session to complete
    final returnCode = await _currentSession!.getReturnCode();

    if (_isCancelled) {
      onProgress(0.0, 'Processing cancelled');
      return null;
    }

    if (ReturnCode.isSuccess(returnCode)) {
      onProgress(1.0, 'Watermark applied successfully!');
      return outputPath;
    } else if (ReturnCode.isCancel(returnCode)) {
      onProgress(0.0, 'Cancelled by user');
      return null;
    } else {
      final failStackTrace = await _currentSession!.getFailStackTrace();
      final logs = await _currentSession!.getAllLogsAsString();
      throw Exception('FFmpeg processing failed: $failStackTrace\n$logs');
    }
  }

  /// Cancel current ongoing session
  Future<void> cancel() async {
    _isCancelled = true;
    if (_currentSession != null) {
      await FFmpegKit.cancel(_currentSession!.getSessionId());
    }
  }
}
