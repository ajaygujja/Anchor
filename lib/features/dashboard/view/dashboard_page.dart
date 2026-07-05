import 'package:anchor/app/router.dart';
import 'package:anchor/core/copy.dart';
import 'package:anchor/core/theme/theme.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:anchor/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The daily home screen.
///
/// Phase 2 shows the active habit list (or the first-run empty state) and the
/// entry point to Manage. Streaks, the quote card, and check-in controls land
/// in later phases (spec §11).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(context.read<HabitRepository>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.appName),
        actions: [
          IconButton(
            tooltip: Copy.manageHabits,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.manage),
          ),
          IconButton(
            tooltip: Copy.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              return switch (state.status) {
                DashboardStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                DashboardStatus.failure => const Center(
                  child: Text(Copy.habitActionFailed),
                ),
                DashboardStatus.ready when state.habits.isEmpty =>
                  const _EmptyState(),
                DashboardStatus.ready => _HabitList(habits: state.habits),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  const _HabitList({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ListTile(
          leading: _HabitDot(color: habit.color),
          title: Text(habit.name),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Copy.dashboardEmptyTitle,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push(Routes.manage),
            child: const Text(Copy.addFirstHabit),
          ),
        ],
      ),
    );
  }
}

/// Small colour dot for a habit, falling back to the theme's neutral tint.
class _HabitDot extends StatelessWidget {
  const _HabitDot({required this.color});

  final String? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AnchorTheme.swatchColor(color) ?? scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    );
  }
}
