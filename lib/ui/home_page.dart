import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer_service.dart';
import '../server/server.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PrinterService _printerService;
  late LocalServer _server;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _printerService = PrinterService();
    _server = LocalServer(_printerService);

    // Start the server
    _startServer();

    // Listen to printer status updates
    _printerService.statusStream.listen((status) {
      setState(() {
        _addLog('Printer: $status');
      });
    });

    // Listen to server logs
    _server.logStream.listen((log) {
      setState(() {
        _addLog(log);
      });
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, message);
      if (_logs.length > 50) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _startServer() async {
    try {
      await _server.start();
      setState(() {});
    } catch (e) {
      _addLog('Server error: $e');
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final devices = await _printerService.scanDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      _addLog('Scan error: $e');
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _assignPrinter(String categoryId) async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device first')),
      );
      return;
    }

    try {
      await _printerService.assignPrinterToCategory(
        categoryId,
        _selectedDevice!,
      );

      if (mounted) {
        final category = _printerService.printerCategories.categories
            .firstWhere((c) => c.id == categoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.name} printer assigned: ${_selectedDevice!.name}',
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
      }
    }
  }

  void _toggleDebugMode() {
    setState(() {
      _printerService.debugMode = !_printerService.debugMode;
      _addLog('Debug mode: ${_printerService.debugMode ? "ON" : "OFF"}');
    });
  }

  void _showPrintLog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Print Log (Debug Mode)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child:
                  _printerService.printLog.isEmpty
                      ? const Center(child: Text('No print jobs yet'))
                      : ListView.builder(
                        itemCount: _printerService.printLog.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _printerService.printLog[index],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Color _getCategoryColor(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('dapur') || nameLower.contains('kitchen')) {
      return Colors.orange;
    } else if (nameLower.contains('kasir') ||
        nameLower.contains('cashier') ||
        nameLower.contains('pos')) {
      return Colors.green;
    } else if (nameLower.contains('bar')) {
      return Colors.purple;
    }
    return Colors.blue;
  }

  String _getCategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('dapur') || nameLower.contains('kitchen')) {
      return '🍳';
    } else if (nameLower.contains('kasir') ||
        nameLower.contains('cashier') ||
        nameLower.contains('pos')) {
      return '💰';
    } else if (nameLower.contains('bar')) {
      return '🍺';
    }
    return '🖨️';
  }

  Future<void> _removePrinter(String categoryId) async {
    await _printerService.removePrinterFromCategory(categoryId);
    setState(() {});
  }

  Widget _buildPrinterCard(String categoryId, String title, Color color) {
    final category =
        _printerService.printerCategories.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.print, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                if (category?.deviceName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    category!.deviceName!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    category.macAddress ?? 'Unknown Address',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Not assigned',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          if (category?.macAddress != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removePrinter(categoryId),
              tooltip: 'Remove printer',
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _server.dispose();
    _printerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PrintGateway'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          SettingsPage(printerService: _printerService),
                ),
              );
              setState(() {});
            },
            tooltip: 'Settings',
          ),
        ],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Server status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color:
                  _server.isRunning
                      ? Colors.green.shade100
                      : Colors.red.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _server.isRunning ? Icons.check_circle : Icons.cancel,
                        color: _server.isRunning ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _server.isRunning
                              ? 'Server running at http://${LocalServer.host}:${LocalServer.port}'
                              : 'Server stopped',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_printerService.debugMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEBUG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Printer status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Printers: ${_printerService.currentStatus}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Dynamic printer categories
                  ..._printerService.printerCategories.categories.map((
                    category,
                  ) {
                    final color = _getCategoryColor(category.name);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildPrinterCard(
                        category.id,
                        '${_getCategoryIcon(category.name)} ${category.name}',
                        color,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Debug Controls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.amber.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔧 Testing Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _printerService.debugMode
                              ? 'Debug mode aktif (tidak perlu printer fisik)'
                              : 'Debug mode OFF (butuh printer fisik)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Switch(
                        value: _printerService.debugMode,
                        onChanged: (value) => _toggleDebugMode(),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                  if (_printerService.debugMode) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showPrintLog,
                        icon: const Icon(Icons.list_alt),
                        label: Text(
                          'View Print Log (${_printerService.printLog.length})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Scan button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanDevices,
                      icon:
                          _isScanning
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.search),
                      label: Text(
                        _isScanning
                            ? 'Scanning...'
                            : _printerService.debugMode
                            ? 'Scan Mock Devices'
                            : 'Scan Devices',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // Assign buttons (only show if device selected)
                  if (_selectedDevice != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Select category to assign:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._printerService.printerCategories.categories.map((
                      category,
                    ) {
                      final color = _getCategoryColor(category.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _assignPrinter(category.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Assign to ${category.name}'),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // Device list
            if (_devices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Devices:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              Container(
                height: 150,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isSelected =
                        _selectedDevice?.address == device.address;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.blue.shade100,
                      leading: const Icon(Icons.bluetooth),
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address ?? 'Unknown Address'),
                      onTap: () {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            // Logs
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Console Log:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                reverse: false,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
