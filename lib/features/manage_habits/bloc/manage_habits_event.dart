part of 'manage_habits_bloc.dart';

/// Base type for [ManageHabitsBloc] events.
sealed class ManageHabitsEvent extends Equatable {
  const ManageHabitsEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the active and archived habit streams. Dispatched once
/// at bloc creation.
final class ManageHabitsSubscriptionRequested extends ManageHabitsEvent {
  const ManageHabitsSubscriptionRequested();
}

/// Creates a habit with the given name and optional swatch.
final class ManageHabitAdded extends ManageHabitsEvent {
  const ManageHabitAdded({required this.name, this.color});

  final String name;
  final String? color;

  @override
  List<Object?> get props => [name, color];
}

/// Renames the habit with [id].
final class ManageHabitRenamed extends ManageHabitsEvent {
  const ManageHabitRenamed({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Archives the habit with [id]; its entries are kept.
final class ManageHabitArchived extends ManageHabitsEvent {
  const ManageHabitArchived(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Restores the archived habit with [id] to the active list.
final class ManageHabitRestored extends ManageHabitsEvent {
  const ManageHabitRestored(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Persists a new active-habit ordering (full set, top to bottom).
final class ManageHabitsReordered extends ManageHabitsEvent {
  const ManageHabitsReordered(this.orderedIds);

  final List<String> orderedIds;

  @override
  List<Object?> get props => [orderedIds];
}

/// Internal: the active-habits stream emitted a new list.
final class _ManageActiveUpdated extends ManageHabitsEvent {
  const _ManageActiveUpdated(this.habits);

  final List<Habit> habits;

  @override
  List<Object?> get props => [habits];
}

/// Internal: the archived-habits stream emitted a new list.
final class _ManageArchivedUpdated extends ManageHabitsEvent {
  const _ManageArchivedUpdated(this.habits);

  final List<Habit> habits;

  @override
  List<Object?> get props => [habits];
}

/// Internal: a habit stream reported an error.
final class _ManageStreamFailed extends ManageHabitsEvent {
  const _ManageStreamFailed();
}
