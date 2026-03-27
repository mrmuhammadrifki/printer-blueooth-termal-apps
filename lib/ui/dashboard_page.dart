import 'dart:async';
import 'package:flutter/material.dart';
import '../services/printer_service.dart';
import '../server/server.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'preview_receipt_page.dart';

class DashboardPage extends StatefulWidget {
  final PrinterService printerService;

  const DashboardPage({super.key, required this.printerService});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  LocalServer? _server;
  bool _isServerRunning = false;
  final List<String> _serverLogs = [];
  StreamSubscription? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _server = LocalServer(widget.printerService);
    _server!.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _serverLogs.insert(0, log);
          if (_serverLogs.length > 50) _serverLogs.removeLast();
        });
      }
    });

    _categoriesSubscription = widget.printerService.categoriesChangedStream
        .listen((_) {
          if (mounted) {
            setState(() {});
          }
        });
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
      await _server?.stop();
      setState(() => _isServerRunning = false);
    } else {
      await _server?.start();
      setState(() => _isServerRunning = true);
    }
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.printerService.printerCategories.categories;
    final assignedCount = categories.where((c) => c.isAssigned).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.print_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OrbitPrint',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Printer Gateway',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _isServerRunning
                                  ? const Color(0xFF00FFA3)
                                  : Colors.grey,
                          boxShadow:
                              _isServerRunning
                                  ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00FFA3,
                                      ).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isServerRunning ? 'Server Online' : 'Server Offline',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _toggleServer,
                        icon: Icon(
                          _isServerRunning ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(_isServerRunning ? 'Stop' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isServerRunning
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_isServerRunning) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'http://${LocalServer.host}:${LocalServer.port}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.category_rounded,
                  title: 'Categories',
                  value: '${categories.length}',
                  color: const Color(0xFF00D9FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Assigned',
                  value: '$assignedCount',
                  color: const Color(0xFF00FFA3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Test Tools
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.blue),
              ),
              title: const Text('Preview Layout Struk (Visual Test)'),
              subtitle: const Text('Lihat tampilan struk tanpa printer'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PreviewReceiptPage(
                          printerService: widget.printerService,
                        ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Categories Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Printer Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  category.isAssigned
                                      ? const Color(0xFF00FFA3).withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.print_rounded,
                              color:
                                  category.isAssigned
                                      ? const Color(0xFF00FFA3)
                                      : Colors.grey,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  category.isAssigned
                                      ? category.deviceName ?? 'Connected'
                                      : 'Not assigned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        category.isAssigned
                                            ? const Color(0xFF00FFA3)
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.paperSize == esc_pos.PaperSize.mm58
                                  ? '58mm'
                                  : '80mm',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Debug Print Logs (when debug mode is on)
          if (widget.printerService.debugMode &&
              widget.printerService.printLog.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Debug Print Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: widget.printerService.printLog.length,
                        itemBuilder: (context, index) {
                          final log = widget.printerService.printLog[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.orange.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.orange[300],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Server Logs
          if (_serverLogs.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _serverLogs.clear());
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _serverLogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              _serverLogs[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
