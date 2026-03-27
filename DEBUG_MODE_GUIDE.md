# 🐛 Debug Mode Guide - OrbitPrint

## Overview

OrbitPrint memiliki **Debug Mode** yang memungkinkan testing printer tanpa perangkat fisik. Sangat berguna untuk development dan testing integrasi frontend.

---

## 🎯 Cara Mengaktifkan Debug Mode

### Via Settings UI

1. Buka aplikasi OrbitPrint
2. Tab ke **Settings** (icon ⚙️ di bottom navigation)
3. Scroll ke section **Developer Options**
4. Toggle switch **Debug Mode**
5. Akan muncul notifikasi "Debug mode enabled"

### Via Code (Manual)

```dart
final printerService = PrinterService();
printerService.debugMode = true;
```

---

## ✨ Fitur Debug Mode

Ketika debug mode aktif:

### 1. **Simulated Printing**

- Print request tidak dikirim ke printer fisik
- Sistem akan simulasi delay (~500ms) untuk meniru proses printing
- Tidak perlu koneksi Bluetooth

### 2. **Mock Devices**

Saat scan devices, akan muncul 3 mock printer:

- Mock Printer 1 (MAC: AA:BB:CC:DD:EE:01)
- Mock Printer 2 (MAC: AA:BB:CC:DD:EE:02)
- Mock Printer 3 (MAC: AA:BB:CC:DD:EE:03)

### 3. **Print Logs**

Semua print request dicatat dengan format:

```
[HH:MM:SS] PRINT to {category_name}:
{full receipt content}
```

Logs bisa dilihat di **Dashboard** page (maks 20 entries terbaru).

### 4. **Visual Indicator**

- Badge orange "🐛 DEBUG MODE" di Dashboard
- Warning box di Settings page
- Orange color scheme pada debug-related UI

---

## 📋 Testing Workflow

### Step 1: Setup

```bash
# Jalankan app
flutter run
```

### Step 2: Enable Debug Mode

1. Settings → Developer Options → Toggle Debug Mode ON
2. Kembali ke Dashboard

### Step 3: Assign Mock Printers

1. Tab ke **Printers**
2. Tap **Scan Devices**
3. Pilih kategori (kasir/dapur)
4. Assign mock printer ke kategori

### Step 4: Test dari Frontend

```javascript
// Test print ke kasir
fetch('http://127.0.0.1:18181/print-category', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    categoryId: 'kasir',
    text: 'Test receipt\nItem 1: Rp 10.000\nTotal: Rp 10.000',
  }),
})
  .then((res) => res.json())
  .then((data) => console.log('Print result:', data));
```

### Step 5: Lihat Logs

1. Kembali ke **Dashboard**
2. Scroll ke section **Debug Print Logs**
3. Lihat output print yang disimulasi

---

## 🧪 Testing Scenarios

### Scenario 1: Test Single Category Print

```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"text\":\"Test Receipt\\nItem 1: Rp 10000\"}"
```

Expected Output di Dashboard Logs:

```
[12:30:45] PRINT to Kasir:
Jogja Billiard Bogor
Jl. Example No. 123
0251-1234567
---------------------------------------
Tanggal: 12/12/2025, 12.30.45
---------------------------------------
Test Receipt
Item 1: Rp 10000
---------------------------------------
Terima kasih Atas Kunjungan Anda! Sampai Jumpa
kembali
```

### Scenario 2: Test Multi-Category Print

```javascript
// Print receipt to kasir
await fetch('http://127.0.0.1:18181/print-category', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    categoryId: 'kasir',
    text: 'Customer Receipt\nTable: 5\nTotal: Rp 50.000',
  }),
});

// Print kitchen order to dapur
await fetch('http://127.0.0.1:18181/print-category', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    categoryId: 'dapur',
    text: 'KITCHEN ORDER\nTable: 5\nNasi Goreng x2\nEs Teh x1',
  }),
});
```

### Scenario 3: Test Error Handling

```bash
# Test category not found
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"invalid\",\"text\":\"test\"}"

# Expected response:
# {"status":"error","message":"Category not found: invalid"}
```

---

## 📊 Log Format

### Print Log Entry

```
[12:30:45] PRINT to Kasir:
{formatted receipt content with business header}
```

### Server Activity Log

