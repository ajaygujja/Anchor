import 'package:anchor/core/copy.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:anchor/features/dashboard/view/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<HabitRepository>.value(
          value: habits,
          child: const DashboardPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the empty state when there are no habits', (tester) async {
    when(habits.watchActiveHabits).thenAnswer((_) => Stream.value(const []));

    await pumpDashboard(tester);

    expect(find.text(Copy.dashboardEmptyTitle), findsOneWidget);
    expect(find.text(Copy.addFirstHabit), findsOneWidget);
  });

  testWidgets('lists active habits', (tester) async {
    when(habits.watchActiveHabits).thenAnswer((_) => Stream.value([habit]));

    await pumpDashboard(tester);

    expect(find.text('Read'), findsOneWidget);
    expect(find.text(Copy.dashboardEmptyTitle), findsNothing);
  });
}
