import 'package:flutter/material.dart';
import 'package:qr_design_system/qr_design_system.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import '../state/studio_controller.dart';

/// Interactive customization panel for artistic module shapes, colors, gradients, and logos.
class ArtisticCustomizationPanel extends StatelessWidget {
  final StudioController controller;

  const ArtisticCustomizationPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return CyberGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Artistic Customization Studio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CyberTokens.neonCyan,
                ),
              ),
              const SizedBox(height: 12),

              // Template Presets
              const Text('Template Presets', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTemplateChip(
                    name: 'Cyberpunk',
                    template: QrTemplate.cyberpunkNeon,
                    color: CyberTokens.neonCyan,
                  ),
                  _buildTemplateChip(
                    name: 'Corporate Navy',
                    template: QrTemplate.corporateNavy,
                    color: const Color(0xFF0066CC),
                  ),
                  _buildTemplateChip(
                    name: 'Emerald Trust',
                    template: QrTemplate.emeraldTrust,
                    color: CyberTokens.neonEmerald,
                  ),
                  _buildTemplateChip(
                    name: 'High Contrast',
                    template: QrTemplate.highContrastMono,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Module Shape & ECC
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Module Shape', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<QrModuleShape>(
                          isExpanded: true,
                          // ignore: deprecated_member_use
                          value: controller.moduleShape,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          dropdownColor: CyberTokens.slateCard,
                          items: QrModuleShape.values.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setModuleShape(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Error Correction', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<QrErrorCorrectionLevel>(
                          isExpanded: true,
                          // ignore: deprecated_member_use
                          value: controller.errorCorrection,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          dropdownColor: CyberTokens.slateCard,
                          items: QrErrorCorrectionLevel.values.map((ec) {
                            return DropdownMenuItem(value: ec, child: Text(ec.name.toUpperCase(), overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setErrorCorrection(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Eye Framing & Pupil Shapes
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Eye Frame', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<QrEyeFrameShape>(
                          isExpanded: true,
                          // ignore: deprecated_member_use
                          value: controller.eyeFrameShape,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          dropdownColor: CyberTokens.slateCard,
                          items: QrEyeFrameShape.values.map((ef) {
                            return DropdownMenuItem(value: ef, child: Text(ef.name, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setEyeStyle(frameShape: val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Eye Pupil', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<QrEyePupilShape>(
                          isExpanded: true,
                          // ignore: deprecated_member_use
                          value: controller.eyePupilShape,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          dropdownColor: CyberTokens.slateCard,
                          items: QrEyePupilShape.values.map((ep) {
                            return DropdownMenuItem(value: ep, child: Text(ep.name, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setEyeStyle(pupilShape: val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gradient Mode & Colors
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Color Gradient Mode', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                  const SizedBox(height: 4),
                  SegmentedButton<QrGradientType>(
                    segments: const [
                      ButtonSegment(value: QrGradientType.none, label: Text('Solid')),
                      ButtonSegment(value: QrGradientType.linear, label: Text('Linear')),
                      ButtonSegment(value: QrGradientType.radial, label: Text('Radial')),
                    ],
                    selected: {controller.gradientType},
                    onSelectionChanged: (set) {
                      controller.setColors(gradient: set.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Color Palette Swatches
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorPickerButton(
                    context,
                    title: 'Primary Color',
                    currentColor: Color(controller.foregroundColorHex),
                    onColorSelected: (c) => controller.setColors(
                      // ignore: deprecated_member_use
                      foreground: c.value,
                    ),
                  ),
                  if (controller.gradientType != QrGradientType.none)
                    _buildColorPickerButton(
                      context,
                      title: 'Gradient Stop 2',
                      currentColor: Color(controller.gradientColor2Hex),
                      onColorSelected: (c) => controller.setColors(
                        // ignore: deprecated_member_use
                        gradientColor2: c.value,
                      ),
                    ),
                  _buildColorPickerButton(
                    context,
                    title: 'Background',
                    currentColor: Color(controller.backgroundColorHex),
                    onColorSelected: (c) => controller.setColors(
                      // ignore: deprecated_member_use
                      background: c.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Linear Angle Slider (if Linear)
              if (controller.gradientType == QrGradientType.linear) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gradient Angle', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                    Text('${controller.linearAngleDegrees.toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, color: CyberTokens.neonCyan)),
                  ],
                ),
                Slider(
                  value: controller.linearAngleDegrees,
                  min: 0.0,
                  max: 360.0,
                  divisions: 24,
                  activeColor: CyberTokens.neonCyan,
                  onChanged: (val) => controller.setColors(linearAngle: val),
                ),
                const SizedBox(height: 8),
              ],

              // Embedded Logo Area
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: CyberTokens.neonCyan, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Embedded Center Logo Area',
                      style: TextStyle(color: CyberTokens.cyberTextPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(
                    key: const Key('logo_toggle_switch'),
                    value: controller.hasLogo,
                    activeThumbColor: CyberTokens.neonCyan,
                    onChanged: (val) => controller.setLogoConfig(hasLogo: val),
                  ),
                ],
              ),
              if (controller.hasLogo) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Logo Occlusion Ratio', style: TextStyle(fontSize: 12, color: CyberTokens.cyberTextMuted)),
                    Text('${(controller.logoSizeRatio * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: CyberTokens.neonAmber)),
                  ],
                ),
                Slider(
                  key: const Key('logo_size_slider'),
                  value: controller.logoSizeRatio,
                  min: 0.10,
                  max: 0.30,
                  divisions: 4,
                  activeColor: CyberTokens.neonAmber,
                  onChanged: (val) => controller.setLogoConfig(hasLogo: true, sizeRatio: val),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateChip({
    required String name,
    required QrTemplate template,
    required Color color,
  }) {
    final isSelected = controller.activeTemplate?.id == template.id;
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(name),
      backgroundColor: isSelected ? color.withAlpha(76) : CyberTokens.slateCard,
      side: BorderSide(color: isSelected ? color : Colors.transparent),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : CyberTokens.cyberTextPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      onPressed: () => controller.applyTemplate(template),
    );
  }

  Widget _buildColorPickerButton(
    BuildContext context, {
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    // ignore: deprecated_member_use
    final hexVal = currentColor.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: CyberTokens.cyberTextMuted)),
        const SizedBox(height: 4),
        InkWell(
          key: Key('color_button_${title.replaceAll(' ', '_').toLowerCase()}'),
          onTap: () {
            // Quick preset switcher
            final nextColor = hexVal == 0xFF00F5FF
                ? const Color(0xFFFF007F)
                : hexVal == 0xFFFF007F
                    ? const Color(0xFF00E676)
                    : hexVal == 0xFF090D14
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF00F5FF);
            onColorSelected(nextColor);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${hexVal.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
