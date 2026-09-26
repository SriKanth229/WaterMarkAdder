import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'video_player_view.dart';

class ExportResultView extends StatefulWidget {
  final String videoPath;
  final VoidCallback onProcessAnother;

  const ExportResultView({
    super.key,
    required this.videoPath,
    required this.onProcessAnother,
  });

  @override
  State<ExportResultView> createState() => _ExportResultViewState();
}

class _ExportResultViewState extends State<ExportResultView> {
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: false);
      }

      await Gal.putVideo(widget.videoPath);

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Video successfully saved to your Gallery!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to save to gallery: $e'),
          ),
        );
      }
    }
  }

  Future<void> _shareVideo() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.videoPath)],
        text: 'Check out my watermarked video!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error sharing video: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoFile = File(widget.videoPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watermark Added Successfully!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Preview your rendered video below and save to gallery.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Result Video Player
        VideoPlayerView(
          videoFile: videoFile,
          showControls: true,
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            // Save to Gallery Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isSaved ? Icons.check_rounded : Icons.download_rounded, size: 20),
                label: Text(
                  _isSaved ? 'Saved to Gallery' : 'Save to Gallery',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Share Button
            ElevatedButton(
              onPressed: _shareVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF334155)),
                elevation: 2,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF818CF8)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Process Another Video Button
        TextButton.icon(
          onPressed: widget.onProcessAnother,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Process Another Video', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
