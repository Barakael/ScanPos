import '../entities/staff_entity.dart';

abstract class StaffRepository {
  Future<List<StaffEntity>> getStaff();
  Future<StaffEntity> createStaff({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String roleId,
  });
  Future<StaffEntity> updateStaff({
    required int id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? roleId,
  });
  Future<void> deleteStaff(int id);
}
