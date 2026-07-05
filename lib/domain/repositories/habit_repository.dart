import 'package:anchor/domain/entities/habit.dart';

/// Persistence boundary for habits, scoped to the current user (spec §5.1).
///
/// Watches are Firestore snapshot streams so devices stay live-synced;
/// mutations are one-shot futures. Mutating methods throw a sealed `Failure`
/// (never a raw platform exception) so the UI layer never sees provider types.
abstract interface class HabitRepository {
  /// Emits active (non-archived) habits ordered by `sortOrder` ascending.
  Stream<List<Habit>> watchActiveHabits();

  /// Emits archived habits ordered by `sortOrder` ascending.
  Stream<List<Habit>> watchArchivedHabits();

  /// Creates a habit appended after the current last one.
  Future<void> addHabit({required String name, String? color});

  /// Renames an existing habit.
  Future<void> renameHabit({required String id, required String name});

  /// Sets the archived flag; archiving hides a habit without deleting entries.
  Future<void> setArchived({required String id, required bool archived});

  /// Persists a new active-habit ordering; [orderedIds] is the full active set
  /// in its intended top-to-bottom order.
  Future<void> reorder(List<String> orderedIds);
}
