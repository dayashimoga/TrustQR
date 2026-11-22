import 'package:flutter/material.dart';
import 'package:qr_generator_engine/qr_generator_engine.dart';
import 'package:qr_admin_analytics/qr_admin_analytics.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal QR Studio [Admin App]',
      theme: CyberTokens.createDarkCyberTheme(),
      home: const AdminStudioHomePage(),
    );
  }
}

class AdminStudioHomePage extends StatefulWidget {
  const AdminStudioHomePage({super.key});

  @override
  State<AdminStudioHomePage> createState() => _AdminStudioHomePageState();
}

class _AdminStudioHomePageState extends State<AdminStudioHomePage> {
  final QrGeneratorEngine _generator = const DefaultQrGeneratorEngine();
  final AdminAnalyticsService _analytics = const AdminAnalyticsService();
  final TextEditingController _payloadController = TextEditingController(text: 'https://universal-qr.org/admin');
  
  QrModuleShape _moduleShape = QrModuleShape.cyberGrid;
  QrErrorCorrectionLevel _errorCorrection = QrErrorCorrectionLevel.high;
  ScannabilityAssessment? _assessment;
  String _generatedMatrix = '';

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final options = QrCustomizationOptions(
      moduleShape: _moduleShape,
      errorCorrection: _errorCorrection,
      foregroundColorHex: 0xFF00F5FF,
      backgroundColorHex: 0xFF090D14,
    );
    setState(() {
      _assessment = _generator.evaluateScannability(options);
      _generatedMatrix = _generator.generateMatrixRepresentation(_payloadController.text, options);
    });
  }

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal QR Studio & Fleet Analytics [Admin]'),
        backgroundColor: CyberTokens.obsidianBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Fleet Telemetry',
            onPressed: () {
              final summary = _analytics.aggregateMetrics(items: [], generationCount: 1);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Generations: ${summary.totalGenerations}, Threats: ${summary.threatsDetected}')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Artistic QR Generator Studio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CyberTokens.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _payloadController,
                    onChanged: (_) => _recalculate(),
                    decoration: const InputDecoration(
                      labelText: 'Payload Data / URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Module Shape: ', style: TextStyle(color: CyberTokens.cyberTextPrimary)),
                          DropdownButton<QrModuleShape>(
                            value: _moduleShape,
                            dropdownColor: CyberTokens.slateCard,
                            items: QrModuleShape.values.map((shape) {
                              return DropdownMenuItem(value: shape, child: Text(shape.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _moduleShape = val);
                                _recalculate();
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Error Correction: ', style: TextStyle(color: CyberTokens.cyberTextPrimary)),
                          DropdownButton<QrErrorCorrectionLevel>(
                            value: _errorCorrection,
                            dropdownColor: CyberTokens.slateCard,
                            items: QrErrorCorrectionLevel.values.map((ec) {
                              return DropdownMenuItem(value: ec, child: Text(ec.name));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _errorCorrection = val);
                                _recalculate();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_assessment != null) ...[
                    Text(
                      'Scannability Score: ${_assessment!.scannabilityScore.toStringAsFixed(1)}% | Contrast: ${_assessment!.contrastRatio.toStringAsFixed(2)}:1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _assessment!.isScannable ? CyberTokens.neonEmerald : CyberTokens.neonCrimson,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_assessment!.recommendation, style: const TextStyle(color: CyberTokens.cyberTextMuted)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _generatedMatrix,
                    style: const TextStyle(fontFamily: 'monospace', color: CyberTokens.neonCyan),
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
