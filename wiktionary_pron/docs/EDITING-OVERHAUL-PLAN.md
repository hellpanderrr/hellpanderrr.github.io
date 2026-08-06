# UI Editing & Copying Overhaul — Plan (v2)

_Status: proposal, pending approval. Written 2026-08-06. v1 proposed a "decisions replay"
state machine; a 4-member council (classicist, product-framer, adversarial architect,
plain-language explainer) unanimously rejected it. This v2 is the simplified, council-
validated plan. Maps to ISSUES M-004 (editable output) and M-007 (selectable/copyable)._

## 1. Problem

The output renders as `<span class="ipa" content="…">` painted via CSS `attr(content)`
(`css/style.css:451`). The visible text is a pseudo-element, so:

- Nothing is selectable, copyable per word/line, or findable (Ctrl+F).
- Nothing is editable.
- Screen readers see a wall of `role="button"` controls, not prose.

`resultToPlainText()` (`macronizer.html:1315`) reconstructs the text by re-reading the
`content` attribute, which is also the source for copy/CSV/PDF.

**What the real user actually needs** (classicist council): select/copy individual words
and lines, and edit the output directly. They fix ~2–6 words per page, then copy out.
They rarely re-run the same text; when they do, they want a **fresh** result, not old
decisions resurrected.

## 2. Goals & non-goals

**Goals**
- Output becomes real editable text (select/copy/type/delete natively).
- Fix errors in place (click-vowel toggle, or type a correction) — no full-input re-run.
- Keep the app's signature per-word ambiguity cycling (the feature Winge lacks).
- A **per-session accepted-names list** so proper names stop re-flagging.
- Honest confidence signals, never a fake number.

**Non-goals (rejected by the council)**
- **No "decisions replay" state machine.** Rejected for concrete bugs: it can't express a
  typed edit (new content, nothing to replay onto); condition "form still in candidate set"
  kills hand-fixes (a fix exists *because* the form is outside the set); type-vs-token
  over-applies one decision to every occurrence of a surface+lemma; unknowns have no lemma
  or candidate set so the anchor degenerates. Snapshot + name-list is strictly more robust.
