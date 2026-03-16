import 'business_type.dart';

class BusinessProfile {
  const BusinessProfile({
    this.id = 1,
    required this.shopName,
    this.businessType = BusinessType.restaurant,
    this.ownerName = '',
    this.gstNumber = '',
    this.phone = '',
    this.address = '',
    this.logoPath,
  });

  final int id;
  final String shopName;
  final BusinessType businessType;
  final String ownerName;
  final String gstNumber;
  final String phone;
  final String address;
  final String? logoPath;

  bool get isComplete => shopName.isNotEmpty;

  BusinessProfile copyWith({
    int? id,
    String? shopName,
    BusinessType? businessType,
    String? ownerName,
    String? gstNumber,
    String? phone,
    String? address,
    String? logoPath,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      gstNumber: gstNumber ?? this.gstNumber,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      'business_type': businessType.storageValue,
      'owner_name': ownerName,
      'gst_number': gstNumber,
      'phone': phone,
      'address': address,
      'logo_path': logoPath,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'] as int,
      shopName: map['shop_name'] as String,
      businessType: BusinessTypeX.fromValue(map['business_type'] as String?),
      ownerName: (map['owner_name'] as String?) ?? '',
      gstNumber: (map['gst_number'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      logoPath: map['logo_path'] as String?,
    );
  }
}
