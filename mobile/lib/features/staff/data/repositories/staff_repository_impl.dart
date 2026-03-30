import 'package:dio/dio.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../models/staff_model.dart';
import '../../../../core/network/api_client.dart';

class StaffRepositoryImpl implements StaffRepository {
  final ApiClient _apiClient;

  StaffRepositoryImpl(this._apiClient);

  @override
  Future<List<StaffEntity>> getStaff() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        endpoint: '/staff',
        parser: (json) => (json['data'] as List<dynamic>).toList(),
      );
      return response.map((json) => StaffModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load staff: $e');
    }
  }

  @override
  Future<StaffEntity> createStaff({
    required String name,
    required String email,
    required String password,
    required int branchId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint: '/staff',
        parser: (json) => json['data'] as Map<String, dynamic>,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'branch_id': branchId,
        },
      );
      return StaffModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  @override
  Future<StaffEntity> updateStaff({
    required int id,
    required String name,
    required String email,
    String? password,
    int? branchId,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        endpoint: '/staff/$id',
        parser: (json) => json['data'] as Map<String, dynamic>,
        data: {
          'name': name,
          'email': email,
          if (password != null) 'password': password,
          if (branchId != null) 'branch_id': branchId,
        },
      );
      return StaffModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  @override
  Future<void> deleteStaff(int id) async {
    try {
      await _apiClient.delete(endpoint: '/staff/$id');
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }
}