- No guided "review pass" wizard (proofreaders don't want to be shepherded).
- No surfacing of the engine's internal `confidence` score — the engine's own source labels
  it "NOT a probabilistic confidence score"; it is coverage, and it is exactly what the
  user is correcting.
- No spell-check (macrons don't affect spelling).

## 3. The document model (foundation)

Replace `content`-attribute painting with **real text nodes**. Machine doubt (ambig/unknown)
becomes **overlays**, not mutations.

- **Keep the candidate list** — retain the engine's full ranked `accented[]` per word.
  Winge's `token.py:42` macronizes only `accented[0]` and throws the rest away (his #1 bug).
  We keep it so cycling is real.
- **Render** — one `setDisplay(span, text)` setter writes both `textContent` and `content`
  (sync), so the migration is e2e-neutral and exports migrate later. Every writer funnels
  through it (drift risk; the `Lituanian` typo warning in CLAUDE.md applies here).
- **Highlighting off `::before`** — `.ipa::before { content: attr(content) }` is not just
  the text painter: the `.ambig`/`.unknown` background flags live on the *same*
  pseudo-element. When text moves to `textContent`, the flags silently collapse. Move the
  highlight backgrounds onto the span itself in the same change. **This is the #1 trap.**

## 4. Interaction spec

| Gesture | Behavior |
|---|---|
| Single-click word | Place caret (never mutates). |
| Click a vowel | Toggle its macron (`ā`↔`a`, … `ȳ`↔`y`, both cases). Most discoverable correction gesture; structurally can't introduce a non-Latin typo. Winge's gesture, kept. |
| Cycle readings | Existing popup "Next spelling" button + Enter/Space (works on touch). **Not** Alt-click (least discoverable; collides with Cmd/Ctrl-click muscle memory). |
| Double-click word | Pin the popup / choose reading. Gives ambiguous words a "choose" gesture without stealing single-click. (New — prototype.) |
| Drag / triple-click | Native text selection (falls out of real text). Triple-click selects line. |
| Hover | Popup as today (inspect ≠ mutate); readings become selectable chips. |
| Keyboard | Tab word→word; Enter/Space cycle; Shift+Enter backward; arrows move the caret; Ctrl+Z/Y undo/redo over edits and toggles. |

**Explicit edit-mode toggle:** not needed — output is always editable (Winge's model), but
"editable" means the browser-native caret/selection; nothing mutates on a plain click.

## 5. Persistence model (small, robust)

Rejected replay in favor of a **snapshot + accepted-names list**.

- **Snapshot** — the corrected document is the user's own; persist the rendered output
  keyed by a **demacronized-input hash**. If the input is unchanged, restore the document
  verbatim; if the input changed, recompute (correct behavior — cannot over-apply, cannot
  misapply).
- **Accepted-names list** — a surface-keyed `Set` in localStorage (per-session, or
  optionally persisted) so proper names stop re-flagging. No lemma/candidate machinery:
  unknowns have no lemma or candidate set, so surface-keyed verbatim is the honest scope.
- **Store only deviations** — non-auto edits and accepted names. Skip "auto" decisions
  entirely (they add nothing).

**Storage** — `localStorage` (NOT IndexedDB — that's for the 500k-row lexicons; and NOT the
existing `macronizer_form`, which is pre-submit UI state). Keep it tiny.

**Safety rules**
- Typed macrons always win — never re-macronize a word the user typed macrons into.
- Copy/export reads the **rendered DOM** as the single source of truth (already the pattern
  in `resultToPlainText`), so what you see is what you copy.

## 6. Phased implementation

**Phase 1 — real text + selection/copy** (the load-bearing slice)
1. `setDisplay` setter (textContent + content sync); render real text nodes.
2. Move `.ambig`/`.unknown` highlighting off `::before` onto the span.
3. Keep `accented[]` candidate list on the span/token (already on `span.__token`).
4. Native selection + triple-click line select + hover per-line copy button.
5. Gate popup open on a `dragging` flag (hover flicker during drag-select).

**Phase 2 — editing**
6. Click-vowel macron toggle (Winge's gesture).
7. Type-to-edit in the output; exports read the DOM.
8. Double-click word → popup / choose reading.
9. Undo stack (Ctrl+Z/Y) over edits and toggles.

**Phase 3 — persistence + names**
10. Accepted-names list (surface-keyed `Set`); "stop flagging this name" action.
11. Document snapshot keyed by input hash; restore on unchanged input.
12. Typed-macrons-win guard.

**Phase 4 — a11y + polish**
13. Popup → managed dialog (focus trap, Enter/Space open, `aria-live` announcements).
14. A11y punch-list: real text + decoupled cycle control, keyboard selection path,
    CSV menu radio semantics (`menuitemradio` + `aria-checked`, roving tabindex).

## 7. Open decisions (for the owner)

1. **Double-click = popup/choose** — the one genuinely new gesture; prototype before
   committing.
2. **Per-session vs persisted accepted-names** — classicist council ranked "name accepts
   should ideally be global (across texts)" as the 2nd-most-valuable persistence; architect
   prefers per-session throwaway. Decide scope.
3. **Whether to keep `content` in sync indefinitely** or migrate e2e assertions to
   `textContent` once Phase 1 lands.

## 8. Related work not in scope

- M-005 (dictionary definition in popup) — independent, popup-side.
- M-006 (readings-first popup, already done in `1b9357b`) — done.
- Wordlist gate (storage-mode decision at page bottom) — separate UX cleanup.

## Key files

- `macronizer.html` — all render/cycle/popup/export logic.
- `css/style.css:451` — the `attr(content)` painter + highlight backgrounds.
- `e2e/macronizer.spec.js`, `e2e/popup-check.spec.js` — 7+ assertions on `content` attrs.
- Reference: Winge's source (`alatius.com/macronizer/`, GitHub `Alatius/latin-macronizer`).

## Rejected (v1) — why not decisions-replay

The v1 model stored per-word decisions (auto/cycled/hand-fixed/accepted-unknown) and
replayed them onto fresh engine output, keyed by surface+lemma. The council's concrete
objections:

- **No answer for typed edits** — a hand-typed word is new content with nothing to replay
  onto; position keys break when length changes.
- **Condition (3) kills hand-fixes** — "form still in candidate set" fails exactly when the
  user fixed a word the engine got wrong (the fix is by definition outside the set) →
  the fix silently evaporates on re-run.
- **Type vs token** — keyed by surface+lemma, a decision applies to *every* occurrence;
  one fixed `malum` silently fixes all four, even the ones left as auto.
- **Unknowns degenerate** — no lemma, no candidate set → the accepted-name anchor collapses
  to surface + "guess still byte-identical," re-flagging on any engine change.
- **State drift** — stored lemmas go stale (this codebase already had corrupt Morpheus
  lemmas, `currito_,curro`), silently under-applying.
- **Snapshot + name-list is strictly more robust** and ~15% of the complexity.
