# 🌐 OrbitPrint - Web Integration Documentation

> **Panduan Lengkap Integrasi OrbitPrint dengan Aplikasi Web**

## 📊 Status Aplikasi

✅ **Ready for Production**

- ✅ Multi-printer support (Kasir, Dapur, Custom Categories)
- ✅ ESC/POS thermal printer compatible (58mm & 80mm)
- ✅ Auto line wrapping per paper size (32/48 chars)
- ✅ Debug mode untuk testing tanpa printer fisik
- ✅ Real-time settings update
- ✅ Scan timeout protection (15 detik)
- ✅ Multi-printer connection handling
- ✅ Business settings support (nama toko, alamat, phone)

---

## 🚀 Quick Start

### 1. Pastikan OrbitPrint Running

```bash
# Check if server is running
curl http://127.0.0.1:18181/

# Expected response:
{
  "status": "ok",
  "message": "PrintGateway server is running"
}
```

### 2. Test Print (JavaScript)

```javascript
async function testPrint() {
  const response = await fetch('http://127.0.0.1:18181/print-category', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      categoryId: 'kasir',
      serverName: 'Kasir 1',
      text: '---------------------------------------\nTest Print\n---------------------------------------\nHello World!\nPrint successful!'
    })
  });
  
  const result = await response.json();
  console.log(result);
}

testPrint();
```

---

## 📡 API Reference

### Base URL

```
http://127.0.0.1:18181
```

> **⚠️ CORS:** Server sudah include CORS headers untuk semua origins

---

### 1️⃣ Health Check

