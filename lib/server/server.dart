import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../services/printer_service.dart';
import '../models/receipt_custom_data.dart';
import '../models/kitchen_order.dart';

class LocalServer {
  HttpServer? _server;
  final PrinterService printerService;
  final _logController = StreamController<String>.broadcast();

  Stream<String> get logStream => _logController.stream;

  static const String host = '127.0.0.1';
  static const int port = 18181;

  bool get isRunning => _server != null;

  LocalServer(this.printerService);

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    _logController.add(logMessage);
  }

  /// Start the HTTP server
  Future<void> start() async {
    if (_server != null) {
      _log('Server already running');
      return;
    }

    try {
      final router = Router();

      // POST /print endpoint
      router.post('/print', _handlePrint);

      // POST /print-category endpoint
      router.post('/print-category', _handlePrintCategory);

      // GET / endpoint for health check
      router.get('/', _handleRoot);

      // GET /test_multi_printer.html
      router.get('/test_multi_printer.html', _handleTestMultiPrinter);

      // GET /test_page.html
      router.get('/test_page.html', _handleTestPage);

      // POST /print-custom-receipt endpoint
      router.post('/print-custom-receipt', _handlePrintCustom);

      // POST /print-kitchen-order endpoint
      router.post('/print-kitchen-order', _handlePrintKitchenOrder);

      // Middleware for logging
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsHeaders())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, host, port);

      _log('Server started at http://$host:$port');
    } catch (e) {
      _log('Failed to start server: $e');
      rethrow;
    }
  }

  /// Stop the HTTP server
  Future<void> stop() async {
    if (_server == null) {
      _log('Server not running');
      return;
    }

    try {
      await _server?.close(force: true);
      _server = null;
      _log('Server stopped');
    } catch (e) {
      _log('Error stopping server: $e');
    }
  }

  /// Handle POST /print
  Future<Response> _handlePrint(Request request) async {
    try {
      final body = await request.readAsString();
      _log('Received print request: $body');

      final json = jsonDecode(body) as Map<String, dynamic>;
      final text = json['text'] as String?;
      final mac = json['mac'] as String?; // MAC address parameter

      if (text == null || text.isEmpty) {
        _log('Error: Missing or empty text field');
        return Response(
          400,
          body: jsonEncode({
            'status': 'error',
            'message': 'Missing or empty "text" field',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // If MAC address provided, print to that specific printer
      if (mac != null && mac.isNotEmpty) {
        _log('Printing to MAC: $mac');

        // Verify MAC is assigned
        final categories = printerService.printerCategories.categories;
        final hasPrinter = categories.any(
          (c) => c.macAddress != null && c.macAddress == mac,
        );

        if (!hasPrinter) {
          _log('Error: MAC address $mac not assigned');
          return Response(
            404,
            body: jsonEncode({
              'status': 'error',
              'message':
                  'Printer with MAC $mac is not assigned. Please assign it first.',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Find category with this MAC and print to it
        final category = categories.firstWhere((c) => c.macAddress == mac);
        await printerService.printToCategory(category.id, text);
        _log('Print successful to $mac');

        return Response.ok(
          jsonEncode({'status': 'ok', 'message': 'Printed to $mac'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Legacy: no MAC provided, use default printer (kasir)
      final categories = printerService.printerCategories.categories;
      final assignedCategories = categories.where((c) => c.isAssigned).toList();

      if (assignedCategories.isEmpty) {
        _log('Error: No printers assigned');
        return Response(
          503,
          body: jsonEncode({
            'status': 'error',
            'message': 'No printers assigned. Please assign printers first.',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Print using default category (kasir or first available)
      final defaultCategory = categories.firstWhere(
        (c) => c.id == 'kasir' && c.isAssigned,
        orElse: () => assignedCategories.first,
      );
      await printerService.printToCategory(defaultCategory.id, text);
      _log('Print successful (default printer: ${defaultCategory.name})');

      return Response.ok(
        jsonEncode({'status': 'ok', 'message': 'Printed'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log('Print error: $e');
      return Response(
        500,
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handle POST /print-category
  Future<Response> _handlePrintCategory(Request request) async {
    try {
      final body = await request.readAsString();
      _log('Received print-category request: $body');

      final json = jsonDecode(body) as Map<String, dynamic>;
      final categoryId = json['categoryId'] as String?;
      final text = json['text'] as String?;
      final serverName = json['serverName'] as String?; // Optional server name

      if (categoryId == null || categoryId.isEmpty) {
        _log('Error: Missing categoryId');
        return Response(
          400,
          body: jsonEncode({
            'status': 'error',
            'message': 'Missing "categoryId" field',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (text == null || text.isEmpty) {
        _log('Error: Missing text');
        return Response(
          400,
          body: jsonEncode({
            'status': 'error',
            'message': 'Missing "text" field',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find category
      final category = printerService.printerCategories.findById(categoryId);
      if (category == null) {
        _log('Error: Category not found: $categoryId');
        return Response(
          404,
          body: jsonEncode({
            'status': 'error',
            'message': 'Category not found: $categoryId',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!category.isAssigned) {
        _log('Error: No printer assigned to $categoryId');
        return Response(
          503,
          body: jsonEncode({
            'status': 'error',
            'message': 'No printer assigned to ${category.name}',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Print to category with optional serverName
      await printerService.printToCategory(
        categoryId,
        text,
        serverName: serverName,
      );
      _log('Print successful to ${category.name}');

      return Response.ok(
        jsonEncode({'status': 'ok', 'message': 'Printed to ${category.name}'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log('Print-category error: $e');
      return Response(
        500,
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handle POST /print-custom-receipt
  Future<Response> _handlePrintCustom(Request request) async {
    try {
      final body = await request.readAsString();
      _log('Received custom receipt request (Widget-based)');

      final json = jsonDecode(body) as Map<String, dynamic>;
      final data = ReceiptCustomData.fromJson(json);

      // Trigger the UI to render and print
      printerService.requestCustomPrint(data);

      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'message': 'Custom receipt print requested',
          'id_transaksi': data.idTransaksi,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log('Custom Print error: $e');
      return Response(
        500,
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handle POST /print-kitchen-order
  Future<Response> _handlePrintKitchenOrder(Request request) async {
    try {
      final body = await request.readAsString();
      _log('Received kitchen order request');

      final json = jsonDecode(body) as Map<String, dynamic>;
      final order = KitchenOrder.fromJson(json);

      // Direct print (text based)
      await printerService.printKitchenOrder(order);

      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'message': 'Kitchen order printed',
          'orderId': order.orderId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log('Kitchen Print error: $e');
      return Response(
        500,
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handle GET /
  Response _handleRoot(Request request) {
    _log('Health check requested');

    final categories = printerService.printerCategories.categories;
    final categoryInfo =
        categories
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'assigned': c.isAssigned,
                'mac': c.macAddress ?? '',
              },
            )
            .toList();

    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'message': 'PrintGateway server is running',
        'endpoints': [
          '/print',
          '/print-category',
          '/test_multi_printer.html',
          '/test_page.html',
        ],
        'categories': categoryInfo,
        'category_count': categories.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Handle GET /test_multi_printer.html
  Response _handleTestMultiPrinter(Request request) {
    _log('Serving test_multi_printer.html');
    return Response.ok(
      _testMultiPrinterHtml,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  /// Handle GET /test_page.html
  Response _handleTestPage(Request request) {
    _log('Serving test_page.html');
    return Response.ok(
      _testPageHtml,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  // Embedded HTML for test_multi_printer.html
  static const String _testMultiPrinterHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrintGateway Multi-Printer Test</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 { font-size: 32px; margin-bottom: 10px; }
        .header p { opacity: 0.9; }
        .content { padding: 30px; }
        .status {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: bold;
        }
        .status.success { background: #d4edda; color: #155724; }
        .status.error { background: #f8d7da; color: #721c24; }
        .status.info { background: #d1ecf1; color: #0c5460; }
        .printers {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        .printer-card {
            border: 3px solid #e0e0e0;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }
        .printer-card.dapur { border-color: #ff9800; }
        .printer-card.kasir { border-color: #4caf50; }
        .printer-icon { font-size: 48px; margin-bottom: 10px; }
        .printer-name { font-size: 20px; font-weight: bold; margin-bottom: 5px; }
        .printer-card.dapur .printer-name { color: #ff9800; }
        .printer-card.kasir .printer-name { color: #4caf50; }
        .printer-mac { font-size: 12px; color: #666; margin-bottom: 15px; }
        textarea {
            width: 100%;
            min-height: 120px;
            padding: 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            resize: vertical;
            margin-bottom: 15px;
        }
        button {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin: 5px;
        }
        .btn-dapur { background: #ff9800; color: white; }
        .btn-kasir { background: #4caf50; color: white; }
        .btn-primary { background: #667eea; color: white; }
        .response {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-top: 20px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            max-height: 300px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖨️🖨️ PrintGateway</h1>
            <p>Multi-Printer Test Interface</p>
        </div>
        <div class="content">
            <div id="status" class="status info">Loading...</div>
            <div class="printers">
                <div class="printer-card dapur">
                    <div class="printer-icon">🍳</div>
                    <div class="printer-name">Dapur</div>
                    <div class="printer-mac" id="dapurMac">-</div>
                    <button class="btn-dapur" onclick="testDapur()">Test Print</button>
                </div>
                <div class="printer-card kasir">
                    <div class="printer-icon">💰</div>
                    <div class="printer-name">Kasir</div>
                    <div class="printer-mac" id="kasirMac">-</div>
                    <button class="btn-kasir" onclick="testKasir()">Test Print</button>
                </div>
            </div>
            <textarea id="textDapur" placeholder="Text untuk Dapur...">ORDER DAPUR\\n================\\nTest Order</textarea>
            <button class="btn-dapur" onclick="printDapur()">Print ke Dapur</button>
            <textarea id="textKasir" placeholder="Text untuk Kasir...">RECEIPT\\n================\\nTest Receipt</textarea>
            <button class="btn-kasir" onclick="printKasir()">Print ke Kasir</button>
            <button class="btn-primary" onclick="printBoth()">Print Keduanya</button>
            <div id="response" class="response" style="display:none;"></div>
        </div>
    </div>
    <script>
        const API = 'http://127.0.0.1:18181';
        let categories = [];
        
        async function loadPrinters() {
            try {
                const r = await fetch(API);
                const d = await r.json();
                categories = d.categories || [];
                
                const assignedCount = categories.filter(c => c.assigned).length;
                document.getElementById('status').className = 'status success';
                document.getElementById('status').textContent = '✓ Connected: ' + assignedCount + '/' + d.category_count + ' printer(s)';
                
                // Update dapur info
                const dapur = categories.find(c => c.id === 'dapur');
                if (dapur && dapur.assigned) {
                    document.getElementById('dapurMac').textContent = dapur.mac || '-';
                } else {
                    document.getElementById('dapurMac').textContent = 'Not assigned';
                }
                
                // Update kasir info
                const kasir = categories.find(c => c.id === 'kasir');
                if (kasir && kasir.assigned) {
                    document.getElementById('kasirMac').textContent = kasir.mac || '-';
                } else {
                    document.getElementById('kasirMac').textContent = 'Not assigned';
                }
            } catch(e) {
                document.getElementById('status').className = 'status error';
                document.getElementById('status').textContent = '✗ Cannot connect to server';
            }
        }
        
        async function printCategory(categoryId, text, serverName = null) {
            const body = { categoryId, text };
            if (serverName) body.serverName = serverName;
            
            const r = await fetch(API + '/print-category', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(body)
            });
            const d = await r.json();
            document.getElementById('response').style.display = 'block';
            document.getElementById('response').textContent = JSON.stringify(d, null, 2);
            return d;
        }
        
        function testDapur() { 
            printCategory('dapur', 'TEST PRINT DAPUR\\n' + new Date().toLocaleString(), 'Server Rudi'); 
        }
        
        function testKasir() { 
            printCategory('kasir', 'TEST PRINT KASIR\\n' + new Date().toLocaleString(), 'Server Rifki'); 
        }
        
        function printDapur() { 
            const text = document.getElementById('textDapur').value;
            printCategory('dapur', text, 'Server Rudi'); 
        }
        
        function printKasir() { 
            const text = document.getElementById('textKasir').value;
            printCategory('kasir', text, 'Server Rifki'); 
        }
        
        async function printBoth() {
            const dapurText = document.getElementById('textDapur').value;
            const kasirText = document.getElementById('textKasir').value;
            await printCategory('dapur', dapurText, 'Server Rudi');
            setTimeout(() => printCategory('kasir', kasirText, 'Server Rifki'), 1000);
        }
        
        window.onload = loadPrinters;
    </script>
</body>
</html>
''';

  // Embedded HTML for test_page.html (simple version)
  static const String _testPageHtml = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PrintGateway Test</title>
    <style>
        body { font-family: Arial; padding: 20px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #333; }
        textarea { width: 100%; height: 150px; margin: 10px 0; padding: 10px; }
        button { padding: 10px 20px; margin: 5px; font-size: 16px; cursor: pointer; }
        .result { margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>PrintGateway Test</h1>
        <textarea id="text" placeholder="Enter text to print...">Test Print\\nFrom Web Interface</textarea>
        <br>
        <button onclick="testPrint()">Test Print</button>
        <div class="result" id="result" style="display:none;"></div>
    </div>
    <script>
        async function testPrint() {
            const text = document.getElementById('text').value;
            try {
                const response = await fetch('http://127.0.0.1:18181/print', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({text})
                });
                const data = await response.json();
                document.getElementById('result').style.display = 'block';
                document.getElementById('result').textContent = JSON.stringify(data, null, 2);
            } catch(e) {
                document.getElementById('result').style.display = 'block';
                document.getElementById('result').textContent = 'Error: ' + e.message;
            }
        }
    </script>
</body>
</html>
''';

  /// CORS middleware
  Middleware _corsHeaders() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeadersMap());
        }

        final response = await handler(request);
        return response.change(headers: _corsHeadersMap());
      };
    };
  }

  Map<String, String> _corsHeadersMap() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
  }

  void dispose() {
    stop();
    _logController.close();
  }
}
