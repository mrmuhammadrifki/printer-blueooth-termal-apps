# 🔧 Troubleshooting Guide - Blueprint Thermal Printer

## Masalah: API Berhasil tapi Kertas Tidak Keluar

### ✅ Perbaikan yang Sudah Dilakukan:

1. **Default Paper Size → 58mm**
   - Semua kategori printer sekarang default 58mm
   - Sesuai dengan Blueprint thermal printer Anda

2. **Enhanced ESC/POS Commands**
   - Tambahan initialization sequence (ESC @)
   - Set character code table ke PC437
   - Proper reset command

3. **Improved Print Sequence**
   - Delay lebih lama (1500ms) setelah write
   - Paper cut command dikirim terpisah
   - Feed lebih banyak (5 lines) sebelum cut

4. **Better Error Handling**
   - Lebih banyak logging
   - Explicit connection check
   - Proper exception handling

---

## 📋 Checklist Debugging

### 1. Pastikan Printer Paired dengan Bluetooth
```
Settings → Bluetooth → Devices
Cari "Blueprint" atau nama printer Anda
Pastikan status "Paired"
```

### 2. Cek di OrbitPrint App
```
1. Buka OrbitPrint
2. Tab ke "Printers"
3. Klik "Scan Devices"
4. Pastikan Blueprint printer muncul
5. Assign ke kategori "kasir"
6. Lihat status "Connected" berwarna hijau
```

### 3. Test dari Dashboard
```
1. Tab ke "Dashboard"
2. Pastikan server "Running" (hijau)
3. Lihat logs untuk error messages
```

### 4. Test Print dari API
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"text\":\"TEST PRINT\nHello World\nTotal: Rp 10.000\"}"
```

---

## 🐛 Kemungkinan Masalah & Solusi

### Problem 1: Printer Tidak Terkoneksi
**Gejala:** API response success, tapi tidak ada log error
**Solusi:**
- Restart Bluetooth di PC/Android
- Unpair dan pair ulang printer
- Restart OrbitPrint app
- Cek battery printer (jika wireless)

### Problem 2: Paper Jam atau Kertas Habis
**Gejala:** Printer bunyi tapi kertas tidak keluar
**Solusi:**
- Buka cover printer, cek kertas
- Pastikan kertas terpasang dengan benar
- Cek apakah ada kertas yang nyangkut

### Problem 3: Printer Sleep Mode
**Gejala:** Print pertama gagal, print kedua berhasil
**Solusi:**
- Kirim dummy print untuk wake up printer
- Atau: Disable auto-sleep di printer settings (jika ada)

### Problem 4: Wrong Encoding
**Gejala:** Karakter aneh/kotak-kotak
**Solusi:**
- Sudah diperbaiki dengan PC437 encoding
- Jika masih error, coba hindari karakter special

### Problem 5: Bluetooth Connection Lost
**Gejala:** Print pertama OK, selanjutnya gagal
**Solusi:**
- App akan auto-reconnect
- Atau manual disconnect → reconnect di app

---

## 🔍 Cara Melihat Logs Detail

### Di OrbitPrint App:
1. Tab ke "Dashboard"
2. Scroll ke "Server Logs"
3. Lihat output seperti:
   ```
   📤 PRINT REQUEST
   Category: Kasir
   MAC: XX:XX:XX:XX:XX:XX
   Content length: 123 chars
   ═══════════════════════
   🔗 Connecting to printer...
   ✅ Connected to printer
   📝 Preparing print data...
   ✅ Print data prepared: 456 bytes
   📤 SENDING DATA TO PRINTER...
   ✅ Print data sent successfully
   ✅ Cut command sent
   ✅ PRINT COMPLETED
   ```

### Jika Ada Error:
```
❌ ERROR writing to printer: [error message]
```
Screenshot dan share error message untuk debugging lebih lanjut.

---

## 🧪 Test Sequence

### Test 1: Simple Text
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"text\":\"TEST\"}"
```
**Expected:** Kertas keluar dengan text "TEST"

### Test 2: Multi-line
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"text\":\"Line 1\nLine 2\nLine 3\"}"
```
**Expected:** 3 baris text

### Test 3: Full Receipt
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"serverName\":\"Test Server\",\"text\":\"Customer: John\n---------------------------------------\nItem 1: Rp 10.000\nTotal: Rp 10.000\"}"
```
**Expected:** Full receipt dengan business header

---

## 🔧 Advanced Troubleshooting

### Enable Debug Mode
1. Settings → Developer Options
2. Toggle "Debug Mode" ON
3. Test print → Lihat di logs apakah formatting OK
4. Jika formatting OK di debug, masalah di Bluetooth/printer

### Check Bluetooth Permissions
**Windows:**
- Settings → Privacy → Bluetooth
- Pastikan app punya permission

**Android:**
- Settings → Apps → OrbitPrint → Permissions
- Enable Bluetooth & Location

### Printer Self-Test
Kebanyakan thermal printer punya self-test:
1. Matikan printer
2. Tahan tombol feed
3. Nyalakan printer sambil tetap tahan tombol
4. Lepas tombol → printer akan print self-test

Jika self-test gagal → masalah di printer hardware.

---

## 📞 Jika Masih Gagal

Coba langkah berikut:

1. **Restart Everything**
   - Restart printer (off → on)
   - Restart Bluetooth
   - Restart OrbitPrint app
   - Restart PC/Android

2. **Test dengan App Lain**
   - Download "Bluetooth Thermal Printer" app dari Play Store
   - Test print dari app tersebut
   - Jika gagal → masalah di printer/Bluetooth
   - Jika berhasil → masalah di OrbitPrint

3. **Check Printer Model**
   - Beberapa printer butuh driver khusus
   - Cek manual printer untuk ESC/POS compatibility

4. **Share Logs**
   - Screenshot logs dari Dashboard
   - Share untuk debugging lebih lanjut

---

## ✅ Checklist Setelah Perbaikan

- [ ] Rebuild aplikasi: `flutter run`
- [ ] Scan dan assign printer Blueprint
- [ ] Test print sederhana
- [ ] Cek kertas keluar
- [ ] Test full receipt
- [ ] Verify business header muncul
- [ ] Test multiple prints berturut-turut

---

**Good luck! 🚀**
