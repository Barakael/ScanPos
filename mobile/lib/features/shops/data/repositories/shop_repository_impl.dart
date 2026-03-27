import 'package:dio/dio.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';
import '../models/shop_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/app_exception.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ApiClient _apiClient;

  ShopRepositoryImpl(this._apiClient);

  @override
  Future<List<ShopEntity>> getShops() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        endpoint: '/shops',
        parser: (json) => json as List<dynamic>,
      );
      return response.map((json) => ShopModel.fromJson(json)).toList();
    } on ServerException catch (e) {
      throw Exception('Failed to load shops: ${e.message}');
    } on NetworkException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on UnauthorizedException catch (e) {
      throw Exception('Unauthorized: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load shops: $e');
    }
  }

  @override
  Future<ShopEntity> createShop({
    required String name,
    required String address,
    required String phone,
    required String email,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint: '/shops',
        parser: (json) => json['shop'] as Map<String, dynamic>,
        data: {
          'name': name,
          'address': address,
          'phone': phone,
          'email': email,
        },
      );
      return ShopModel.fromJson(response);
    } on ServerException catch (e) {
      throw Exception('Failed to create shop: ${e.message}');
    } on NetworkException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on UnauthorizedException catch (e) {
      throw Exception('Unauthorized: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create shop: $e');
    }
  }

  @override
  Future<ShopEntity> updateShop({
    required int id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? status,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        endpoint: '/shops/$id',
        parser: (json) => json as Map<String, dynamic>,
        data: {
          if (name != null) 'name': name,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (status != null) 'status': status,
        },
      );
      return ShopModel.fromJson(response);
    } on ServerException catch (e) {
      throw Exception('Failed to update shop: ${e.message}');
    } on NetworkException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on UnauthorizedException catch (e) {
      throw Exception('Unauthorized: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update shop: $e');
    }
  }

  @override
  Future<void> deleteShop(int id) async {
    try {
      await _apiClient.delete(endpoint: '/shops/$id');
    } on ServerException catch (e) {
      throw Exception('Failed to delete shop: ${e.message}');
    } on NetworkException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on UnauthorizedException catch (e) {
      throw Exception('Unauthorized: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete shop: $e');
    }
  }

  @override
  Future<ShopEntity> getShop(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint: '/shops/$id',
        parser: (json) => json['shop'] as Map<String, dynamic>,
      );
      return ShopModel.fromJson(response);
    } on ServerException catch (e) {
      throw Exception('Failed to load shop: ${e.message}');
    } on NetworkException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on UnauthorizedException catch (e) {
      throw Exception('Unauthorized: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load shop: $e');
    }
  }
}
