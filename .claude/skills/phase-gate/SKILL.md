---
name: phase-gate
description: Verify a spec phase's acceptance criteria with evidence before starting the next phase. Use when the user says "start phase N", "is phase N done", "phase gate", or before beginning any new phase of anchor-final-spec.md §11.
---

# Phase gate

The spec's rule is absolute: **do not start a phase before the previous
phase's acceptance criteria pass** (spec §11). This skill turns that into a
checked, evidenced procedure.

## Procedure

1. **Identify the boundary.** Read `anchor-final-spec.md` §11 and CLAUDE.md
   "Project status" to determine the completed phase N and the requested
   phase N+1. If they disagree, trust the repo (git log, file contents) and
   update CLAUDE.md.

2. **Quote the acceptance criteria** of phase N verbatim from the spec.

3. **Verify each criterion with a command or observation — not memory:**
   - Code criteria → read the actual files; run `/check` (the verification
     skill) for format/analyze/test/grep gates.
   - "Runs in Chrome against emulators" → `firebase emulators:start` +
     `flutter run -d chrome --dart-define=USE_EMULATORS=true`, exercise the flow.
   - "CI green" → `gh run list --limit 5` (or ask the user if `gh` is not
     authenticated) — a green local run is NOT CI green.
   - "Rules deployed" / console-side steps (IAM backup owner, auth provider
     enabled) → these are not verifiable from the repo; list them explicitly
     and ask the user to confirm each one. Never mark them assumed-done.
   - "Synced across two browser windows" and similar live behaviors → actually
     perform them, or state plainly that it was not performed.

4. **Produce the gate report:**

   | Criterion (spec quote) | Evidence | Status |
   |---|---|---|
   | ... | command + output / user confirmation / file:line | pass / fail / needs-user |

5. **Verdict.**
   - All pass → phase N is closed. Update CLAUDE.md "Project status", then
     list phase N+1's numbered work items from §11 as the plan.
   - Any fail → the gate is closed. Fix the failures first; do not begin
     phase N+1 work "in parallel".
   - Any needs-user → present the exact console steps/questions and stop.

## Standing phase reminders

- One PR per phase; CI must be green before merge.
- Placeholders are filled only in their designated phase.
- Spec §12 (out of scope for v1) overrides any mid-phase feature idea.
