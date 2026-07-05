---
name: add-copy
description: Add or change user-facing text in Anchor with the correct voice and single-source placement in core/copy.dart. Use whenever adding labels, messages, nudges, milestone lines, empty states, or error text.
---

# Adding user-facing copy

Every string a user can read lives in `lib/core/copy.dart` (spec §2.4) so the
app's voice stays auditable and consistent. An inline literal in a widget is a
review-blocker.

## Voice rules (from the spec's philosophy)

- **Quiet, invitational, identity-level.** The app never guilts, alarms, or
  celebrates loudly.
- Banned: exclamation marks in encouragement, streak-loss shaming, urgency
  framing ("don't lose it!", "hurry"), gamification vocabulary (points, badges,
  fire/flame), emoji.
- Reference tones already locked by the spec:
  - Grace nudge: *"Yesterday was a rest. Today keeps it alive."*
  - Day-30 milestone: *"This is who you are now."*
  - Weekly recap: *"Last week: 5 of 7 days — steady."*
  - Empty state: *"One habit is enough to start."*
- Milestone thresholds are fixed: 7, 21, 30, 60, 100, 180, 365.

## Procedure

1. Read the current `lib/core/copy.dart` to match its existing structure and
   naming (static consts on `Copy`, grouped by feature as it grows).
2. Add the string as a `static const`. Name by role, not content:
   `graceNudge`, not `yesterdayWasARest`.
3. Parameterized copy (counts, dates) → a static method on `Copy` returning
   the composed string; date formatting via `intl` stays inside `Copy`, not in
   widgets.
4. Reference the constant from the widget.
5. Verify no literal escaped into the widget layer: check the diff for quoted
   user-readable strings under `lib/features/`.
6. Read the new line aloud against the voice rules above. If it sounds like a
   fitness app notification, rewrite it.
