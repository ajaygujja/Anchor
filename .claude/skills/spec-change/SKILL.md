---
name: spec-change
description: Procedure for changing anchor-final-spec.md when a decision, scope item, schema field, or convention needs to differ from the written spec. Use when a request contradicts the spec, adds scope, or alters locked decisions.
---

# Changing the spec

The spec is law (CLAUDE.md). When reality needs to differ, the spec changes
first — code never silently diverges from it.

## When this fires

- A request contradicts a locked decision (spec §1) or the streak/boundary
  semantics (§2.1, §3).
- A request adds something §12 lists as out of scope.
- A schema field, package, bloc, repository, or feature dir outside the
  spec's closed sets.
- A convention conflict discovered during implementation (the spec said X,
  the code needs Y).

## Procedure

1. **Name the conflict precisely.** Quote the spec section verbatim and state
   the requested divergence in one sentence.
2. **Present the trade-off to Ajay** — the spec's rationale vs. the new need.
   Recommend one option. Do NOT implement while this is open.
3. On approval, **edit `anchor-final-spec.md` itself**: update the relevant
   section, and add a row to the §1 decision table when a locked decision
   changed (number, decision, rationale).
4. **Propagate** in the same change set, checking each concretely:
   - `.claude/rules/*.md` — any rule quoting the old behavior.
   - `CLAUDE.md` — invariants and status.
   - `firestore.rules` + `firestore-tests/` — if data shape changed.
   - `lib/core/copy.dart` — if user-facing behavior changed.
   - Test tables — if streak/boundary semantics changed.
5. Commit the spec change separately from (and before) the implementation, so
   history shows the decision preceding the code.

## What this skill is NOT for

Bug fixes toward spec-described behavior, refactors that preserve behavior,
or filling placeholders in their designated phase — those need no spec change.
