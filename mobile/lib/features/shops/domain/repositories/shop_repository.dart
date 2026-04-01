import '../entities/shop_entity.dart';

abstract class ShopRepository {
  Future<List<ShopEntity>> getShops();
  Future<ShopEntity> createShop({
    required String name,
    required String address,
    required String phone,
    required String email,
    String currency = 'TZS',
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  });
  Future<ShopEntity> updateShop({
    required int id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? status,
  });
  Future<void> deleteShop(int id);
  Future<ShopEntity> getShop(int id);
}
