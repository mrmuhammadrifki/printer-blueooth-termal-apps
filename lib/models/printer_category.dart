import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrinterCategory {
  String id;
  String name;
  String? macAddress;
  String? deviceName;
  esc_pos.PaperSize paperSize;

  PrinterCategory({
    required this.id,
    required this.name,
    this.macAddress,
    this.deviceName,
    this.paperSize = esc_pos.PaperSize.mm58,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'deviceName': deviceName,
      'paperSize': paperSize == esc_pos.PaperSize.mm58 ? 58 : 80,
    };
  }

  factory PrinterCategory.fromJson(Map<String, dynamic> json) {
    return PrinterCategory(
      id: json['id'],
      name: json['name'],
      macAddress: json['macAddress'],
      deviceName: json['deviceName'],
      paperSize:
          json['paperSize'] == 80
              ? esc_pos.PaperSize.mm80
              : esc_pos.PaperSize.mm58,
    );
  }

  BluetoothDevice? toBluetoothDevice() {
    if (macAddress == null) return null;
    return BluetoothDevice(deviceName ?? name, macAddress!);
  }

  bool get isAssigned => macAddress != null;
}

class PrinterCategoryList {
  List<PrinterCategory> categories;

  PrinterCategoryList({List<PrinterCategory>? categories})
    : categories =
          categories ??
          [
            PrinterCategory(
              id: 'kasir',
              name: 'Kasir',
              paperSize: esc_pos.PaperSize.mm58,
            ),
            PrinterCategory(
              id: 'dapur',
              name: 'Dapur',
              paperSize: esc_pos.PaperSize.mm58,
            ),
          ];

  List<Map<String, dynamic>> toJson() {
    return categories.map((c) => c.toJson()).toList();
  }

  factory PrinterCategoryList.fromJson(List<dynamic> json) {
    return PrinterCategoryList(
      categories: json.map((c) => PrinterCategory.fromJson(c)).toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PrinterCategoryList.fromJsonString(String jsonString) {
    return PrinterCategoryList.fromJson(jsonDecode(jsonString));
  }

  PrinterCategory? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void addCategory(PrinterCategory category) {
    if (!categories.any((c) => c.id == category.id)) {
      categories.add(category);
    }
  }

  void removeCategory(String id) {
    categories.removeWhere((c) => c.id == id);
  }
}
