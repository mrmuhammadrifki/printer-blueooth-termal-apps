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
- ✅ Auto-reconnects to saved printer on startup
- ✅ Real-time status monitoring

## API Usage

```bash
curl -X POST http://127.0.0.1:18181/print \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World!"}'
```

## Documentation

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for complete documentation including:

- Full installation instructions
- API reference
- Building APKs
- Troubleshooting
- Code examples

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
