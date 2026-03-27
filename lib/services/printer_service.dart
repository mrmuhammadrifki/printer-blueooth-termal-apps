import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/business_settings.dart';
import '../models/printer_category.dart';
import '../models/receipt_custom_data.dart';
import '../models/kitchen_order.dart';

class PrinterService {
  final _bluetooth = BlueThermalPrinter.instance;
  bool _isConnected = false;

  BusinessSettings businessSettings = BusinessSettings();
  PrinterCategoryList printerCategories = PrinterCategoryList();

  bool debugMode = false;
  final List<String> _printLog = [];

  final _statusController = StreamController<String>.broadcast();
  final _customPrintRequestController =
      StreamController<ReceiptCustomData>.broadcast();
  final _categoriesChangedController = StreamController<void>.broadcast();

  String _currentStatus = 'No printers connected';

  Stream<String> get statusStream => _statusController.stream;
  Stream<ReceiptCustomData> get customPrintRequestStream =>
      _customPrintRequestController.stream;
  Stream<void> get categoriesChangedStream =>
      _categoriesChangedController.stream;

  String get currentStatus => _currentStatus;
  List<String> get printLog => List.unmodifiable(_printLog);
  bool get isCurrentlyConnected => _isConnected;

  static const String _businessSettingsKey = 'business_settings';
  static const String _printerCategoriesKey = 'printer_categories';

  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() {
    return _instance;
  }

  PrinterService._internal() {
    _initialize();
    _setupStateListener();
  }

  void _setupStateListener() {
    _bluetooth.onStateChanged().listen(
      (state) {
        try {
          switch (state) {
            case BlueThermalPrinter.CONNECTED:
              _isConnected = true;
              print('✅ Bluetooth state: CONNECTED');
              _updateStatus('✓ Printer connected');
              break;
            case BlueThermalPrinter.DISCONNECTED:
              _isConnected = false;
              print('⚠️ Bluetooth state: DISCONNECTED');
              _updateStatus('Printer disconnected');
              break;
            case BlueThermalPrinter.DISCONNECT_REQUESTED:
              _isConnected = false;
              print('🔌 Bluetooth state: DISCONNECT_REQUESTED');
              _updateStatus('Disconnecting...');
              break;
            default:
              print('📱 Bluetooth state: $state');
              break;
          }
        } catch (e) {
          print('❌ Error in state listener: $e');
          _updateStatus('Bluetooth error: $e');
        }
      },
      onError: (error) {
        print('❌ Bluetooth state stream error: $error');
        _updateStatus('Bluetooth error: $error');
        _isConnected = false;
      },
    );
  }

  Future<void> _initialize() async {
    await loadBusinessSettings();
    await loadPrinterCategories();
    _updatePrinterStatus();
  }

