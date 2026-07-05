part of 'manage_habits_bloc.dart';

/// Lifecycle of the Manage screen's habit lists.
enum ManageHabitsStatus { loading, ready, failure }

/// State of [ManageHabitsBloc].
final class ManageHabitsState extends Equatable {
  const ManageHabitsState({
    this.status = ManageHabitsStatus.loading,
    this.active = const [],
    this.archived = const [],
    this.actionFailed = false,
  });

  final ManageHabitsStatus status;
  final List<Habit> active;
  final List<Habit> archived;

  /// Whether the last mutation failed; drives one quiet retry line, then
  /// resets to `false`.
  final bool actionFailed;

  ManageHabitsState copyWith({
    ManageHabitsStatus? status,
    List<Habit>? active,
    List<Habit>? archived,
    bool? actionFailed,
  }) {
    return ManageHabitsState(
      status: status ?? this.status,
      active: active ?? this.active,
      archived: archived ?? this.archived,
      actionFailed: actionFailed ?? this.actionFailed,
    );
  }

  @override
  List<Object?> get props => [status, active, archived, actionFailed];
}
