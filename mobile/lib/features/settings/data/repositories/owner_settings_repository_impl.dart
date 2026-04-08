import 'package:dio/dio.dart';
import '../../../shops/domain/entities/shop_entity.dart';
import '../../domain/repositories/owner_settings_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/app_exception.dart';

class OwnerSettingsRepositoryImpl implements OwnerSettingsRepository {
  final ApiClient _apiClient;

  OwnerSettingsRepositoryImpl(this._apiClient);

  @override
  Future<ShopEntity?> getCurrentShop() async {
    try {
      // For now, get the first shop (owner typically has one shop)
      final response = await _apiClient.get<List<dynamic>>(
        endpoint: '/shops',
        parser: (json) => json as List<dynamic>,
      );
      
      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
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

  @override
  Future<List<BranchEntity>> getBranches() async {
    try {
      // For now, return mock data - replace with actual API call when branch endpoint exists
      // TODO: Implement actual branches API call
      return [
        BranchEntity(
          id: 1,
          name: 'Main Branch',
          address: '123 Main St, Dar es Salaam',
          phone: '+255 712 345 678',
        ),
        BranchEntity(
          id: 2,
          name: 'Branch 2',
          address: '456 Secondary St, Dar es Salaam',
          phone: '+255 712 345 679',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load branches: $e');
    }
  }

  @override
  Future<BranchEntity> createBranch({
    required String name,
    required String address,
    String? phone,
  }) async {
    try {
      // TODO: Implement actual branch creation API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      return BranchEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        address: address,
        phone: phone,
      );
    } catch (e) {
      throw Exception('Failed to create branch: $e');
    }
  }

  @override
  Future<void> deleteBranch(int id) async {
    try {
      // TODO: Implement actual branch deletion API call
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    } catch (e) {
      throw Exception('Failed to delete branch: $e');
    }
  }

  @override
  Future<SubscriptionEntity> getSubscription() async {
    try {
      // For now, return mock data - replace with actual API call when subscription endpoint exists
      // TODO: Implement actual subscription API call
      return SubscriptionEntity(
        planName: 'Premium Plan',
        price: 29.99,
        status: 'active',
        nextDueDate: '2026-05-08',
        paymentHistory: [
          PaymentHistoryItem(
            date: '2026-04-08',
            amount: 29.99,
            status: 'success',
          ),
          PaymentHistoryItem(
            date: '2026-03-08',
            amount: 29.99,
            status: 'success',
          ),
          PaymentHistoryItem(
            date: '2026-02-08',
            amount: 29.99,
            status: 'success',
          ),
        ],
      );
    } catch (e) {
      throw Exception('Failed to load subscription: $e');
    }
  }
}