```
[Server] 12:30:45 - POST /print-category (categoryId: kasir)
[Server] 12:30:45 - ✓ Print completed to kasir
```

---

## 🔄 Integration Testing dengan Frontend

### Test API Connectivity

```javascript
// healthCheck.js
async function checkPrinterGateway() {
  try {
    const response = await fetch('http://127.0.0.1:18181/');
    const data = await response.json();

    console.log('Status:', data.status);
    console.log('Categories:', data.categories);
    console.log('Category Count:', data.category_count);

    return data.status === 'ok';
  } catch (error) {
    console.error('Gateway not available:', error);
    return false;
  }
}
```

### Test Print Function

```javascript
// printerTest.js
async function testPrint() {
  const testReceipt = {
    categoryId: 'kasir',
    text: [
      'TEST RECEIPT',
      'Tanggal: ' + new Date().toLocaleString('id-ID'),
      '---------------------------------------',
      'Item 1 (x1)                 Rp 10.000',
      'Item 2 (x2)                 Rp 20.000',
      '',
      'Subtotal:                   Rp 30.000',
      'TOTAL:                      Rp 30.000',
    ].join('\n'),
  };

  const response = await fetch('http://127.0.0.1:18181/print-category', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(testReceipt),
  });

  const result = await response.json();
  console.log('Print Result:', result);

  // Check OrbitPrint Dashboard → Debug Print Logs
}
```

---

## 🎓 Tips & Best Practices

### ✅ DO

- Enable debug mode saat development frontend
- Test semua kategori printer (kasir, dapur, custom)
- Verify logs di Dashboard setelah setiap print request
- Test error scenarios (invalid category, printer not assigned)
- Use mock printers untuk parallel development

### ❌ DON'T

- Jangan lupa disable debug mode di production
- Jangan assign mock printer untuk production use
- Jangan expect real Bluetooth connection di debug mode

---

## 🚀 Production Ready Checklist

Sebelum deploy ke production:

- [ ] Disable debug mode di Settings
- [ ] Remove semua mock printer assignments
- [ ] Assign real Bluetooth printers
- [ ] Test actual printing ke physical devices
- [ ] Verify business info di Settings
- [ ] Clear all debug logs

---

## 🐛 Troubleshooting

### Q: Debug logs tidak muncul di Dashboard?

**A:** Pastikan:

1. Debug mode sudah ON di Settings
2. Ada printer yang di-assign ke kategori
3. Sudah kirim print request via API
4. Refresh dashboard (pull to refresh)

### Q: Mock devices tidak muncul saat scan?

**A:** Pastikan:

1. Debug mode aktif SEBELUM scan
2. Restart scan jika perlu

### Q: Print logs tidak ter-format dengan business header?

**A:** Check Settings → Business Info:

1. Toggle "Show Business Name" dll sudah ON
2. Business info sudah diisi dan saved

### Q: Bagaimana cara clear logs?

**A:**

- Server logs: Tap "Clear" button di Dashboard
- Print logs: Disable → Enable debug mode lagi

---

## 📝 Code Reference

### PrinterService Debug Implementation

```dart
// lib/services/printer_service.dart

bool debugMode = false;
final List<String> _printLog = [];

Future<List<BluetoothDevice>> scanDevices() async {
  if (debugMode) {
    // Return mock devices
    return [
      BluetoothDevice('Mock Printer 1', 'AA:BB:CC:DD:EE:01'),
      BluetoothDevice('Mock Printer 2', 'AA:BB:CC:DD:EE:02'),
      BluetoothDevice('Mock Printer 3', 'AA:BB:CC:DD:EE:03'),
    ];
  }

  // Real Bluetooth scan
  return await _bluetooth.getBondedDevices();
}

Future<void> printToCategory(String categoryId, String content) async {
  if (debugMode) {
    // Simulate print
    await Future.delayed(const Duration(milliseconds: 500));

    final logEntry =
        '[${DateTime.now().toString().substring(11, 19)}] PRINT to $categoryId:\n$content';
    _printLog.insert(0, logEntry);
    if (_printLog.length > 20) _printLog.removeLast();

    return;
  }

  // Real Bluetooth print
  // ...
}
```

---

**Happy Debugging! 🎉**

_OrbitPrint - Thermal Printer Gateway Solution_
