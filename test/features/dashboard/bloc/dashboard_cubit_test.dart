import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:anchor/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late HabitRepository habits;

  const habit = Habit(
    id: 'a1',
    name: 'Read',
    createdAt: null,
    archived: false,
    sortOrder: 0,
  );

  setUp(() {
    habits = _MockHabitRepository();
  });

  group('DashboardCubit', () {
    blocTest<DashboardCubit, DashboardState>(
      'emits ready with the active habits from the stream',
      setUp: () => when(
        habits.watchActiveHabits,
      ).thenAnswer((_) => Stream.value([habit])),
      build: () => DashboardCubit(habits),
      expect: () => [
        const DashboardState(status: DashboardStatus.ready, habits: [habit]),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits ready with an empty list when there are no habits',
      setUp: () => when(
        habits.watchActiveHabits,
      ).thenAnswer((_) => Stream.value(const [])),
      build: () => DashboardCubit(habits),
      expect: () => [
        const DashboardState(status: DashboardStatus.ready),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits failure when the stream errors',
      setUp: () => when(
        habits.watchActiveHabits,
      ).thenAnswer((_) => Stream.error(Exception('boom'))),
      build: () => DashboardCubit(habits),
      expect: () => [
        const DashboardState(status: DashboardStatus.failure),
      ],
    );
  });
}
