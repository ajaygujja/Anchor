import 'package:anchor/core/copy.dart';
import 'package:anchor/core/theme/theme.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:anchor/features/manage_habits/bloc/manage_habits_bloc.dart';
import 'package:anchor/features/manage_habits/widgets/habit_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add, rename, archive/restore, and reorder habits (spec §2.2D).
class ManageHabitsPage extends StatelessWidget {
  const ManageHabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ManageHabitsBloc(context.read<HabitRepository>())
            ..add(const ManageHabitsSubscriptionRequested()),
      child: const _ManageHabitsView(),
    );
  }
}

class _ManageHabitsView extends StatelessWidget {
  const _ManageHabitsView();

  Future<void> _add(BuildContext context) async {
    final result = await HabitEditSheet.show(context);
    if (result == null || !context.mounted) return;
    context.read<ManageHabitsBloc>().add(
      ManageHabitAdded(name: result.name, color: result.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.manageHabits)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text(Copy.addHabit),
      ),
      body: BlocConsumer<ManageHabitsBloc, ManageHabitsState>(
        listenWhen: (previous, current) => current.actionFailed,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(Copy.habitActionFailed)),
            );
        },
        builder: (context, state) {
          return switch (state.status) {
            ManageHabitsStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ManageHabitsStatus.failure => const _Retry(),
            ManageHabitsStatus.ready => _HabitLists(state: state),
          };
        },
      ),
    );
  }
}

class _HabitLists extends StatelessWidget {
  const _HabitLists({required this.state});

  final ManageHabitsState state;

  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    final ids = state.active.map((habit) => habit.id).toList();
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = ids.removeAt(oldIndex);
    ids.insert(adjusted, moved);
    context.read<ManageHabitsBloc>().add(ManageHabitsReordered(ids));
  }

  @override
  Widget build(BuildContext context) {
    if (state.active.isEmpty && state.archived.isEmpty) {
      return const Center(child: Text(Copy.manageEmpty));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.active.length,
          onReorder: (oldIndex, newIndex) =>
              _reorder(context, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final habit = state.active[index];
            return _ActiveHabitTile(
              key: ValueKey(habit.id),
              habit: habit,
              index: index,
            );
          },
        ),
        if (state.archived.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(Copy.archivedSection),
          ),
          for (final habit in state.archived) _ArchivedHabitTile(habit: habit),
        ],
      ],
    );
  }
}

class _ActiveHabitTile extends StatelessWidget {
  const _ActiveHabitTile({
    required this.habit,
    required this.index,
    super.key,
  });

  final Habit habit;
  final int index;

  Future<void> _rename(BuildContext context) async {
    final result = await HabitEditSheet.show(
      context,
      initialName: habit.name,
    );
    if (result == null || !context.mounted) return;
    context.read<ManageHabitsBloc>().add(
      ManageHabitRenamed(id: habit.id, name: result.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _HabitDot(color: habit.color),
      title: Text(habit.name),
      onTap: () => _rename(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: Copy.archive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => context.read<ManageHabitsBloc>().add(
              ManageHabitArchived(habit.id),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
  }
}

class _ArchivedHabitTile extends StatelessWidget {
  const _ArchivedHabitTile({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _HabitDot(color: habit.color),
      title: Text(
        habit.name,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      trailing: TextButton(
        onPressed: () => context.read<ManageHabitsBloc>().add(
          ManageHabitRestored(habit.id),
        ),
        child: const Text(Copy.restore),
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

class _Retry extends StatelessWidget {
  const _Retry();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.read<ManageHabitsBloc>().add(
          const ManageHabitsSubscriptionRequested(),
        ),
        child: const Text(Copy.habitActionFailed),
      ),
    );
  }
}
