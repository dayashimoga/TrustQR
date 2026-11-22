import 'package:flutter/material.dart';
import 'package:qr_core/qr_core.dart';
import 'package:qr_scanner_engine/qr_scanner_engine.dart';
import 'package:qr_design_system/qr_design_system.dart';

void main() {
  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal QR Scanner (User App)',
      theme: CyberTokens.createDarkCyberTheme(),
      home: const UserScannerHomePage(),
    );
  }
}

class UserScannerHomePage extends StatefulWidget {
  const UserScannerHomePage({super.key});

  @override
  State<UserScannerHomePage> createState() => _UserScannerHomePageState();
}

class _UserScannerHomePageState extends State<UserScannerHomePage> {
  final QrScannerEngine _scanner = DefaultQrScannerEngine();
  String _scanResult = 'No code scanned yet. Tap scan or enter payload below.';
  SecurityThreatLevel _threatLevel = SecurityThreatLevel.safe;
  final TextEditingController _inputController = TextEditingController();

  Future<void> _performScan(String input) async {
    if (input.trim().isEmpty) return;
    final result = await _scanner.decodeFromRawString(input.trim());
    setState(() {
      _scanResult = 'Scanned: ${result.rawContent}\nType: ${result.payloadType.name}\nThreat Level: ${result.threatLevel.name}';
      _threatLevel = result.threatLevel;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal QR Scanner [User App]'),
        backgroundColor: CyberTokens.obsidianBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restricted Scanner Workspace',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CyberTokens.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zero-Trust QR Threat Firewall Active. QR Generation is physically restricted.',
                    style: TextStyle(color: CyberTokens.cyberTextMuted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _scanResult,
                    style: TextStyle(
                      color: _threatLevel == SecurityThreatLevel.critical
                          ? CyberTokens.neonCrimson
                          : CyberTokens.cyberTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Simulated Camera / File Input Payload',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _performScan(_inputController.text),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Execute Threat-Audited Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CyberTokens.neonCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
