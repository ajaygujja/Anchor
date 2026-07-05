import 'dart:async';

import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_state.dart';

/// Feeds the dashboard its active habit list (spec §11 Phase 2).
///
/// Phase 4 replaces this with the full `DashboardBloc` that composes habits
/// with entry streams for streaks and grace state (spec §5.3).
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._habits) : super(const DashboardState()) {
    _subscription = _habits.watchActiveHabits().listen(
      (habits) => emit(
        DashboardState(status: DashboardStatus.ready, habits: habits),
      ),
      onError: (Object _) =>
          emit(state.copyWith(status: DashboardStatus.failure)),
    );
  }

  final HabitRepository _habits;
  late final StreamSubscription<List<Habit>> _subscription;

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
