# OrbitPrint - Integration Guide for Frontend

## 🎯 Overview

OrbitPrint adalah Bluetooth thermal printer gateway yang memungkinkan web application mencetak ke thermal printer via HTTP API.

## 📡 API Endpoints

### Base URL

```
http://127.0.0.1:18181
```

### 1. Health Check

**GET /**

```bash
curl http://127.0.0.1:18181/
```

Response:

```json
{
  "status": "ok",
  "message": "PrintGateway server is running",
  "endpoints": ["/print", "/print-category", "/test_multi_printer.html", "/test_page.html"],
  "categories": [
    {
      "id": "kasir",
      "name": "Kasir",
      "assigned": true,
      "mac": "AA:BB:CC:DD:EE:FF"
    },
    {
      "id": "dapur",
      "name": "Dapur",
      "assigned": true,
      "mac": "11:22:33:44:55:66"
    }
  ],
  "category_count": 2
}
```

### 2. Print to Category (RECOMMENDED)

**POST /print-category**

Request Body:

```json
{
  "categoryId": "kasir",
  "serverName": "Rifki",
  "text": "---------------------------------------\nCustomer: tes\n---------------------------------------\nMeja: -\nID Transaksi: 69350af2a64457cc4cb0ce23\n\nMakanan & Minuman:\n\nKopi Aren (x1)             Rp 19.000\n\nSubtotal:                 Rp 19.000\nTOTAL:                    Rp 19.000\nMetode Bayar:             LATER"
}
```

**Parameters:**
- `categoryId` (required): ID kategori printer (kasir, dapur, dll)
- `serverName` (optional): Nama server/kasir yang akan ditampilkan di struk
- `text` (required): Isi konten struk (tanpa business header)

**Note:** Business header (nama toko, alamat, phone, tanggal) otomatis ditambahkan oleh OrbitPrint dari Settings.

Response Success:

```json
{
  "status": "ok",
  "message": "Printed to kasir"
}
```

Response Error:

```json
{
  "status": "error",
  "message": "Category not found: kasir"
}
```

### 3. Print (Backward Compatible)

**POST /print**

Request Body:

```json
{
  "categoryId": "kasir",
  "text": "Your receipt content..."
}
```

Jika `categoryId` tidak dikirim, default akan print ke category `kasir`.

## 🎨 Format Struk yang Direkomendasikan

```javascript
function formatReceipt(data) {
  const lines = [];

  // Header Business (dari settings OrbitPrint)
  // Business name, address, phone akan otomatis ditambahkan jika enabled

  // Transaction Info
  lines.push(`Tanggal: ${formatDate(new Date())}`);
  if (data.serverName) {
    lines.push(`Server: ${data.serverName}`);
  }
  if (data.customerName) {
    lines.push(`Customer: ${data.customerName}`);
  }
  lines.push('---------------------------------------');

  // Table & Transaction ID
  lines.push(`Meja: ${data.tableName || '-'}`);
  lines.push(`ID Transaksi: ${data.transactionId}`);
  lines.push('');

  // Items
  lines.push('Makanan & Minuman:');
  lines.push('');
  data.items.forEach((item) => {
    const itemLine = `${item.name} (x${item.qty})`.padEnd(30, ' ');
    const price = `Rp ${formatNumber(item.total)}`;
    lines.push(`${itemLine}${price.padStart(10)}`);
  });
  lines.push('');

  // Totals
  lines.push(`Subtotal:${formatNumber(data.subtotal).padStart(32)}`);
  lines.push('');
  lines.push(`Subtotal:${formatNumber(data.subtotal).padStart(32)}`);
  lines.push(`TOTAL:${formatNumber(data.total).padStart(35)}`);
  lines.push(`Metode Bayar:${data.paymentMethod.padStart(28)}`);

  return lines.join('\n');
}

function formatDate(date) {
  return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}, ${date
    .getHours()
    .toString()
    .padStart(2, '0')}.${date.getMinutes().toString().padStart(2, '0')}.${date
    .getSeconds()
    .toString()
    .padStart(2, '0')}`;
}

function formatNumber(num) {
  return ` Rp ${num.toLocaleString('id-ID')}`;
}
```

## 💻 Integration Example

### JavaScript/TypeScript (React/Vue/Next.js)

```typescript
// services/printerService.ts

interface PrintRequest {
  categoryId: 'kasir' | 'dapur' | string;
  text: string;
}

interface PrintResponse {
  status: 'ok' | 'error';
  message: string;
}

class PrinterService {
  private baseUrl = 'http://127.0.0.1:18181';

  async checkConnection(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/`);
      const data = await response.json();
      return data.status === 'ok';
    } catch (error) {
      console.error('Printer gateway not connected:', error);
      return false;
    }
  }

  async printToCategory(categoryId: string, content: string): Promise<PrintResponse> {
    try {
      const response = await fetch(`${this.baseUrl}/print-category`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          categoryId,
          text: content,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Print failed');
      }

      return data;
    } catch (error) {
      console.error('Print error:', error);
      throw error;
    }
  }

  async printReceipt(receipt: TransactionData, categoryId: string = 'kasir'): Promise<void> {
    const content = this.formatReceipt(receipt);
    await this.printToCategory(categoryId, content);
  }

  private formatReceipt(data: TransactionData): string {
    const lines: string[] = [];

    // Format transaction info
    lines.push(`Tanggal: ${this.formatDate(new Date())}`);
    if (data.serverName) {
      lines.push(`Server: ${data.serverName}`);
    }
    if (data.customerName) {
      lines.push(`Customer: ${data.customerName}`);
    }
    lines.push('---------------------------------------');

    lines.push(`Meja: ${data.tableName || '-'}`);
    lines.push(`ID Transaksi: ${data.transactionId}`);
    lines.push('');
    lines.push('Makanan & Minuman:');
    lines.push('');

    // Format items
    data.items.forEach((item) => {
      const itemLine = `${item.name} (x${item.qty})`.padEnd(30, ' ');
      const price = `Rp ${this.formatNumber(item.total)}`;
      lines.push(`${itemLine}${price.padStart(10)}`);
    });

    lines.push('');
    lines.push(`Subtotal:${'Rp ' + this.formatNumber(data.subtotal)}`.padStart(42));
    lines.push('');
    lines.push(`Subtotal:${'Rp ' + this.formatNumber(data.subtotal)}`.padStart(42));
    lines.push(`TOTAL:${'Rp ' + this.formatNumber(data.total)}`.padStart(45));
    lines.push(`Metode Bayar:${data.paymentMethod.padStart(28)}`);

    return lines.join('\n');
  }

  private formatDate(date: Date): string {
    return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}, ${date
      .getHours()
      .toString()
      .padStart(2, '0')}.${date.getMinutes().toString().padStart(2, '0')}.${date
      .getSeconds()
      .toString()
      .padStart(2, '0')}`;
  }

  private formatNumber(num: number): string {
    return num.toLocaleString('id-ID');
  }
}

export const printerService = new PrinterService();

// Types
interface TransactionData {
  transactionId: string;
  tableName?: string;
  serverName?: string;
  customerName?: string;
  items: Array<{
    name: string;
    qty: number;
    total: number;
  }>;
  subtotal: number;
  total: number;
  paymentMethod: string;
}
```

### Usage Example in Component

```typescript
// components/CheckoutButton.tsx
import { printerService } from '@/services/printerService';

function CheckoutButton({ transaction }: { transaction: TransactionData }) {
  const [printing, setPrinting] = useState(false);

  const handlePrint = async () => {
    setPrinting(true);
    try {
      // Check connection first
      const isConnected = await printerService.checkConnection();
      if (!isConnected) {
        alert('Printer gateway is not connected. Please start OrbitPrint app.');
        return;
      }

      // Print to kasir (receipt)
      await printerService.printReceipt(transaction, 'kasir');

      // Optional: Print to dapur (kitchen order)
      // await printerService.printReceipt(transaction, 'dapur');

      alert('Print successful!');
    } catch (error) {
      console.error('Print failed:', error);
      alert('Print failed. Please check OrbitPrint app.');
    } finally {
      setPrinting(false);
    }
  };

  return (
    <button onClick={handlePrint} disabled={printing} className="btn btn-primary">
      {printing ? 'Printing...' : 'Print Receipt'}
    </button>
  );
}
```

## 🔧 Setup Instructions for Frontend Team

1. **Install OrbitPrint App** (on Windows PC yang connect ke printer Bluetooth)

   - Download APK dari release
   - Install di Android device atau Windows PC

2. **Start OrbitPrint Server**

   - Buka aplikasi OrbitPrint
   - Tab ke "Dashboard"
   - Klik tombol "Start" untuk menjalankan server
   - Server akan berjalan di `http://127.0.0.1:18181`

3. **Assign Printers**

   - Tab ke "Printers"
   - Klik "Scan Devices" untuk menemukan printer Bluetooth
   - Tap kategori (kasir/dapur) dan pilih printer yang ingin di-assign
   - Printer siap digunakan

4. **Configure Business Info** (optional)

   - Tab ke "Settings"
   - Isi business name, address, phone
   - Pilih info mana yang ingin ditampilkan di struk
   - Klik "Save"

5. **Test Connection dari Frontend**
   ```bash
   curl http://127.0.0.1:18181/
   ```

## 📱 Supported Printers

- Thermal Bluetooth Printers (58mm / 80mm)
- ESC/POS compatible printers
- Tested brands: Epson, Xprinter, Zjiang, dll

## 🐛 Troubleshooting

### Print tidak keluar

- Cek apakah OrbitPrint server running (status hijau di dashboard)
- Pastikan printer sudah di-assign ke kategori yang benar
- Cek koneksi Bluetooth printer
- Lihat logs di dashboard OrbitPrint

### Connection refused

- Pastikan OrbitPrint app berjalan
- Cek firewall Windows tidak block port 18181
- Gunakan `127.0.0.1` bukan `localhost`

### Printer tidak terdeteksi

- Pair printer dengan device Windows/Android terlebih dahulu
- Pastikan Bluetooth enabled
- Restart Bluetooth service jika perlu

## 📞 Support

Untuk pertanyaan atau issues, hubungi tim backend atau buat issue di repository.

---

**OrbitPrint** - Thermal Printer Gateway Solution 🖨️
