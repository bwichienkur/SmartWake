import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeChallenge extends StatefulWidget {
  const BarcodeChallenge({
    super.key,
    this.expectedValue,
    required this.onComplete,
  });

  final String? expectedValue;
  final VoidCallback onComplete;

  @override
  State<BarcodeChallenge> createState() => _BarcodeChallengeState();
}

class _BarcodeChallengeState extends State<BarcodeChallenge> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Scan a barcode', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              onDetect: (capture) {
                if (_scanned) return;
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final value = barcode.rawValue;
                  if (value != null) {
                    if (widget.expectedValue == null ||
                        value == widget.expectedValue) {
                      _scanned = true;
                      widget.onComplete();
                    }
                  }
                }
              },
            ),
          ),
        ),
        if (widget.expectedValue != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Scan your registered barcode to dismiss',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

class QrChallenge extends StatefulWidget {
  const QrChallenge({
    super.key,
    this.expectedValue,
    required this.onComplete,
  });

  final String? expectedValue;
  final VoidCallback onComplete;

  @override
  State<QrChallenge> createState() => _QrChallengeState();
}

class _QrChallengeState extends State<QrChallenge> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Scan a QR code', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              onDetect: (capture) {
                if (_scanned) return;
                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;
                  if (value != null) {
                    if (widget.expectedValue == null ||
                        value == widget.expectedValue) {
                      _scanned = true;
                      widget.onComplete();
                    }
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