  Future<void> loadBusinessSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_businessSettingsKey);
      if (jsonString != null) {
        businessSettings = BusinessSettings.fromJsonString(jsonString);
        print('✅ Business settings loaded');
      }
    } catch (e) {
      print('❌ Failed to load business settings: $e');
    }
  }

  Future<void> saveBusinessSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _businessSettingsKey,
        businessSettings.toJsonString(),
      );
      print('✅ Business settings saved');
    } catch (e) {
      print('❌ Failed to save business settings: $e');
    }
  }

  Future<void> loadPrinterCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_printerCategoriesKey);
      if (jsonString != null) {
        printerCategories = PrinterCategoryList.fromJsonString(jsonString);
        print(
          '✅ Printer categories loaded: ${printerCategories.categories.length} categories',
        );
      } else {
        // Initialize default categories if none exist
        await addCategory(
          'kasir',
          'Kasir (Receipt)',
          paperSize: esc_pos.PaperSize.mm58,
        );
        await addCategory(
          'dapur',
          'Dapur (Kitchen)',
          paperSize: esc_pos.PaperSize.mm58,
        );
      }
    } catch (e) {
      print('❌ Failed to load printer categories: $e');
    }
  }

  Future<void> savePrinterCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _printerCategoriesKey,
        printerCategories.toJsonString(),
      );
      print('✅ Printer categories saved');
      _updatePrinterStatus();
      _categoriesChangedController.add(null);
    } catch (e) {
      print('❌ Failed to save printer categories: $e');
    }
  }

  void _updateStatus(String status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _updatePrinterStatus() {
    final assigned =
        printerCategories.categories.where((c) => c.isAssigned).length;
    final total = printerCategories.categories.length;
    _updateStatus('Printers: $assigned/$total assigned');
  }

  // --- printKitchenOrder implementation ---
  Future<void> printKitchenOrder(KitchenOrder order) async {
    const categoryId = 'dapur';
    final category = printerCategories.findById(categoryId);

    if (category == null || !category.isAssigned) {
      throw Exception(
        'Printer kategori "dapur" belum disetting atau tidak ditemukan.',
      );
    }

    final profile = await esc_pos.CapabilityProfile.load();
    final generator = esc_pos.Generator(category.paperSize, profile);
    final bytes = <int>[];

    // Reset
    bytes.addAll(generator.reset());

    // Header
    bytes.addAll(
      generator.text(
        '=== ORDER DAPUR ===',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size2,
          width: esc_pos.PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.feed(1));

    // Order Info
    bytes.addAll(
      generator.text(
        'No: ${order.orderId}',
        styles: const esc_pos.PosStyles(bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'Meja: ${order.tableName ?? 'N/A'}',
        styles: const esc_pos.PosStyles(
          height: esc_pos.PosTextSize.size2,
          width: esc_pos.PosTextSize.size2,
        ),
      ),
    );

    if (order.customerName != null && order.customerName!.isNotEmpty) {
      bytes.addAll(generator.text('Customer: ${order.customerName}'));
    }

    // Timestamp formatting
    String timeStr = order.timestamp ?? '';
    // If timestamp is ISO string, try parsing
    try {
      if (timeStr.isNotEmpty) {
        final dt = DateTime.parse(timeStr).toLocal();
        // Format: HH:mm
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$minute';
      }
    } catch (_) {} // use original if parse fails

    bytes.addAll(generator.text('Waktu: $timeStr'));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr());

    // Items
    for (final item in order.items) {
      bytes.addAll(
        generator.text(
          '${item.quantity}x ${item.name}',
          styles: const esc_pos.PosStyles(
            bold: true,
            height: esc_pos.PosTextSize.size2,
            width: esc_pos.PosTextSize.size2,
          ),
        ),
      );
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.addAll(generator.text('   Catatan: ${item.notes}'));
      }
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    // Print
    if (_isConnected) {
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      _updateStatus('Printed Kitchen Order ${order.orderId}');
    } else {
      throw Exception('Printer Disconnected');
    }
  }

  // Called by Server via API
  void requestCustomPrint(ReceiptCustomData data) {
    print('📥 Received custom print request for ID: ${data.idTransaksi}');
    _customPrintRequestController.add(data);
  }

  Future<List<BluetoothDevice>> scanDevices() async {
    try {
      _updateStatus('Scanning for devices... (Debug: $debugMode)');
      print('═══════════════════════════════════════');
      print('🔍 BLUETOOTH SCAN REQUESTED');
      print('Debug Mode: $debugMode');
      print('═══════════════════════════════════════');

      if (debugMode) {
        print('🐛 DEBUG MODE: Returning mock devices');
        _updateStatus('DEBUG MODE: Returning mock devices');
        await Future.delayed(const Duration(milliseconds: 500));
        return [
          BluetoothDevice('Mock Printer 1', 'AA:BB:CC:DD:EE:01'),
          BluetoothDevice('Mock Printer 2', 'AA:BB:CC:DD:EE:02'),
          BluetoothDevice('Mock Printer 3', 'AA:BB:CC:DD:EE:03'),
        ];
      }

      print('🔍 Starting Bluetooth discovery...');

      // Check if Bluetooth is available
      final isAvailable = await _bluetooth.isAvailable;
      if (isAvailable != true) {
        final error = 'Bluetooth is not available on this device';
        print('❌ $error');
        _updateStatus('Error: $error');
        throw Exception(error);
      }

      // Check if Bluetooth is enabled
      final isOn = await _bluetooth.isOn;
      if (isOn != true) {
        final error = 'Bluetooth is turned off. Please enable Bluetooth.';
        print('❌ $error');
        _updateStatus('Error: $error');
        throw Exception(error);
      }

      print('✅ Bluetooth is available and enabled');
      print('📡 Fetching bonded devices...');

      final devices = await _bluetooth.getBondedDevices();

      print('═══════════════════════════════════════');
      print('📊 SCAN RESULTS');
      print('Found ${devices.length} bonded device(s)');
      if (devices.isEmpty) {
        print('⚠️ No paired Bluetooth devices found!');
        print('💡 TIP: Pair your printer in System Bluetooth settings first');
      } else {
        for (final device in devices) {
          print('  ✓ ${device.name ?? "Unknown"} (${device.address})');
        }
      }
      print('═══════════════════════════════════════');

      _updateStatus('Found ${devices.length} device(s)');
      return devices;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ BLUETOOTH SCAN ERROR');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════');

      String errorMessage;
      if (e.toString().contains('Bluetooth')) {
        errorMessage = e.toString();
      } else if (e.toString().contains('permission')) {
        errorMessage =
            'Bluetooth permission denied. Please grant permission in settings.';
      } else {
        errorMessage = 'Scan failed: ${e.toString()}';
      }

      _updateStatus('Scan error: $errorMessage');
      return [];
    }
  }

  Future<void> assignPrinterToCategory(
    String categoryId,
    BluetoothDevice device,
  ) async {
    try {
      print('═══════════════════════════════════════');
      print('🔗 ASSIGN PRINTER TO CATEGORY');
      print('Category: $categoryId');
      print('Device: ${device.name} (${device.address})');
      print('═══════════════════════════════════════');

      final category = printerCategories.findById(categoryId);
      if (category == null) {
        final error = 'Category not found: $categoryId';
        print('❌ $error');
        throw Exception(error);
      }

      category.macAddress = device.address;
      category.deviceName = device.name;

      await savePrinterCategories();

      final successMsg = '✓ ${device.name} assigned to ${category.name}';
      print('✅ $successMsg');
      _updateStatus(successMsg);
      print('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ ASSIGN PRINTER ERROR');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════');
      _updateStatus('Assign error: $e');
      rethrow;
    }
  }

  Future<void> removePrinterFromCategory(String categoryId) async {
    final category = printerCategories.findById(categoryId);
    if (category == null) return;

    category.macAddress = null;
    category.deviceName = null;
    await savePrinterCategories();
    _updateStatus('✓ Printer removed from ${category.name}');
  }

  Future<void> addCategory(
    String id,
    String name, {
    esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm58,
  }) async {
    final category = PrinterCategory(id: id, name: name, paperSize: paperSize);
    printerCategories.addCategory(category);
    await savePrinterCategories();
  }

  Future<void> removeCategory(String id) async {
    printerCategories.removeCategory(id);
    await savePrinterCategories();
  }

  Future<void> updateCategoryPaperSize(
    String categoryId,
    esc_pos.PaperSize paperSize,
  ) async {
    final category = printerCategories.findById(categoryId);
    if (category != null) {
      category.paperSize = paperSize;
      await savePrinterCategories();
      _categoriesChangedController.add(null);
    }
  }

  String formatReceipt(String content, {String? serverName}) {
    final lines = <String>[];

    if (businessSettings.showBusinessName) {
      lines.add(businessSettings.businessName);
    }

    if (businessSettings.showAddress) {
      lines.add(businessSettings.address);
    }

    if (businessSettings.showPhoneNumber) {
      lines.add(businessSettings.phoneNumber);
    }

    if (businessSettings.showBusinessName ||
        businessSettings.showAddress ||
        businessSettings.showPhoneNumber) {
      lines.add('---------------------------------------');
    }

    if (businessSettings.showDateTime) {
      final now = DateTime.now();
      final dateStr =
          'Tanggal: ${now.day}/${now.month}/${now.year}, ${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}.${now.second.toString().padLeft(2, '0')}';
      lines.add(dateStr);
    }

    if (businessSettings.showServerId) {
      final server = serverName ?? businessSettings.serverId;
      lines.add('Server: $server');
    }

    if (businessSettings.showDateTime || businessSettings.showServerId) {
      lines.add('---------------------------------------');
    }

    lines.add(content);

    lines.add('---------------------------------------');
    lines.add('Terima kasih Atas Kunjungan Anda! Sampai Jumpa');
    lines.add('kembali');

    return lines.join('\n');
  }

  Future<void> printToCategory(
    String categoryId,
    String content, {
    String? serverName,
  }) async {
    try {
      final category = printerCategories.findById(categoryId);
      if (category == null) {
        throw Exception('Category not found: $categoryId');
      }

      if (!category.isAssigned) {
        throw Exception('No printer assigned to ${category.name}');
      }

      final formattedContent = formatReceipt(content, serverName: serverName);

      _updateStatus('🖨️ Printing to ${category.name}...');
      print('═══════════════════════════════════════');
      print('📤 PRINT REQUEST');
      print('Category: ${category.name}');
      print('MAC: ${category.macAddress}');
      print('Content length: ${content.length} chars');
      print('═══════════════════════════════════════');

      if (debugMode) {
        print('🔧 DEBUG MODE: Simulating print...');
        await Future.delayed(const Duration(milliseconds: 500));
        final logEntry =
            '[${DateTime.now().toString().substring(11, 19)}] PRINT to ${category.name}:\n$formattedContent';
        _printLog.insert(0, logEntry);
        if (_printLog.length > 20) _printLog.removeLast();
        _updateStatus('✓ DEBUG: Simulated print to ${category.name}');
        print('✅ DEBUG: Print simulated successfully');
        return;
      }

      final device = category.toBluetoothDevice();
      if (device == null) {
        throw Exception('Invalid device configuration');
      }

      print('📌 Target MAC: ${category.macAddress}');

      print('🔗 Connecting to printer...');
      _updateStatus('Connecting to printer...');

      final isAlreadyConnected = await _bluetooth.isConnected;
      if (isAlreadyConnected != true) {
        await _bluetooth.connect(device);
        await Future.delayed(const Duration(milliseconds: 500));
        final connected = await _bluetooth.isConnected;
        if (connected != true) {
          throw Exception('Failed to connect to printer');
        }
      }
      print('✅ Connected to printer');

      print('📝 Preparing print data...');
      _updateStatus('Preparing print data...');
      List<int> bytes = [];

      try {
        final profile = await esc_pos.CapabilityProfile.load();
        final generator = esc_pos.Generator(category.paperSize, profile);

        // Initialize printer with proper ESC/POS commands
        // reset() already sends ESC @ (0x1B 0x40), so we don't duplicate it
        bytes.addAll(generator.reset());

        // Wait for printer to wake up and initialize
        await Future.delayed(const Duration(milliseconds: 300));

        // Enable printer (ESC = 1) - wake up from sleep mode
        bytes.addAll([0x1B, 0x3D, 0x01]);

        // Set character code table to PC437 (standard)
        bytes.addAll([0x1B, 0x74, 0x00]);

        // Set print mode to normal
        bytes.addAll([0x1B, 0x21, 0x00]);

        final lines = formattedContent.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) {
            // Empty line - just add line feed
            bytes.addAll([0x0A]);
          } else if (line.startsWith('---')) {
            // Horizontal rule - use dashes for better compatibility
            final dashes = '-' * 42;
            bytes.addAll(
              generator.text(
                dashes,
                styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
              ),
            );
          } else if (line == businessSettings.businessName &&
              businessSettings.showBusinessName) {
            // Business name - bold and centered
            bytes.addAll(
              generator.text(
                line,
                styles: const esc_pos.PosStyles(
                  align: esc_pos.PosAlign.center,
                  bold: true,
                  height: esc_pos.PosTextSize.size2,
                  width: esc_pos.PosTextSize.size1,
                ),
              ),
            );
          } else {
            // Regular text
            bytes.addAll(
              generator.text(
                line,
                styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
              ),
            );
          }
        }

        // Add sufficient feed before cut (increased from 5 to 6)
        bytes.addAll(generator.feed(6));

        print('✅ Print data prepared: ${bytes.length} bytes');
      } catch (prepareError) {
        print('❌ ERROR preparing print data: $prepareError');
        _updateStatus('Failed to prepare print data');
        throw Exception('Prepare failed: $prepareError');
      }

      print('📤 SENDING DATA TO PRINTER...');
      _updateStatus('Sending ${bytes.length} bytes...');

      try {
        // Send data to printer in chunks to prevent buffer overflow
        const int chunkSize = 512; // Max 512 bytes per write
        int offset = 0;
        int chunkNumber = 1;
        final totalChunks = (bytes.length / chunkSize).ceil();

        while (offset < bytes.length) {
          final end =
              (offset + chunkSize < bytes.length)
                  ? offset + chunkSize
                  : bytes.length;
          final chunk = bytes.sublist(offset, end);

          print(
            '📦 Sending chunk $chunkNumber/$totalChunks (${chunk.length} bytes)...',
          );

          // Retry mechanism for each chunk
          bool chunkSent = false;
          int retryCount = 0;
          const maxRetries = 3;

          while (!chunkSent && retryCount < maxRetries) {
            try {
              // Verify connection before sending
              final connected = await _bluetooth.isConnected;
              if (connected != true) {
                throw Exception('Printer disconnected during transmission');
              }

              await _bluetooth.writeBytes(Uint8List.fromList(chunk));
              chunkSent = true;
              print('  ✅ Chunk $chunkNumber sent successfully');

              // Small delay between chunks to let printer process
              if (offset + chunkSize < bytes.length) {
                await Future.delayed(const Duration(milliseconds: 100));
              }
            } catch (e) {
              retryCount++;
              if (retryCount < maxRetries) {
                print(
                  '  ⚠️ Chunk $chunkNumber failed (attempt $retryCount/$maxRetries), retrying...',
                );
                await Future.delayed(const Duration(milliseconds: 500));
              } else {
                throw Exception(
                  'Failed to send chunk $chunkNumber after $maxRetries attempts: $e',
                );
              }
            }
          }

          offset = end;
          chunkNumber++;
        }

        print('✅ All print data sent successfully (${bytes.length} bytes)');

        // Wait longer for printer to process all the data before cutting
        // Increased from 1500ms to 3000ms for better reliability
        print('⏳ Waiting for printer to process data...');
        await Future.delayed(const Duration(milliseconds: 3000));

        // Send paper cut command separately to ensure it executes
        print('✂️ Sending cut command...');
        final profile = await esc_pos.CapabilityProfile.load();
        final generator = esc_pos.Generator(category.paperSize, profile);
        final cutBytes = generator.cut();

        // Retry cut command if needed
        bool cutSent = false;
        int cutRetry = 0;
        const maxCutRetries = 3;

        while (!cutSent && cutRetry < maxCutRetries) {
          try {
            await _bluetooth.writeBytes(Uint8List.fromList(cutBytes));
            cutSent = true;
            print('✅ Cut command sent');
          } catch (e) {
            cutRetry++;
            if (cutRetry < maxCutRetries) {
              print('  ⚠️ Cut command failed, retrying...');
              await Future.delayed(const Duration(milliseconds: 500));
            } else {
              print(
                '  ⚠️ Cut command failed after $maxCutRetries attempts: $e',
              );
              // Don't throw error for cut failure, print was successful
            }
          }
        }

        _updateStatus('✓ Print completed: ${bytes.length} bytes');

        // Final delay to ensure cut completes
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (writeError) {
        print('❌ ERROR writing to printer: $writeError');
        _updateStatus('Failed to write to printer');
        throw Exception('Write failed: $writeError');
      }

      print('═══════════════════════════════════════');
      print('✅ PRINT COMPLETED to ${category.name}');
      print('═══════════════════════════════════════');

      _updateStatus('✓ Print completed to ${category.name}');
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ PRINT ERROR OCCURRED');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('═══════════════════════════════════════');

      // Categorize error and provide helpful message
      String userFriendlyError;
      if (e.toString().contains('Category not found')) {
        userFriendlyError =
            'Printer category not found. Please check category ID.';
      } else if (e.toString().contains('No printer assigned')) {
        userFriendlyError =
            'No printer assigned to this category. Please assign a printer first.';
      } else if (e.toString().contains('Failed to connect')) {
        userFriendlyError =
            'Cannot connect to printer. Check if printer is on and paired.';
      } else if (e.toString().contains('Write failed') ||
          e.toString().contains('writeBytes')) {
        userFriendlyError =
            'Failed to send data to printer. Check Bluetooth connection and try again.';
      } else if (e.toString().contains('Prepare failed')) {
        userFriendlyError =
            'Failed to prepare print data. Check paper size settings.';
      } else if (e.toString().contains('Bluetooth')) {
        userFriendlyError = 'Bluetooth error: ${e.toString()}';
      } else {
        userFriendlyError = 'Print failed: ${e.toString()}';
      }

      _updateStatus('❌ $userFriendlyError');

      print('💡 TROUBLESHOOTING TIPS:');
      print('  1. Check if printer is turned on');
      print('  2. Verify Bluetooth is enabled');
      print('  3. Ensure printer is paired in system settings');
      print('  4. Try disconnecting and reconnecting');
      print('  5. Check if paper is loaded correctly');
      print('═══════════════════════════════════════');

      rethrow;
    }
  }

  // --- PRINT IMAGE (New) ---
  Future<void> printReceiptImage(
    String categoryId,
    Uint8List imageBytes,
  ) async {
    try {
      final category = printerCategories.findById(categoryId);
      if (category == null) {
        throw Exception('Category not found: $categoryId');
      }

      if (!category.isAssigned) {
        throw Exception('No printer assigned to ${category.name}');
      }

      _updateStatus('🖨️ Printing IMAGE to ${category.name}...');

      if (debugMode) {
        await Future.delayed(const Duration(milliseconds: 1000));
        final logEntry =
            '[${DateTime.now().toString().substring(11, 19)}] PRINT IMAGE to ${category.name} (${imageBytes.length} bytes)';
        _printLog.insert(0, logEntry);
        _updateStatus('✓ DEBUG: Simulated image print');
        return;
      }

      final device = category.toBluetoothDevice();
      if (device == null) throw Exception('Invalid device config');

      final isAlreadyConnected = await _bluetooth.isConnected;
      if (isAlreadyConnected != true) {
        _updateStatus('Connecting...');
        await _bluetooth.connect(device);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Prepare Image
      _updateStatus('Processing image...');
      final image = img.decodePng(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Convert to ESC/POS commands
      final profile = await esc_pos.CapabilityProfile.load();
      final generator = esc_pos.Generator(category.paperSize, profile);

      List<int> bytes = [];
      bytes.addAll(generator.reset());
      bytes.addAll(generator.image(image));
      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());

      _updateStatus('Sending image data...');
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));

      _updateStatus('✓ Image Printed to ${category.name}');
      print('✅ Image print success');
    } catch (e) {
      print('❌ Print Image Error: $e');
      _updateStatus('Print Image Error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
      _updateStatus('Disconnected');
    } catch (e) {
      _updateStatus('Disconnect error: $e');
    }
  }

  Future<bool> isConnected() async {
    try {
      final connected = await _bluetooth.isConnected;
      _isConnected = connected ?? false;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void dispose() {
    _statusController.close();
    _customPrintRequestController.close();
    _categoriesChangedController.close();
  }
}
