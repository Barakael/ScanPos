import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import 'staff_event.dart';
import 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository _repository;

  StaffBloc(this._repository) : super(const StaffInitial()) {
    on<StaffRequested>(_onStaffRequested);
    on<StaffCreateRequested>(_onStaffCreateRequested);
    on<StaffUpdateRequested>(_onStaffUpdateRequested);
    on<StaffDeleteRequested>(_onStaffDeleteRequested);
  }

  Future<void> _onStaffRequested(
    StaffRequested event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());
    try {
      final staff = await _repository.getStaff();
      emit(StaffLoaded(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onStaffCreateRequested(
    StaffCreateRequested event,
    Emitter<StaffState> emit,
  ) async {
    try {
      final newStaff = await _repository.createStaff(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
        password: event.password,
        roleId: event.roleId,
      );
      emit(StaffCreated(newStaff));
      // Refresh the list
      add(const StaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onStaffUpdateRequested(
    StaffUpdateRequested event,
    Emitter<StaffState> emit,
  ) async {
    try {
      final updatedStaff = await _repository.updateStaff(
        id: event.id,
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
        roleId: event.roleId,
      );
      emit(StaffUpdated(updatedStaff));
      // Refresh the list
      add(const StaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onStaffDeleteRequested(
    StaffDeleteRequested event,
    Emitter<StaffState> emit,
  ) async {
    try {
      await _repository.deleteStaff(event.id);
      emit(const StaffDeleted());
      // Refresh the list
      add(const StaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }
}
