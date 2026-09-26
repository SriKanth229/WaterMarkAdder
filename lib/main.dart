import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'models/watermark_config.dart';
import 'services/ffmpeg_service.dart';
import 'services/permission_service.dart';
import 'widgets/video_player_view.dart';
import 'widgets/watermark_config_card.dart';
import 'widgets/processing_dialog.dart';
import 'widgets/export_result_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watermark Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep slate background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo accent
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0B0F19),
        ),
        fontFamily: 'Roboto',
      ),
      home: const WatermarkHomeScreen(),
    );
  }
}

class WatermarkHomeScreen extends StatefulWidget {
  const WatermarkHomeScreen({super.key});

  @override
  State<WatermarkHomeScreen> createState() => _WatermarkHomeScreenState();
}

class _WatermarkHomeScreenState extends State<WatermarkHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final FFmpegService _ffmpegService = FFmpegService();

  File? _selectedVideo;
  WatermarkConfig _config = const WatermarkConfig(
    text: 'Watermark Demo',
    fontSize: 28,
    opacity: 0.75,
    position: WatermarkPosition.bottomCenter,
    bottomMargin: 35,
    showBackgroundBox: true,
  );

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _exportedVideoPath;

  /// Pick video from Gallery
  Future<void> _pickVideo() async {
    final hasPermission = await PermissionService.requestMediaPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text('Storage / Media permission is required to select videos.'),
          ),
        );
      }
      return;
    }

    try {
      final pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 60),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedVideo = File(pickedFile.path);
          _exportedVideoPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to select video: $e'),
          ),
        );
      }
    }
  }

  /// Start the FFmpeg rendering pipeline
  Future<void> _startWatermarking() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first.')),
      );
      return;
    }

    if (_config.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a watermark text.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusText = 'Preparing video engine...';
    });

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return ProcessingDialog(
            progress: _progress,
            statusText: _statusText,
            onCancel: () async {
              await _ffmpegService.cancel();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _isProcessing = false);
              }
            },
          );
        },
      ),
    );

    try {
      final outputPath = await _ffmpegService.processWatermark(
        inputPath: _selectedVideo!.path,
        config: _config,
        onProgress: (progress, statusText) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText = statusText;
            });
          }
        },
      );

      // Close processing modal
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (outputPath != null && mounted) {
        setState(() {
          _isProcessing = false;
          _exportedVideoPath = outputPath;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isProcessing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Processing Error', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            error,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF818CF8))),
          ),
        ],
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _selectedVideo = null;
      _exportedVideoPath = null;
      _isProcessing = false;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watermark Studio',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Local Frame-by-Frame Video Renderer',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_selectedVideo != null || _exportedVideoPath != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
              tooltip: 'Clear & Start Over',
              onPressed: _resetAll,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Exported Result State
              if (_exportedVideoPath != null) ...[
                ExportResultView(
                  videoPath: _exportedVideoPath!,
                  onProcessAnother: _resetAll,
                ),
              ]
              // 2. Editing & Video Selection State
              else ...[
                // Video Selector / Live Preview
                if (_selectedVideo == null)
                  _buildUploadBox()
                else ...[
                  // Live Preview Player with bottom watermark overlay
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LIVE PREVIEW',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Bottom Watermark Preview',
                              style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      VideoPlayerView(
                        videoFile: _selectedVideo!,
                        overlayConfig: _config,
                        onRemove: () => setState(() => _selectedVideo = null),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Watermark Settings Card
                  WatermarkConfigCard(
                    config: _config,
                    onChanged: (newConfig) {
                      setState(() => _config = newConfig);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Render Action Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _startWatermarking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 22),
                      label: const Text(
                        'Apply Watermark & Render Video',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Visual dropzone card for selecting video
  Widget _buildUploadBox() {
    return InkWell(
      onTap: _pickVideo,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_rounded,
                color: Color(0xFF818CF8),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Video to Watermark',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap here to choose any video (MP4, MKV, MOV, WebM)\nfrom your phone gallery or storage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Choose Video',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
