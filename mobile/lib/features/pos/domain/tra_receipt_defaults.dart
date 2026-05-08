import '../../shops/domain/entities/shop_entity.dart';

/// Fallback shop profile when API/user has no shop (matches TRA sample receipt).
class TraReceiptDefaults {
  TraReceiptDefaults._();

  static ShopEntity get demoShop => const ShopEntity(
        id: 1,
        name: 'DEMO COMPANY LTD',
        address: '123 Business Street, Dar es Salaam',
        phone: '+255123456789',
        email: 'demo.company@tera-pos.local',
        taxRate: 18,
        currency: 'TZS',
        tin: 'TAX123456789',
        vrn: 'VRN987654321',
        mobile: '+255123456789',
        location: 'DODOMA',
        taxOffice: 'DODOMA',
        serialPrefix: 'DEM',
      );
}
