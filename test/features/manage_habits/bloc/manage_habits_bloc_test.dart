import 'package:anchor/core/failures.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:anchor/features/manage_habits/bloc/manage_habits_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late HabitRepository habits;

  const active = Habit(
    id: 'a1',
    name: 'Read',
    createdAt: null,
    archived: false,
    sortOrder: 0,
  );
  const archived = Habit(
    id: 'z1',
    name: 'Old',
    createdAt: null,
    archived: true,
    sortOrder: 9,
  );

  setUp(() {
    habits = _MockHabitRepository();
  });

  void stubStreams({
    List<Habit> activeList = const [],
    List<Habit> archivedList = const [],
  }) {
    when(habits.watchActiveHabits).thenAnswer((_) => Stream.value(activeList));
    when(
      habits.watchArchivedHabits,
    ).thenAnswer((_) => Stream.value(archivedList));
  }

  group('ManageHabitsBloc', () {
    test('initial state is loading', () {
      stubStreams();
      expect(
        ManageHabitsBloc(habits).state.status,
        ManageHabitsStatus.loading,
      );
    });

    blocTest<ManageHabitsBloc, ManageHabitsState>(
      'subscription emits ready with active then archived lists',
      setUp: () => stubStreams(activeList: [active], archivedList: [archived]),
      build: () => ManageHabitsBloc(habits),
      act: (bloc) => bloc.add(const ManageHabitsSubscriptionRequested()),
      expect: () => [
        const ManageHabitsState(
          status: ManageHabitsStatus.ready,
          active: [active],
        ),
        const ManageHabitsState(
          status: ManageHabitsStatus.ready,
          active: [active],
          archived: [archived],
        ),
      ],
    );

    blocTest<ManageHabitsBloc, ManageHabitsState>(
      'add delegates to the repository',
      setUp: () {
        stubStreams();
        when(
          () => habits.addHabit(name: any(named: 'name')),
        ).thenAnswer((_) async {});
      },
      build: () => ManageHabitsBloc(habits),
      act: (bloc) => bloc.add(const ManageHabitAdded(name: 'Walk')),
      expect: () => const <ManageHabitsState>[],
      verify: (_) => verify(() => habits.addHabit(name: 'Walk')).called(1),
    );

    blocTest<ManageHabitsBloc, ManageHabitsState>(
      'reorder delegates to the repository',
      setUp: () {
        stubStreams();
        when(() => habits.reorder(any())).thenAnswer((_) async {});
      },
      build: () => ManageHabitsBloc(habits),
      act: (bloc) => bloc.add(const ManageHabitsReordered(['b', 'a'])),
      verify: (_) => verify(() => habits.reorder(['b', 'a'])).called(1),
    );

    blocTest<ManageHabitsBloc, ManageHabitsState>(
      'a failed mutation raises then clears actionFailed',
      setUp: () {
        stubStreams();
        when(
          () => habits.addHabit(name: any(named: 'name')),
        ).thenThrow(const NetworkFailure());
      },
      build: () => ManageHabitsBloc(habits),
      act: (bloc) => bloc.add(const ManageHabitAdded(name: 'Walk')),
      expect: () => [
        const ManageHabitsState(actionFailed: true),
        const ManageHabitsState(),
      ],
    );
  });
}
