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

  /// Placeholder home copy until the dashboard lands (spec §11 Phase 2).
  static const dashboardComingSoon = 'Your habits will live here.';
}
