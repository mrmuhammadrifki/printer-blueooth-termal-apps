import 'dart:convert';

class BusinessSettings {
  String businessName;
  String address;
  String phoneNumber;
  bool showBusinessName;
  bool showAddress;
  bool showPhoneNumber;
  bool showDateTime;
  bool showServerId;
  String serverId;

  BusinessSettings({
    this.businessName = 'Jogja Billiard Bogor',
    this.address = 'Jl. Example No. 123, Bogor',
    this.phoneNumber = '0251-1234567',
    this.showBusinessName = true,
    this.showAddress = true,
    this.showPhoneNumber = true,
    this.showDateTime = true,
    this.showServerId = true,
    this.serverId = 'Server Rudi',
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'address': address,
      'phoneNumber': phoneNumber,
      'showBusinessName': showBusinessName,
      'showAddress': showAddress,
      'showPhoneNumber': showPhoneNumber,
      'showDateTime': showDateTime,
      'showServerId': showServerId,
      'serverId': serverId,
    };
  }

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessName: json['businessName'] ?? 'Jogja Billiard Bogor',
      address: json['address'] ?? 'Jl. Example No. 123, Bogor',
      phoneNumber: json['phoneNumber'] ?? '0251-1234567',
      showBusinessName: json['showBusinessName'] ?? true,
      showAddress: json['showAddress'] ?? true,
      showPhoneNumber: json['showPhoneNumber'] ?? true,
      showDateTime: json['showDateTime'] ?? true,
      showServerId: json['showServerId'] ?? true,
      serverId: json['serverId'] ?? 'Server Rudi',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory BusinessSettings.fromJsonString(String jsonString) {
    return BusinessSettings.fromJson(jsonDecode(jsonString));
  }
}
