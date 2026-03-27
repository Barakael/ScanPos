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
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String roleId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint: '/staff',
        parser: (json) => json['data'] as Map<String, dynamic>,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'role_id': roleId,
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
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? roleId,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        endpoint: '/staff/$id',
        parser: (json) => json['data'] as Map<String, dynamic>,
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (roleId != null) 'role_id': roleId,
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
