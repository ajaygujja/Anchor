import 'dart:async';

import 'package:anchor/core/failures.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'manage_habits_event.dart';
part 'manage_habits_state.dart';

/// Owns the Manage screen: active and archived habit lists plus create,
/// rename, archive/restore, and reorder (spec §2.2D, §5.3).
class ManageHabitsBloc extends Bloc<ManageHabitsEvent, ManageHabitsState> {
  ManageHabitsBloc(this._habits) : super(const ManageHabitsState()) {
    on<ManageHabitsSubscriptionRequested>(_onSubscriptionRequested);
    on<ManageHabitAdded>(_onAdded);
    on<ManageHabitRenamed>(_onRenamed);
    on<ManageHabitArchived>(_onArchived);
    on<ManageHabitRestored>(_onRestored);
    on<ManageHabitsReordered>(_onReordered);
    on<_ManageActiveUpdated>(_onActiveUpdated);
    on<_ManageArchivedUpdated>(_onArchivedUpdated);
    on<_ManageStreamFailed>(_onStreamFailed);
  }

  final HabitRepository _habits;
  StreamSubscription<List<Habit>>? _activeSub;
  StreamSubscription<List<Habit>>? _archivedSub;

  Future<void> _onSubscriptionRequested(
    ManageHabitsSubscriptionRequested event,
    Emitter<ManageHabitsState> emit,
  ) async {
    _activeSub ??= _habits.watchActiveHabits().listen(
      (habits) => add(_ManageActiveUpdated(habits)),
      onError: (Object _) => add(const _ManageStreamFailed()),
    );
    _archivedSub ??= _habits.watchArchivedHabits().listen(
      (habits) => add(_ManageArchivedUpdated(habits)),
      onError: (Object _) => add(const _ManageStreamFailed()),
    );
  }

  Future<void> _onAdded(
    ManageHabitAdded event,
    Emitter<ManageHabitsState> emit,
  ) {
    return _mutate(
      emit,
      () => _habits.addHabit(name: event.name, color: event.color),
    );
  }

  Future<void> _onRenamed(
    ManageHabitRenamed event,
    Emitter<ManageHabitsState> emit,
  ) {
    return _mutate(
      emit,
      () => _habits.renameHabit(id: event.id, name: event.name),
    );
  }

  Future<void> _onArchived(
    ManageHabitArchived event,
    Emitter<ManageHabitsState> emit,
  ) {
    return _mutate(
      emit,
      () => _habits.setArchived(id: event.id, archived: true),
    );
  }

  Future<void> _onRestored(
    ManageHabitRestored event,
    Emitter<ManageHabitsState> emit,
  ) {
    return _mutate(
      emit,
      () => _habits.setArchived(id: event.id, archived: false),
    );
  }

  Future<void> _onReordered(
    ManageHabitsReordered event,
    Emitter<ManageHabitsState> emit,
  ) {
    return _mutate(emit, () => _habits.reorder(event.orderedIds));
  }

  void _onActiveUpdated(
    _ManageActiveUpdated event,
    Emitter<ManageHabitsState> emit,
  ) {
    emit(
      state.copyWith(
        status: ManageHabitsStatus.ready,
        active: event.habits,
      ),
    );
  }

  void _onArchivedUpdated(
    _ManageArchivedUpdated event,
    Emitter<ManageHabitsState> emit,
  ) {
    emit(
      state.copyWith(
        status: ManageHabitsStatus.ready,
        archived: event.habits,
      ),
    );
  }

  void _onStreamFailed(
    _ManageStreamFailed event,
    Emitter<ManageHabitsState> emit,
  ) {
    emit(state.copyWith(status: ManageHabitsStatus.failure));
  }

  Future<void> _mutate(
    Emitter<ManageHabitsState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Failure {
      emit(state.copyWith(actionFailed: true));
      emit(state.copyWith(actionFailed: false));
    }
  }

  @override
  Future<void> close() {
    unawaited(_activeSub?.cancel());
    unawaited(_archivedSub?.cancel());
    return super.close();
  }
}
