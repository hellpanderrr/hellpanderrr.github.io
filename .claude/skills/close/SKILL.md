---
name: close
description: Use when the user says /close, "close the session", "wrap up", "done for now", or is about to /clear or /compact. Writes the session's state into the repo so the conversation can be discarded losslessly, then tells the user exactly how to resume.
---

# Closing a session

The point: move everything worth keeping out of the conversation and into the
repo, so `/clear` costs nothing. Never suggest `/compact` as the way to finish
work — compaction is for surviving a task that genuinely cannot be split, not
for ending one.

Work through these in order. Skip a step only if it plainly does not apply, and
say which you skipped.

## 1. Establish what actually happened

Do not reconstruct this from memory of the conversation — read it:

- `git status --short` and `git diff --stat` (plus `git diff --stat --cached`)
- `git log --oneline` since the session started, if anything was committed
- any output/data files written this session (check mtimes, not recollection)

## 2. Run the verification that matters

If code changed, run the project's tests — **gate on the test runner's own exit
code**, never on a filtered view of it (`pytest | tail` reports tail's status).
If a long job is running, check it by the WORK — output file growing — not by a
process name or a launcher's exit code.

Report failures plainly. Do not close a session by claiming success you did not
observe.

## 3. Capture lessons, not narrative

Review the diff for problems, dead ends and gotchas: wrong assumptions,
misleading docs, silent failures, bugs that only appeared at runtime. If one is
non-obvious and likely to recur, append a dated one-line entry to the project's
lessons file (`docs/LESSONS.md` here; otherwise ask where).

Nothing worth logging is a valid outcome. Do not manufacture entries.

## 3b. Annotate, never delete

**Nothing is removed from the knowledge files.** They are append-only. What
changes is their *status*, in place:

- **Did this session make a logged lesson enforced?** If a test, hook or code
  guard now covers it, append `✅ enforced by <path>` to that entry. Leave the
  entry. The annotation is the useful part — it tells the next reader a guard
  exists.
- **Did a lesson recur in a second area?** Add the standing form to
  `CLAUDE.md`'s rules and leave both dated entries where they are.
- **Is something in `CLAUDE.md` no longer true?** That file is the exception:
  it is loaded every session, so a stale instruction there gets *followed*.
  Correct it, and move the superseded detail to `docs/LESSONS.md` with its date
  rather than dropping it.
- **Check the load cap.** If `CLAUDE.md` exceeds ~35k chars, say so and propose
  what to *move out* (never what to destroy). Do not let it pass silently.

## 3c. Findings that outlived the session

If the work is audit- or mining-shaped and produced findings you did not fix,
they belong in `docs/ISSUES.md` with a stable ID — not in prose, and not only
in the commit message. Without an ID the next round re-finds them.

If `ISSUES.md` exists: append new findings, set `Status: FIXED` on anything
this session resolved (the row stays, with its evidence), and re-count the
totals by machine rather than by eye. Never renumber an ID.

If it does not exist and the work is finding-shaped, propose creating it.

## 3d. Reconcile this session's artifacts

Creating a file is one call; reconciling is search+read+judge — so it happens
here, once, not per-file. List what this session created (`git status --short`
plus new untracked files). Each is one of:

- **regenerable** — a tracked script writes it → leave it;
- **durable** — cite it from the doc that should own it (a topical doc if it is
  reusable knowledge, not a chronological log);
- **scratch** — it belongs in the project's dated scratch dir; if the project
  has no such convention, propose one rather than leaving loose files at the top
  level;
- **superseding** — mark the file it replaces as superseded and reconcile the
  two; never leave both live with contradicting numbers.

**Session dirs get a `FINDINGS.md`.** If this session's dated scratch dir
holds more than a couple of artifacts (CSVs, JSON dumps, run logs), write or
update a `FINDINGS.md` in it: the question, the method, results with counts,
which claims were hand-verified vs not, and caveats. It is the entry point
that makes the artifacts interpretable without replaying the session. If the
findings feed a registered issue or a standing doc, cite the FINDINGS.md from
that doc's row — citation is what graduates it from scratch; an uncited
findings file is invisible to the next session.

If the project defines a provenance/artifact gate (its `CLAUDE.md` will name
it), run it and gate on its exit code.

## 3e. Class-probe any user correction

If the user caught an error this session — a stale line, a dropped file, a wrong
ruling — do NOT fix only that instance. Sweep for the rest of its class before
closing, and record the sweep result, not just the point fix.

## 4. Write the handoff

Update `NEXT.md` at the repo root — overwrite it, it is a baton and not a
journal. Keep it under ~30 lines, four sections:

```markdown
# Next

_Updated <date> — branch <name>_

## State
Where things stand. What is done and verified, in one or two sentences.

## Open threads
- Concrete next action, with the file or command it starts from.

## Running / unfinished
Background jobs, half-done edits, anything a fresh session would not
otherwise discover. Include how to check on it.

## Don't redo
Things that look undone but are deliberate, and dead ends already ruled out.
```

The `Don't redo` section is the one that pays. It is what stops the next
session re-deriving a settled fact.

## 5. Commit

Stage by **explicit path** — never `git add -A`, which sweeps caches and
scratch output into permanent history. Commit with a message that states what
changed and why. Do not push unless asked.

## 6. Tell the user how to resume

Close with exactly this, filled in:

> Committed `<sha>`. Safe to `/clear`.
> To pick this up: **`read NEXT.md and continue`**

Then stop. Do not start new work after closing.
