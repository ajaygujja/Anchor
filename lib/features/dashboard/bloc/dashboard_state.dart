part of 'dashboard_cubit.dart';

/// Lifecycle of the dashboard's habit list.
enum DashboardStatus { loading, ready, failure }

/// State of [DashboardCubit].
final class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.habits = const [],
  });

  final DashboardStatus status;
  final List<Habit> habits;

  DashboardState copyWith({DashboardStatus? status, List<Habit>? habits}) {
    return DashboardState(
      status: status ?? this.status,
      habits: habits ?? this.habits,
    );
  }

  @override
  List<Object?> get props => [status, habits];
}