**GET /**

Cek status server dan list kategori printer yang tersedia.

**Response:**

```json
{
  "status": "ok",
  "message": "PrintGateway server is running",
  "endpoints": ["/print", "/print-category", "/settings", "/test"],
  "categories": [
    {
      "id": "kasir",
      "name": "Kasir",
      "assigned": true,
      "mac": "AA:BB:CC:DD:EE:FF",
      "deviceName": "Printer Kasir"
    },
    {
      "id": "dapur",
      "name": "Dapur",
      "assigned": false,
      "mac": null,
      "deviceName": null
    }
  ],
  "category_count": 2,
  "debug_mode": false
}
```

---

### 2️⃣ Print to Category (RECOMMENDED) ⭐

**POST /print-category**

Print struk ke kategori printer tertentu dengan business header otomatis.

**Request Body:**

```typescript
interface PrintCategoryRequest {
  categoryId: string;      // "kasir" | "dapur" | custom ID
  serverName?: string;     // Nama kasir/server (optional)
  text: string;            // Konten struk (tanpa header bisnis)
}
```

**Example:**

```javascript
const printReceipt = async (orderId, items, total) => {
  // Format struk content
  const receiptText = `
---------------------------------------
ORDER #${orderId}
---------------------------------------
Meja: 5
Tanggal: ${new Date().toLocaleDateString('id-ID')}

ITEMS:
${items.map(item => 
  `${item.name.padEnd(25)} ${item.qty}x Rp ${item.price.toLocaleString()}`
).join('\n')}

---------------------------------------
SUBTOTAL:        Rp ${total.toLocaleString()}
TAX (10%):       Rp ${(total * 0.1).toLocaleString()}
TOTAL:           Rp ${(total * 1.1).toLocaleString()}
---------------------------------------
Terima kasih!
`.trim();

  try {
    const response = await fetch('http://127.0.0.1:18181/print-category', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        categoryId: 'kasir',
        serverName: 'Rifki',
        text: receiptText
      })
    });

    const result = await response.json();
    
    if (result.status === 'ok') {
      console.log('✅ Print berhasil:', result.message);
      return true;
    } else {
      console.error('❌ Print gagal:', result.message);
      return false;
    }
  } catch (error) {
    console.error('❌ Network error:', error);
    return false;
  }
};

// Usage
printReceipt('ORD-001', [
  { name: 'Kopi Susu', qty: 2, price: 15000 },
  { name: 'Nasi Goreng', qty: 1, price: 25000 }
], 55000);
```

**Response Success:**

```json
{
  "status": "ok",
  "message": "Printed to kasir"
}
```

**Response Error:**

```json
{
  "status": "error",
  "message": "Category 'kasir' not assigned to any printer"
}
```

**Possible Errors:**

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `Category not found: kasir` | Category ID tidak ada | Cek available categories di GET / |
| `Category 'kasir' not assigned` | Printer belum di-assign | Assign printer di app |
| `Bluetooth not enabled` | Bluetooth off | Aktifkan Bluetooth di device |
| `Printer not connected` | Printer tidak konek | Reconnect printer di app |

---

### 3️⃣ Print (Backward Compatible)

**POST /print**

Legacy endpoint, default print ke kategori "kasir".

**Request:**

```json
{
  "categoryId": "kasir",  // optional, default: "kasir"
  "text": "Receipt content..."
}
```

> **💡 Rekomendasi:** Gunakan `/print-category` untuk fitur lengkap dan clarity.

---

### 4️⃣ Get Settings

**GET /settings**

Get business settings (nama toko, alamat, dll).

**Response:**

```json
{
  "businessName": "Kopi Kenangan",
  "address": "Jl. Sudirman No. 123",
  "phone": "081234567890",
  "paperSize": "80mm",
  "debugMode": false
}
```

---

### 5️⃣ Test Print

**GET /test**

Test print dengan mock data (untuk testing koneksi).

**Response:**

```json
{
  "status": "ok",
  "message": "Test print sent to all assigned categories",
  "results": [
    {
      "category": "kasir",
      "status": "ok",
      "message": "Test print successful"
    }
  ]
}
```

---

## 💻 Integration Examples

### Vanilla JavaScript

```javascript
class OrbitPrintClient {
  constructor(baseUrl = 'http://127.0.0.1:18181') {
    this.baseUrl = baseUrl;
  }

  async checkHealth() {
    const response = await fetch(`${this.baseUrl}/`);
    return await response.json();
  }

  async printToCategory(categoryId, text, serverName = null) {
    const response = await fetch(`${this.baseUrl}/print-category`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        categoryId,
        text,
        ...(serverName && { serverName })
      })
    });
    
    const result = await response.json();
    if (result.status !== 'ok') {
      throw new Error(result.message);
    }
    return result;
  }

  async getCategories() {
    const health = await this.checkHealth();
    return health.categories || [];
  }

  async getSettings() {
    const response = await fetch(`${this.baseUrl}/settings`);
    return await response.json();
  }
}

// Usage
const printer = new OrbitPrintClient();

// Print struk kasir
await printer.printToCategory('kasir', `
---------------------------------------
STRUK PEMBAYARAN
---------------------------------------
Item: Kopi Susu
Harga: Rp 15.000
---------------------------------------
TOTAL: Rp 15.000
---------------------------------------
`, 'Kasir 1');
```

---

### React / Next.js

```typescript
// hooks/useOrbitPrint.ts
import { useState, useEffect } from 'react';

interface PrinterCategory {
  id: string;
  name: string;
  assigned: boolean;
  mac: string | null;
  deviceName: string | null;
}

export function useOrbitPrint(baseUrl = 'http://127.0.0.1:18181') {
  const [categories, setCategories] = useState<PrinterCategory[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkConnection();
  }, []);

  const checkConnection = async () => {
    try {
      const response = await fetch(`${baseUrl}/`);
      const data = await response.json();
      setIsConnected(data.status === 'ok');
      setCategories(data.categories || []);
    } catch (error) {
      setIsConnected(false);
      console.error('OrbitPrint not connected:', error);
    }
  };

  const printReceipt = async (
    categoryId: string,
    text: string,
    serverName?: string
  ) => {
    setLoading(true);
    try {
      const response = await fetch(`${baseUrl}/print-category`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ categoryId, text, serverName })
      });

      const result = await response.json();
      
      if (result.status !== 'ok') {
        throw new Error(result.message);
      }

      return { success: true, message: result.message };
    } catch (error) {
      return { 
        success: false, 
        message: error instanceof Error ? error.message : 'Print failed'
      };
    } finally {
      setLoading(false);
    }
  };

  return {
    categories,
    isConnected,
    loading,
    printReceipt,
    checkConnection
  };
}

// Component Usage
import { useOrbitPrint } from '@/hooks/useOrbitPrint';

function CheckoutPage() {
  const { printReceipt, isConnected, categories } = useOrbitPrint();

  const handlePrint = async () => {
    const receiptText = generateReceiptText(orderData);
    const result = await printReceipt('kasir', receiptText, 'Kasir 1');
    
    if (result.success) {
      toast.success('Struk berhasil dicetak!');
    } else {
      toast.error(`Print gagal: ${result.message}`);
    }
  };

  if (!isConnected) {
    return (
      <Alert variant="destructive">
        <AlertTitle>Printer Tidak Terhubung</AlertTitle>
        <AlertDescription>
          Pastikan OrbitPrint app berjalan di Android device.
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <div>
      <Button onClick={handlePrint}>
        Print Struk
      </Button>
    </div>
  );
}
```

---

### Vue 3 / Nuxt

```typescript
// composables/useOrbitPrint.ts
import { ref, onMounted } from 'vue';

export function useOrbitPrint(baseUrl = 'http://127.0.0.1:18181') {
  const categories = ref([]);
  const isConnected = ref(false);
  const loading = ref(false);

  const checkConnection = async () => {
    try {
      const response = await fetch(`${baseUrl}/`);
      const data = await response.json();
      isConnected.value = data.status === 'ok';
      categories.value = data.categories || [];
    } catch (error) {
      isConnected.value = false;
    }
  };

  const printReceipt = async (categoryId, text, serverName = null) => {
    loading.value = true;
    try {
      const response = await fetch(`${baseUrl}/print-category`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ categoryId, text, serverName })
      });

      const result = await response.json();
      
      if (result.status !== 'ok') {
        throw new Error(result.message);
      }

      return { success: true, message: result.message };
    } catch (error) {
      return { 
        success: false, 
        message: error.message || 'Print failed'
      };
    } finally {
      loading.value = false;
    }
  };

  onMounted(() => {
    checkConnection();
  });

  return {
    categories,
    isConnected,
    loading,
    printReceipt,
    checkConnection
  };
}

// Component
<script setup>
import { useOrbitPrint } from '~/composables/useOrbitPrint';

const { printReceipt, isConnected } = useOrbitPrint();

const handleCheckout = async () => {
  const receiptText = `
---------------------------------------
ORDER #12345
---------------------------------------
Kopi Susu             2x   Rp 30.000
Nasi Goreng           1x   Rp 25.000
---------------------------------------
TOTAL:                     Rp 55.000
---------------------------------------
  `;

  const result = await printReceipt('kasir', receiptText, 'POS 1');
  
  if (result.success) {
    // Show success
  }
};
</script>
```

---

## 🎨 Receipt Formatting Guide

### Character Width per Paper Size

- **58mm:** 32 characters per line
- **80mm:** 48 characters per line

OrbitPrint **automatically wraps text** sesuai paper size yang dipilih di Settings.

### Best Practices

```javascript
// ✅ GOOD: Simple, clean formatting
const receipt = `
---------------------------------------
STRUK PEMBAYARAN
---------------------------------------
Item: Kopi Susu
Qty: 2
Harga: Rp 15.000
---------------------------------------
TOTAL: Rp 30.000
---------------------------------------
`;

// ✅ GOOD: Aligned columns (for 48 chars / 80mm)
const formatItem = (name, qty, price) => {
  const nameCol = name.substring(0, 25).padEnd(25);
  const qtyCol = `${qty}x`.padStart(4);
  const priceCol = `Rp ${price.toLocaleString()}`.padStart(15);
  return `${nameCol}${qtyCol} ${priceCol}`;
};

// Example output:
// Kopi Susu                   2x      Rp 15.000
// Nasi Goreng Spesial         1x      Rp 25.000

// ❌ BAD: Too wide, will wrap awkwardly
const badReceipt = `
=================================================================
                    STRUK YANG TERLALU PANJANG
=================================================================
`;

// ✅ GOOD: Center-aligned header
const centerText = (text, width = 48) => {
  const spaces = Math.max(0, Math.floor((width - text.length) / 2));
  return ' '.repeat(spaces) + text;
};

const receipt = `
${centerText('KOPI KENANGAN')}
${centerText('Jl. Sudirman No. 123')}
${centerText('Telp: 081234567890')}
---------------------------------------
`;
```

### Template Generator

```javascript
class ReceiptFormatter {
  constructor(paperSize = '80mm') {
    this.width = paperSize === '58mm' ? 32 : 48;
  }

  center(text) {
    const spaces = Math.max(0, Math.floor((this.width - text.length) / 2));
    return ' '.repeat(spaces) + text;
  }

  divider(char = '-') {
    return char.repeat(this.width);
  }

  row(left, right) {
    const available = this.width - right.length - 1;
    return left.substring(0, available).padEnd(available) + ' ' + right;
  }

  itemRow(name, qty, price) {
    const priceStr = `Rp ${price.toLocaleString()}`;
    const qtyStr = `${qty}x`;
    const nameWidth = this.width - qtyStr.length - priceStr.length - 2;
    
    return `${name.substring(0, nameWidth).padEnd(nameWidth)} ${qtyStr} ${priceStr}`;
  }

  build(data) {
    return `
${this.center(data.businessName)}
${this.center(data.address)}
${this.center(data.phone)}
${this.divider()}
Order: ${data.orderId}
Meja: ${data.table}
Tanggal: ${data.date}
${this.divider()}

ITEMS:
${data.items.map(item => 
  this.itemRow(item.name, item.qty, item.price)
).join('\n')}

${this.divider()}
${this.row('SUBTOTAL:', `Rp ${data.subtotal.toLocaleString()}`)}
${this.row('TAX:', `Rp ${data.tax.toLocaleString()}`)}
${this.row('TOTAL:', `Rp ${data.total.toLocaleString()}`)}
${this.divider()}
${this.center('Terima Kasih!')}
`.trim();
  }
}

// Usage
const formatter = new ReceiptFormatter('80mm');
const receipt = formatter.build({
  businessName: 'KOPI KENANGAN',
  address: 'Jl. Sudirman No. 123',
  phone: '081234567890',
  orderId: 'ORD-001',
  table: '5',
  date: new Date().toLocaleDateString('id-ID'),
  items: [
    { name: 'Kopi Susu', qty: 2, price: 15000 },
    { name: 'Nasi Goreng', qty: 1, price: 25000 }
  ],
  subtotal: 55000,
  tax: 5500,
  total: 60500
});
```

---

## 🔧 Error Handling

### Robust Error Handler

```javascript
class PrinterError extends Error {
  constructor(message, code) {
    super(message);
    this.code = code;
    this.name = 'PrinterError';
  }
}

async function safePrint(categoryId, text, serverName) {
  try {
    // 1. Check connection first
    const healthCheck = await fetch('http://127.0.0.1:18181/', {
      signal: AbortSignal.timeout(3000) // 3 second timeout
    });
    
    if (!healthCheck.ok) {
      throw new PrinterError(
        'OrbitPrint server tidak merespon',
        'SERVER_UNREACHABLE'
      );
    }

    const health = await healthCheck.json();
    
    // 2. Verify category exists
    const category = health.categories?.find(c => c.id === categoryId);
    if (!category) {
      throw new PrinterError(
        `Kategori '${categoryId}' tidak ditemukan`,
        'CATEGORY_NOT_FOUND'
      );
    }

    // 3. Verify printer assigned
    if (!category.assigned) {
      throw new PrinterError(
        `Printer '${category.name}' belum di-assign`,
        'PRINTER_NOT_ASSIGNED'
      );
    }

    // 4. Attempt print
    const response = await fetch('http://127.0.0.1:18181/print-category', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ categoryId, text, serverName }),
      signal: AbortSignal.timeout(10000) // 10 second timeout
    });

    const result = await response.json();
    
    if (result.status !== 'ok') {
      throw new PrinterError(result.message, 'PRINT_FAILED');
    }

    return { success: true, message: result.message };

  } catch (error) {
    if (error instanceof PrinterError) {
      return { 
        success: false, 
        code: error.code,
        message: error.message 
      };
    }

    if (error.name === 'AbortError') {
      return {
        success: false,
        code: 'TIMEOUT',
        message: 'Request timeout - pastikan OrbitPrint berjalan'
      };
    }

    if (error.name === 'TypeError') {
      return {
        success: false,
        code: 'NETWORK_ERROR',
        message: 'Tidak dapat terhubung ke OrbitPrint'
      };
    }

    return {
      success: false,
      code: 'UNKNOWN_ERROR',
      message: error.message || 'Unknown error'
    };
  }
}

// Usage with UI feedback
const handlePrint = async () => {
  setLoading(true);
  
  const result = await safePrint('kasir', receiptText, 'Kasir 1');
  
  setLoading(false);

  if (result.success) {
    showNotification('success', 'Struk berhasil dicetak!');
  } else {
    // Different error messages based on error code
    switch (result.code) {
      case 'SERVER_UNREACHABLE':
        showNotification('error', 'OrbitPrint tidak berjalan. Jalankan aplikasi di Android.');
        break;
      case 'CATEGORY_NOT_FOUND':
        showNotification('error', 'Kategori printer tidak valid.');
        break;
      case 'PRINTER_NOT_ASSIGNED':
        showNotification('error', 'Printer belum di-assign. Assign printer di aplikasi OrbitPrint.');
        break;
      case 'TIMEOUT':
        showNotification('error', 'Request timeout. Cek koneksi jaringan.');
        break;
      case 'NETWORK_ERROR':
        showNotification('error', 'Gagal terhubung ke printer. Pastikan di jaringan yang sama.');
        break;
      default:
        showNotification('error', `Print gagal: ${result.message}`);
    }
  }
};
```

---

## 🧪 Testing

### Testing Tanpa Printer Fisik

1. **Aktifkan Debug Mode** di OrbitPrint Settings
2. Debug mode akan menampilkan **3 mock printers** saat scan:
   - TEST-PRINTER-001 (AA:BB:CC:DD:EE:FF)
   - TEST-PRINTER-002 (11:22:33:44:55:66)
   - TEST-PRINTER-003 (FF:EE:DD:CC:BB:AA)

3. Mock printers akan **simulate print** tanpa hardware:
   - ✅ Semua endpoint `/print-category` return success
   - ✅ Receipt data di-log di console
   - ✅ Tidak butuh Bluetooth enabled

### Test Suite HTML

Gunakan `test_complete.html` untuk testing manual:

```bash
# Di browser
open http://127.0.0.1:18181/test_complete.html
```

Features:
- ✨ Form builder untuk create receipt
- 📋 Quick fill templates
- 👁️ Live preview
- 📊 Print history & statistics
- 🔍 Server status monitoring

---

## 🎯 Common Use Cases

### 1. Kasir POS - Print Struk

```javascript
async function printKasirReceipt(order) {
  const items = order.items.map(item => 
    `${item.name.padEnd(25)} ${item.qty}x Rp ${item.price.toLocaleString()}`
  ).join('\n');

  const text = `
---------------------------------------
ORDER #${order.id}
---------------------------------------
Meja: ${order.table}
Kasir: ${order.cashier}
Waktu: ${new Date(order.createdAt).toLocaleString('id-ID')}

ITEMS:
${items}

---------------------------------------
SUBTOTAL:        Rp ${order.subtotal.toLocaleString()}
TAX (10%):       Rp ${order.tax.toLocaleString()}
SERVICE (5%):    Rp ${order.service.toLocaleString()}
---------------------------------------
TOTAL:           Rp ${order.total.toLocaleString()}
---------------------------------------
Metode Bayar: ${order.paymentMethod}

Terima kasih atas kunjungan Anda!
  `;

  return await printReceipt('kasir', text, order.cashier);
}
```

### 2. Dapur - Kitchen Order

```javascript
async function printKitchenOrder(order) {
  const items = order.items
    .filter(item => item.category === 'food' || item.category === 'beverage')
    .map(item => `${item.qty}x ${item.name}\n   Note: ${item.notes || '-'}`)
    .join('\n\n');

  const text = `
=======================================
       KITCHEN ORDER
=======================================
Order: #${order.id}
Meja: ${order.table}
Waktu: ${new Date().toLocaleTimeString('id-ID')}
---------------------------------------

${items}

=======================================
       SEGERA DIPROSES!
=======================================
  `;

  return await printReceipt('dapur', text);
}
```

### 3. Custom Category - Bar Order

```javascript
// First, create custom category "bar" in OrbitPrint app

async function printBarOrder(order) {
  const drinks = order.items
    .filter(item => item.category === 'drinks')
    .map(item => `${item.qty}x ${item.name}${item.variant ? ` (${item.variant})` : ''}`)
    .join('\n');

  const text = `
=======================================
         BAR ORDER
=======================================
Order: #${order.id}
Meja: ${order.table}
---------------------------------------

${drinks}

=======================================
  `;

  return await printReceipt('bar', text);
}
```

### 4. Multi-Printer - Split by Category

```javascript
async function printOrderToAllCategories(order) {
  const results = {};

  // Kasir - Full receipt
  results.kasir = await printKasirReceipt(order);

  // Dapur - Food items only
  const foodItems = order.items.filter(i => i.category === 'food');
  if (foodItems.length > 0) {
    results.dapur = await printKitchenOrder({ ...order, items: foodItems });
  }

  // Bar - Drinks only
  const drinkItems = order.items.filter(i => i.category === 'drinks');
  if (drinkItems.length > 0) {
    results.bar = await printBarOrder({ ...order, items: drinkItems });
  }

  return results;
}

// Usage
const results = await printOrderToAllCategories(orderData);

console.log('Print results:', {
  kasir: results.kasir?.success ? '✅' : '❌',
  dapur: results.dapur?.success ? '✅' : '❌',
  bar: results.bar?.success ? '✅' : '❌'
});
```

---

## 🔐 Security Considerations

### Network Security

1. **Local Network Only:** OrbitPrint berjalan di `127.0.0.1` (localhost) atau local IP
2. **No Authentication:** Tidak ada auth - hanya untuk trusted local network
3. **CORS:** Enabled untuk all origins - aman karena local only

### Best Practices

```javascript
// ✅ GOOD: Validate before sending
function validateReceiptData(data) {
  if (!data.categoryId) {
    throw new Error('categoryId required');
  }
  
  if (!data.text || data.text.trim().length === 0) {
    throw new Error('text cannot be empty');
  }
  
  if (data.text.length > 10000) {
    throw new Error('text too long (max 10KB)');
  }
  
  return true;
}

// ✅ GOOD: Sanitize user input
function sanitizeText(text) {
  // Remove control characters except newline/tab
  return text.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');
}

// ❌ BAD: Sending user input directly
const text = userInput; // Could contain weird characters

// ✅ GOOD: Sanitize first
const text = sanitizeText(userInput);
await printReceipt('kasir', text);
```

---

## 🚨 Troubleshooting

### Problem: "Failed to fetch"

**Cause:** OrbitPrint tidak berjalan atau network issue

**Solution:**
1. Pastikan OrbitPrint app berjalan di Android
2. Check server status: `curl http://127.0.0.1:18181/`
3. Pastikan web app dan Android di **jaringan yang sama**
4. Jika emulator, gunakan `10.0.2.2:18181` dari Android, atau `127.0.0.1:18181` dari browser host

---

### Problem: "Category not assigned"

**Cause:** Printer belum di-assign ke kategori

**Solution:**
1. Buka OrbitPrint app
2. Tap kategori yang ingin di-assign
3. Scan Bluetooth devices
4. Pilih printer
5. Printer akan tersimpan untuk kategori tersebut

---

### Problem: "Bluetooth not enabled"

**Cause:** Bluetooth device OFF

**Solution:**
1. Enable Bluetooth di Android settings
2. Pair printer di system Bluetooth settings
3. Scan ulang di OrbitPrint app

---

### Problem: Print berhasil tapi kertas tidak keluar

**Cause:** Printer tidak disconnect dari koneksi sebelumnya

**Solution:**
✅ **Already fixed!** OrbitPrint sekarang otomatis disconnect dari printer sebelumnya sebelum connect ke printer baru.

Jika masih error:
1. Restart OrbitPrint app
2. Unpair dan pair ulang printer di system settings
3. Assign ulang printer di app

---

### Problem: Text terpotong atau format berantakan

**Cause:** Text terlalu panjang atau format tidak sesuai paper size

**Solution:**
- Gunakan `ReceiptFormatter` class (lihat section "Receipt Formatting Guide")
- Paper 58mm = max 32 chars/line
- Paper 80mm = max 48 chars/line
- OrbitPrint otomatis wrap text, tapi hasil terbaik adalah format manual

---

## 📦 Complete Example - E-Commerce Checkout

```typescript
// services/printer.service.ts
export class PrinterService {
  private baseUrl = 'http://127.0.0.1:18181';
  
  async checkConnection(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/`, {
        signal: AbortSignal.timeout(3000)
      });
      return response.ok;
    } catch {
      return false;
    }
  }

  async getCategories() {
    const response = await fetch(`${this.baseUrl}/`);
    const data = await response.json();
    return data.categories || [];
  }

  async printReceipt(
    categoryId: string,
    order: Order,
    cashier: string
  ): Promise<PrintResult> {
    const formatter = new ReceiptFormatter('80mm');
    
    const receiptText = formatter.build({
      businessName: 'TOKO ANDA',
      address: 'Jl. Contoh No. 123',
      phone: '081234567890',
      orderId: order.id,
      table: order.table || '-',
      date: new Date().toLocaleString('id-ID'),
      items: order.items,
      subtotal: order.subtotal,
      tax: order.tax,
      total: order.total
    });

    try {
      const response = await fetch(`${this.baseUrl}/print-category`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          categoryId,
          text: receiptText,
          serverName: cashier
        }),
        signal: AbortSignal.timeout(10000)
      });

      const result = await response.json();
      
      return {
        success: result.status === 'ok',
        message: result.message
      };
    } catch (error) {
      return {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}

// components/CheckoutButton.tsx
import { useState } from 'react';
import { PrinterService } from '@/services/printer.service';

export function CheckoutButton({ order, onComplete }) {
  const [printing, setPrinting] = useState(false);
  const printerService = new PrinterService();

  const handleCheckout = async () => {
    setPrinting(true);

    // 1. Process payment
    const payment = await processPayment(order);
    
    if (!payment.success) {
      toast.error('Pembayaran gagal');
      setPrinting(false);
      return;
    }

    // 2. Print receipt
    const printResult = await printerService.printReceipt(
      'kasir',
      order,
      'Kasir 1'
    );

    if (printResult.success) {
      toast.success('✅ Struk berhasil dicetak!');
      onComplete();
    } else {
      toast.warning('⚠️ Pembayaran berhasil, tapi print gagal: ' + printResult.message);
      // Still complete order even if print fails
      onComplete();
    }

    setPrinting(false);
  };

  return (
    <button
      onClick={handleCheckout}
      disabled={printing}
      className="checkout-btn"
    >
      {printing ? 'Processing...' : 'Checkout & Print'}
    </button>
  );
}
```

---

## 📚 Additional Resources

- 📄 **Test Page:** `http://127.0.0.1:18181/test_complete.html`
- 📖 **API Examples:** Check `test_multi_printer.html` source
- 🐛 **Debug Guide:** See `DEBUG_MODE_GUIDE.md`
- 🔧 **Troubleshooting:** See `TROUBLESHOOTING_BLUEPRINT.md`

---

## 🎉 Summary

OrbitPrint siap digunakan untuk production! Fitur utama:

✅ Multi-printer support dengan category system
✅ ESC/POS compatible dengan auto line wrapping
✅ Debug mode untuk testing tanpa printer
✅ Simple REST API dengan error handling yang baik
✅ Real-time settings & category updates
✅ Business header otomatis (nama toko, alamat, phone)

**Recommended Integration Steps:**

1. ✅ Test koneksi dengan health check endpoint
2. ✅ Implementasi error handling yang robust
3. ✅ Gunakan `/print-category` untuk semua print operations
4. ✅ Format receipt sesuai paper size (32/48 chars)
5. ✅ Enable debug mode untuk development testing
6. ✅ Test dengan mock printers sebelum deploy
7. ✅ Production: assign real printers untuk semua categories

**Need Help?**

- Issues dengan print formatting? → Gunakan `ReceiptFormatter` class
- Printer tidak konek? → Check Bluetooth pairing & assign ulang
- Testing tanpa printer? → Enable debug mode di Settings
- API errors? → Check error codes di section "Error Handling"

**Happy Printing! 🖨️✨**
