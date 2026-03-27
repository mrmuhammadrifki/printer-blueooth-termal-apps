import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
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

    _startServer();

    _printerService.statusStream.listen((status) {
      setState(() {
        _addLog('Printer: $status');
      });
    });

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

  Future<void> _assignPrinterToCategory(String categoryId) async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device first')),
      );
      return;
    }

    try {
      await _printerService.assignPrinterToCategory(
          categoryId, _selectedDevice!);

      if (mounted) {
        final category = _printerService.printerCategories.findById(categoryId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category?.name} printer assigned: ${_selectedDevice!.name}',
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removePrinterFromCategory(String categoryId) async {
    try {
      await _printerService.removePrinterFromCategory(categoryId);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PrintGateway'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(printerService: _printerService),
                ),
              );
              setState(() {});
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(
              _printerService.debugMode
                  ? Icons.bug_report
                  : Icons.bug_report_outlined,
            ),
            onPressed: () {
              setState(() {
                _printerService.debugMode = !_printerService.debugMode;
              });
              _addLog(
                'Debug mode: ${_printerService.debugMode ? "ON" : "OFF"}',
              );
            },
            tooltip: 'Toggle Debug Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildServerStatus(),
          _buildPrinterCategories(),
          _buildDeviceList(),
          _buildLogs(),
        ],
      ),
    );
  }

  Widget _buildServerStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _server.isRunning ? Colors.green.shade100 : Colors.red.shade100,
      child: Row(
        children: [
          Icon(
            _server.isRunning ? Icons.check_circle : Icons.error,
            color: _server.isRunning ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _server.isRunning ? 'Server Running' : 'Server Stopped',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_server.isRunning)
                  Text(
                    'http://${LocalServer.host}:${LocalServer.port}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterCategories() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Printer Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _printerService.printerCategories.categories.map((category) {
              final isAssigned = category.isAssigned;
              return InkWell(
                onTap: () {
                  if (isAssigned) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(category.name),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device: ${category.deviceName}'),
                            Text('MAC: ${category.macAddress}'),
                            Text(
                              'Paper Size: ${category.paperSize == esc_pos.PaperSize.mm58 ? "58mm" : "80mm"}',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _removePrinterFromCategory(category.id);
                            },
                            child: const Text('Remove'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _assignPrinterToCategory(category.id);
                  }
                },
                child: Chip(
                  avatar: Icon(
                    isAssigned ? Icons.check_circle : Icons.print,
                    color: isAssigned ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  label: Text(category.name),
                  backgroundColor:
                      isAssigned ? Colors.green.shade50 : Colors.grey.shade200,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Available Devices',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanDevices,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child: Text('No devices found. Press Scan to start.'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected = _selectedDevice == device;

                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          device.name ?? 'Unknown Device',
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(device.address ?? 'No address'),
                        selected: isSelected,
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
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Server Logs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
    );
  }

  @override
  void dispose() {
    _server.stop();
    _printerService.dispose();
    super.dispose();
  }
}
