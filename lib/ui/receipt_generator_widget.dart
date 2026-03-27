import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../models/receipt_custom_data.dart';
import '../services/printer_service.dart';
import 'receipt_layout.dart';

class ReceiptGeneratorWidget extends StatefulWidget {
  final PrinterService printerService;

  const ReceiptGeneratorWidget({super.key, required this.printerService});

  @override
  State<ReceiptGeneratorWidget> createState() => _ReceiptGeneratorWidgetState();
}

class _ReceiptGeneratorWidgetState extends State<ReceiptGeneratorWidget> {
  final ScreenshotController _screenshotController = ScreenshotController();
  ReceiptCustomData? _currentData;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.printerService.customPrintRequestStream.listen(
      _handleRequest,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleRequest(ReceiptCustomData data) {
    setState(() {
      _currentData = data;
    });

    // Wait for frame to build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _captureAndPrint();
    });
  }

  Future<void> _captureAndPrint() async {
    if (_currentData == null) return;

    try {
      print('📸 Capturing receipt widget...');
      // Capture invisible widget
      // delay ensures layout is complete
      final bytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0, // Higher resolution for sharper text
      );

      if (bytes != null) {
        print(
          '📸 Receipt captured (${bytes.length} bytes), sending to printer...',
        );
        // Default to 'kasir' category for now
        await widget.printerService.printReceiptImage('kasir', bytes);
      } else {
        print('⚠️ Screenshot capture returned null');
      }
    } catch (e) {
      print('❌ Capture/Print failed: $e');
    } finally {
      // Optional: Clear data after print to save memory,
      // but keeping it might be useful for debug visual if we remove Offstage
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) return const SizedBox.shrink();

    // Use Transform to move it off-screen but keep it in the tree
    // Opacity 0 to be sure it's invisible
    return Transform.translate(
      offset: const Offset(10000, 10000), // Far away
      child: Opacity(
        opacity: 0, // Invisible
        child: SingleChildScrollView(
          child: RepaintBoundary(
            // Boundary for good measure
            child: Screenshot(
              controller: _screenshotController,
              child: ReceiptLayout(
                data: _currentData!,
                settings: widget.printerService.businessSettings,
                width: 380, // Target width for 58mm printer at reasonable dpi
              ),
            ),
          ),
        ),
      ),
    );
  }
}
