import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/di/providers.dart';

enum BarcodeScanMode { barcode, qr }

class BarcodeRegistrationScreen extends ConsumerStatefulWidget {
  const BarcodeRegistrationScreen({super.key, required this.mode});

  final BarcodeScanMode mode;

  @override
  ConsumerState<BarcodeRegistrationScreen> createState() =>
      _BarcodeRegistrationScreenState();
}

class _BarcodeRegistrationScreenState
    extends ConsumerState<BarcodeRegistrationScreen> {
  bool _saved = false;

  Future<void> _save(String value) async {
    if (_saved) return;
    _saved = true;

    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    if (user == null) return;

    final prefs = widget.mode == BarcodeScanMode.barcode
        ? user.preferences.copyWith(registeredBarcode: value)
        : user.preferences.copyWith(registeredQrCode: value);

    await ref.read(userRepositoryProvider).saveUser(
          user.copyWith(preferences: prefs),
        );
    if (mounted) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == BarcodeScanMode.barcode
        ? 'Register barcode'
        : 'Register QR code';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Scan the code on your bathroom or kitchen item once. '
              'Use it for wake-up challenges without scanning every morning setup.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final value = barcodes.first.rawValue;
                if (value != null && value.isNotEmpty) {
                  _save(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
