import 'package:flutter/material.dart';
import '../models/watermark_config.dart';

class WatermarkConfigCard extends StatefulWidget {
  final WatermarkConfig config;
  final ValueChanged<WatermarkConfig> onChanged;

  const WatermarkConfigCard({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  State<WatermarkConfigCard> createState() => _WatermarkConfigCardState();
}

class _WatermarkConfigCardState extends State<WatermarkConfigCard> {
  late TextEditingController _textController;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.config.text);
  }

  @override
  void didUpdateWidget(covariant WatermarkConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.text != widget.config.text &&
        _textController.text != widget.config.text) {
      _textController.text = widget.config.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate dark surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.branding_watermark_rounded, color: Color(0xFF818CF8), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Watermark Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              // Light bottom badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Bottom Overlay',
                  style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Watermark Text Input
          const Text(
            'WATERMARK TEXT',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            cursorColor: const Color(0xFF818CF8),
            decoration: InputDecoration(
              hintText: 'e.g. @MyChannel or © Copyright 2026',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.text_fields_rounded, color: Color(0xFF818CF8), size: 20),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                      onPressed: () {
                        _textController.clear();
                        widget.onChanged(widget.config.copyWith(text: ''));
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
              ),
            ),
            onChanged: (val) {
              widget.onChanged(widget.config.copyWith(text: val));
            },
          ),

          const SizedBox(height: 16),

          // Presets Row
          const Text(
            'STYLE PRESETS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(
                  label: 'Subtle Bottom (Recommended)',
                  isSelected: widget.config.opacity == 0.75 && widget.config.showBackgroundBox,
                  onTap: () {
                    widget.onChanged(widget.config.copyWith(
                      opacity: 0.75,
                      fontSize: 28,
                      showBackgroundBox: true,
                      boxOpacity: 0.35,
                      bottomMargin: 35,
                      position: WatermarkPosition.bottomCenter,
                    ));
                  },
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Ghost White',
                  isSelected: widget.config.opacity == 0.5 && !widget.config.showBackgroundBox,
                  onTap: () {
                    widget.onChanged(widget.config.copyWith(
                      opacity: 0.5,
                      fontSize: 26,
                      showBackgroundBox: false,
                      bottomMargin: 30,
                      position: WatermarkPosition.bottomCenter,
                    ));
                  },
                ),
                const SizedBox(width: 8),
                _buildPresetChip(
                  label: 'Bottom Right Light',
                  isSelected: widget.config.position == WatermarkPosition.bottomRight,
                  onTap: () {
                    widget.onChanged(widget.config.copyWith(
                      position: WatermarkPosition.bottomRight,
                      opacity: 0.7,
                      fontSize: 24,
                      showBackgroundBox: true,
                      boxOpacity: 0.3,
                      bottomMargin: 30,
                    ));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Advanced settings expander
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded,
                    color: const Color(0xFF818CF8),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showAdvanced ? 'Hide Fine Adjustments' : 'Customize Opacity, Size & Margin',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showAdvanced) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 16),

            // Opacity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Watermark Opacity (Lightness)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${(widget.config.opacity * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6366F1),
                thumbColor: const Color(0xFF818CF8),
                inactiveTrackColor: const Color(0xFF334155),
              ),
              child: Slider(
                value: widget.config.opacity,
                min: 0.2,
                max: 1.0,
                divisions: 16,
                onChanged: (val) {
                  widget.onChanged(widget.config.copyWith(opacity: val));
                },
              ),
            ),

            // Font Size Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Font Size',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${widget.config.fontSize.toInt()} px',
                  style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6366F1),
                thumbColor: const Color(0xFF818CF8),
                inactiveTrackColor: const Color(0xFF334155),
              ),
              child: Slider(
                value: widget.config.fontSize,
                min: 16.0,
                max: 48.0,
                divisions: 16,
                onChanged: (val) {
                  widget.onChanged(widget.config.copyWith(fontSize: val));
                },
              ),
            ),

            // Bottom Margin Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bottom Distance (Padding)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${widget.config.bottomMargin} px',
                  style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6366F1),
                thumbColor: const Color(0xFF818CF8),
                inactiveTrackColor: const Color(0xFF334155),
              ),
              child: Slider(
                value: widget.config.bottomMargin.toDouble(),
                min: 10.0,
                max: 100.0,
                divisions: 18,
                onChanged: (val) {
                  widget.onChanged(widget.config.copyWith(bottomMargin: val.toInt()));
                },
              ),
            ),

            // Subtle Background Box Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subtle Background Box',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Soft dark backdrop for readability',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                Switch(
                  value: widget.config.showBackgroundBox,
                  activeColor: const Color(0xFF818CF8),
                  activeTrackColor: const Color(0xFF6366F1).withOpacity(0.4),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: const Color(0xFF334155),
                  onChanged: (val) {
                    widget.onChanged(widget.config.copyWith(showBackgroundBox: val));
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Color(0xFF818CF8), size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
