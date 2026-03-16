enum BusinessType {
  teaShop,
  restaurant,
  salon,
  juiceShop,
  bakery,
  streetVendor,
}

extension BusinessTypeX on BusinessType {
  String get storageValue => name;

  String get label {
    switch (this) {
      case BusinessType.teaShop:
        return 'Tea Shop';
      case BusinessType.restaurant:
        return 'Restaurant';
      case BusinessType.salon:
        return 'Salon / Barber Shop';
      case BusinessType.juiceShop:
        return 'Juice Shop';
      case BusinessType.bakery:
        return 'Bakery';
      case BusinessType.streetVendor:
        return 'Street Vendor';
    }
  }

  static BusinessType fromValue(String? value) {
    switch (value) {
      case 'teaShop':
        return BusinessType.teaShop;
      case 'salon':
        return BusinessType.salon;
      case 'juiceShop':
        return BusinessType.juiceShop;
      case 'bakery':
        return BusinessType.bakery;
      case 'streetVendor':
        return BusinessType.streetVendor;
      case 'restaurant':
      default:
        return BusinessType.restaurant;
    }
  }
}
