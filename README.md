# PrintGateway 🖨️

A Flutter Android application that bridges websites to Bluetooth thermal printers via a local HTTP server.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
```

## What It Does

- ✅ Runs local HTTP server on `http://127.0.0.1:18181`
- ✅ Connects to Bluetooth ESC/POS thermal printers
- ✅ Accepts POST requests from websites to print text
- ✅ **Multi-printer support** (Kasir, Dapur, etc.)
- ✅ Auto-reconnects to saved printer on startup
- ✅ Real-time status monitoring
- ✅ **Debug Mode** for testing without physical printer

## 🧪 Testing Without Printer?

**No problem!** Enable **Debug Mode** to test without physical printer:

1. Run the app → Go to **Settings** → Toggle **Debug Mode ON**
2. Scan & assign **Mock Printers** (simulated devices)
3. Use [test_complete.html](test_complete.html) for comprehensive testing
4. Check print logs in **Dashboard → Debug Print Logs**

**👉 See [TESTING_GUIDE.md](TESTING_GUIDE.md) for complete testing instructions**

## API Usage

```bash
curl -X POST http://127.0.0.1:18181/print \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World!"}'
```

## Documentation

**📘 Main Guides:**
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - **Testing without physical printer (Debug Mode)**
- [FRONTEND_INTEGRATION_GUIDE.md](FRONTEND_INTEGRATION_GUIDE.md) - API reference & integration
- [TROUBLESHOOTING_BLUEPRINT.md](TROUBLESHOOTING_BLUEPRINT.md) - Common issues & solutions
- [UPDATE_LOG.md](UPDATE_LOG.md) - Version history & changes

**🧪 Test Files:**
- [test_complete.html](test_complete.html) - Complete test suite (recommended)
- [test_page.html](test_page.html) - Simple test page
- [test_multi_printer.html](test_multi_printer.html) - Multi-printer test

## Requirements

- Flutter SDK 3.7.0+
- Android device with Bluetooth
- ESC/POS thermal printer (RPP02N or compatible)

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── server/server.dart        # HTTP server
├── services/printer_service.dart  # Bluetooth logic
└── ui/home_page.dart         # UI
```

## License

Educational/Development use
