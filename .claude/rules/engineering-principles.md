# Engineering Principles

Industry-standard principles, each bound to this codebase and each **testable**
— every principle carries a check a reviewer (human or Claude) can actually
run or answer yes/no. A principle without a check is an opinion; don't add one
here without its test.

## SOLID

**S — Single Responsibility.** One reason to change per class/file: a bloc
manages one screen's state; a repository fronts one aggregate; the calculator
computes streaks and nothing else.
*Test:* describe the file's job in one sentence without "and". Fails → split.

**O — Open/Closed.** Extend via new implementations of existing abstractions
(a future mobile `AuthRepository` impl) rather than editing stable domain code.
*Test:* does the diff modify `lib/domain/` to support a platform/data concern?
Fails → the abstraction is wrong or the code is in the wrong layer.

**L — Liskov Substitution.** Any `XRepository` implementation (Firestore, fake,
mock) must honor the interface contract documented in its dartdoc —
idempotency, ordering, null semantics.
*Test:* bloc tests pass unchanged with mocktail fakes substituted for real
implementations. Contract facts appear in the interface's dartdoc, not only in
the impl.

**I — Interface Segregation.** Repository interfaces expose only what their
consumers use.
*Test:* `grep` each interface method's usages; a method with zero call sites
outside tests gets deleted, not kept "for later" (see YAGNI).

**D — Dependency Inversion.** Presentation and domain depend on abstractions;
concretes are chosen once, in `lib/app/di.dart`.
*Test:* the architecture greps in `architecture.md` print nothing; no
`Firestore*Repository` type name appears under `lib/features/`.

## Core principles

**DRY — with the rule of three.** Extract shared logic on the third
occurrence, not the second. A premature abstraction is more expensive than a
duplicated line; two similar habit-card branches may stay similar.
*Test:* before extracting, point to ≥3 call sites; before duplicating a third
time, extract.

**KISS.** The simplest design that satisfies the spec: no service locator, no
code-gen, no state-machine frameworks, single-column layout, `set(merge:true)`
instead of transactions.
*Test:* can a simpler construct (function over class, Cubit over Bloc where
spec allows, plain stream over rx) do the same job? If yes, use it.

**YAGNI.** Build for the spec's phases, not imagined futures. Explicitly
banned speculative work: stored aggregates, breakpoint forks, App Check,
pagination, export (spec §12).
*Test:* every new public symbol has a caller in the same PR (or its designated
phase's PR). Dead placeholders are only the spec-sanctioned phase stubs.

**Single Source of Truth.** Firestore entries are the only persisted facts;
everything else derives at read time.
*Test:* editing any past entry self-heals streaks/heatmap/recap with zero
recompute jobs. Any persisted number that could be recomputed = violation.

**Fail fast, fail loud (at boundaries).** Invalid data is rejected at the
edge — security rules validate shape server-side; DTOs surface corrupt docs as
`Failure`s. Inside domain, invariants are encoded in types (sealed classes,
non-null by default), not runtime checks scattered everywhere.
*Test:* every `FirebaseException` path maps to a sealed `Failure` in the data
layer; no empty `catch`, no `catch` that only logs.

**Pure core, effects at the edge (functional core, imperative shell).**
Business decisions (`streak_calculator`, `day_boundary` math) are pure
functions; I/O lives in repositories; blocs orchestrate.
*Test:* `lib/domain/streaks/` needs no mocks to reach 100% branch coverage —
if a domain test needs a mock, logic leaked outward.

**Immutability.** Entities, states, and DTO outputs are immutable
(`final` fields, `const` constructors where possible); state changes are new
`Equatable` instances.
*Test:* `flutter analyze` clean under very_good_analysis (`prefer_final_*`,
`prefer_const_*` are active); no setters on entities or states.

**Principle of Least Astonishment.** Follow platform and codebase convention:
Effective Dart naming, go_router for back-button correctness, Material 3
patterns, and whatever pattern Phase 1 established.
*Test:* the new code is indistinguishable in style from the file next to it.

**Composition over inheritance.** Widgets compose; behavior variation goes
through injected collaborators, not subclassing. No `extends` of a concrete
project class.
*Test:* `grep -rn "extends " lib/ --include="*.dart"` shows only framework
types (StatelessWidget, Cubit, Bloc, Equatable, Failure…) on the right side.

**Boy Scout Rule — scoped.** Leave touched files cleaner (naming, dead code,
comment rot), but a bug-fix PR stays a bug-fix PR; drive-by refactors of
untouched files belong in their own commit.
*Test:* the diff's file list matches the task's stated scope.

## Comment & documentation style (Effective Dart, enforced)

Format: `///` doc comments on public API; `//` for rare implementation notes;
no block comments (`/* */`) for docs.

1. **A comment states what the code cannot say**: a constraint, an invariant,
   a spec citation, a non-obvious why. Never what the next line does, never
   the history of the change, never a justification aimed at a reviewer.
   *Test:* delete the comment mentally — if the code still conveys everything
   the comment said, the comment goes. If it references "before/after/now/
   previously/instead of", it goes.
2. **Doc comments describe what a symbol IS, timelessly.** First line: one
   sentence, ending with a period, separated as its own paragraph. Functions
   start with a third-person verb ("Returns…", "Computes…"); non-boolean
   properties are noun phrases ("The number of…"); booleans start "Whether…".
   *Test:* read the first sentence alone — it fully identifies the symbol.
3. **Reference identifiers in square brackets** (`[StreakResult]`, `[today]`)
   so dartdoc links them.
   *Test:* backticks around an in-scope identifier in a doc comment = wrong
   form.
4. **Cite the spec for spec-driven constraints**: `(spec §3)`. This makes the
   constraint auditable years later.
   *Test:* the cited section actually says what the comment claims — open it.
5. **No commented-out code.** Git remembers.
   *Test:* `grep -rn "^\s*// .*;\s*$" lib/ --include="*.dart"` candidates get
   reviewed and removed.
6. **TODOs carry an owner and a target**: `// TODO(ajay): <action>, Phase N`.
   *Test:* `grep -rn "TODO" lib/` — every hit matches this shape; a TODO
   without a phase/issue is either done now or deleted.
7. **Don't document the obvious.** `public_member_api_docs` is deliberately
   off: a doc comment on `AnchorApp` saying "The Anchor app." is noise —
   document where meaning is non-obvious, skip where it isn't.
   *Test:* the comment survives rule 1's deletion test.

## Meta-rule: verifiability

Every claim in a PR description or task report is backed by an executed
command, a file:line reference, or a spec citation. "Should work" is not a
state of the world; it's a hypothesis awaiting `flutter test`.
