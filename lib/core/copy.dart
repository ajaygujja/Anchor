/// Every user-facing string lives here so the app's voice is auditable and
/// consistent (spec §2.4). Populated as features land in later phases.
///
/// The voice is quiet, invitational, identity-level — never guilt, never alarm,
/// never celebration.
abstract final class Copy {
  static const appName = 'Anchor';
  static const philosophy = 'Never miss twice.';

  static const continueWithGoogle = 'Continue with Google';
  static const signOut = 'Sign out';

  /// Shown quietly when sign-in fails for a non-cancellation reason.
  static const signInFailed = "Couldn't sign in. Try again.";

  // Dashboard (spec §2.2B).
  static const dashboardEmptyTitle = 'One habit is enough to start.';
  static const addFirstHabit = 'Add your first habit';

  // Manage habits (spec §2.2D).
  static const manageHabits = 'Manage habits';
  static const addHabit = 'Add habit';
  static const editHabit = 'Edit habit';
  static const habitNameLabel = 'Habit name';
  static const habitColorLabel = 'Colour';
  static const save = 'Save';
  static const archive = 'Archive';
  static const restore = 'Restore';
  static const archivedSection = 'Archived';
  static const manageEmpty = 'No habits yet.';

  /// Shown quietly when a habit operation fails.
  static const habitActionFailed = "Couldn't save that. Try again.";
}
