---
name: mr-review
description: Adversarial review of a GitLab merge request or GitHub pull request, posted as a comment on it. Resolves the MR/PR from an argument (`!42`, `#67`, or a full URL) or, with no argument, from the current checkout branch. Use when asked to review an MR/PR, "review my merge request", "review !42", "review this branch's PR".
---

# MR/PR review

Review a merge request **adversarially** and deliver the findings as a comment
on the MR itself, not only in the terminal.

Adversarial means: assume the change is wrong until the code proves otherwise.
Hunt for the edge case where it breaks, the side effect nobody traced, the
simpler version that was not written. Push limits — an approving review is
earned, not the default.

That stance governs the **search**. It does not lower the bar for **reporting**:
every finding still has to survive step 5 before it goes in the comment.

## 1. Resolve the target

The review scope is always one MR/PR. Determine it in this order:

1. **Full URL passed** — parse host, project path and number from it.
2. **`!42` / `#67` / bare `42` passed** — the number refers to the MR/PR in the
   origin remote of the current repo. `!` hints GitLab, `#` hints GitHub, but
   trust the remote over the sigil.
3. **Nothing passed** — infer from the current branch:
   - GitLab: `glab mr list --source-branch "$(git branch --show-current)"`
   - GitHub: `gh pr list --head "$(git branch --show-current)"`

   Fall back to `glab mr view` / `gh pr view` with no args, which resolve the MR
   for the current branch directly.

Pick the tool by inspecting `git remote get-url origin`: `gitlab*` → `glab`,
`github.com` → `gh`. For self-hosted GitLab, `glab` already honours the repo's
remote; pass `--repo <path>` when operating on a URL for a different project.

**Stop and ask** if resolution is ambiguous (several open MRs for the branch) or
finds nothing. Do not silently review the working tree instead — that is a
different scope than what this skill promises.

## 2. Gather context

Read all of these before forming an opinion:

- **Description and metadata** — `glab mr view <n>` / `gh pr view <n>`.
- **Related ticket(s)** — follow every ticket reference in the description,
  branch name or commit messages, via `glab issue view <n>` /
  `gh issue view <n>`, or by fetching the URL for a tracker outside the repo
  host. The ticket states what was *asked for*; the description
  states what the author *thinks they did*; the diff states what they *did*.
  Any gap between the three is a finding, and often the most valuable one.
- **Diff** — `glab mr diff <n>` / `gh pr diff <n>`.
- **Commit history** — `git log --reverse <base>..<head>` plus per-commit diffs.
  Reviewed as its own axis in step 3.
- **Existing discussion** — `glab mr note list <n>` (or `glab mr view <n> --comments`)
  / `gh pr view <n> --comments`. Never re-raise a point a reviewer already made,
  and never contradict a resolved decision without acknowledging it.
- **Repo instructions** — read `AGENTS.md` first, then `CLAUDE.md`, plus any
  nested ones under the touched directories. These define what "correct" means
  in this repo and override generic style opinions.
- **Surrounding code** — for any non-trivial hunk, open the full file, and find
  the callers of anything whose behaviour changed. A diff read in isolation
  produces confident, wrong review comments.

## 3. What to look for

### Correctness, edge cases, side effects

- Logic errors, off-by-one, inverted conditions, wrong operator precedence.
- Every edge case you can construct: empty input, nil/None, zero, negative,
  duplicate, overflow, unicode, concurrent arrival, retry after partial failure.
- Side effects the author may not have traced: every caller of a changed
  signature or changed behaviour, shared state, cache invalidation, ordering
  assumptions downstream, logs/metrics/alerts that silently change meaning.
- Error handling: swallowed errors, errors logged but not returned, missing
  wrapping/context, `panic`/bare `except` in library code.
- Concurrency: data races, unsynchronised shared state, missing `context`
  cancellation, goroutine/task leaks, deadlock-prone lock ordering.
- Resource leaks: unclosed files/connections/rows, missing `defer`, unbounded
  growth of caches or slices.
- Compatibility: signature or wire-format changes that break existing callers,
  migrations that are not backward compatible or not reversible.

### Could this be better?

Do not stop at "it works". For each meaningful hunk ask:

- Is there a shorter, more elegant formulation with the same behaviour?
- Does it cost performance it need not — an allocation in a hot loop, an N+1
  query, a linear scan where a map exists, work repeated per iteration that
  could be hoisted?
- **If it is a refactor: can it go further?** Half-finished refactors are worse
  than none — say where it stopped short.
- **If duplicate code is being hoisted: is more of it deduplicable?** Look for
  the third and fourth copy the author missed. Better still, can any of it be
  deleted outright rather than abstracted?
- Is there dead code, an unused parameter, a flag with one call site, an
  abstraction with one implementation?

### Tests

- Does the new behaviour have tests at all?
- **Mutate the code under test to prove the tests are meaningful.** Flip a
  condition, drop a call, change a constant, return early — then run the test
  and see if it fails. A test that stays green under mutation is evergreen and
  worthless; name it and say which mutation it survived.

  Do this in a scratch copy or `git stash`/`git checkout --` the mutation
  immediately after. **Never leave a mutation in the working tree, never commit
  one, and never push one.** Verify the tree is clean before you finish.
- Do the assertions check the thing that was actually fixed, or just that the
  code ran without throwing?

### Comments

- Flag excessive and unnecessary comments — restatements of the code below,
  obvious statements, commented-out code, stale comments describing an older
  version of the logic.
- Comments should explain "why", never "what".

### Commit history

Code history is documentation. Review it commit by commit:

- Atomic: one logical change each, individually green, easy to review alone.
- Purposeful: every commit carries significant change; no noise commits, no
  stray `fixup!`/`squash!`, no "address review comments" churn left unsquashed.
- Compact but meaningful: not one giant commit, not fifty trivial ones.
- Messages: Conventional Commits (`type(scope): subject`), subject ~50 cols,
  body hard-wrapped at 72 columns. Informative but not bloated. About **why**
  the change was made, not what changed — the diff already says what.
- Docs and tests land in the same commit as the code they describe.
- No vanity trailers.

### Repo conventions

Compliance with `AGENTS.md` / `CLAUDE.md`, and consistency with the code around
the change — naming, error style, layout, test structure. Match the file, not
your preference.

Out of scope unless the repo instructions ask for it: subjective style taste,
formatting a linter already enforces, and speculative "you might one day need"
architecture advice.

## 4. Verify before reporting

Adversarial in search, rigorous in reporting. Every finding must survive this,
or it does not go in the comment:

- Quote the exact line and re-read it in full file context.
- State a concrete failure: specific inputs or state → specific wrong result.
  If you cannot write that sentence, it is a hunch, not a finding.
- Confirm the code does not already handle it elsewhere (caller, wrapper,
  middleware, validation layer).
- For "could be better" claims, be concrete about what the better version is.
  "This could be cleaner" is noise; "these three branches are the same modulo
  the field name — take it as a parameter" is a finding.

Three findings you are sure of beat ten you are not. An empty review is a
legitimate outcome — say so plainly.

## 5. Compose the comment

### Finding IDs

Every finding gets an ID so it can be referenced in replies and follow-up
threads. The letter is the severity, the number runs per letter:

- **B**n — **blocking.** Must be fixed before merge: it is wrong, unsafe, or
  breaks something.
- **I**n — **issue.** Should be fixed, but the author decides whether now or
  in a follow-up: inelegance, avoidable cost, missing coverage, convention drift.
- **N**n — **nit.** Take it or leave it. If a review is all nits, say that.

Sections group by *topic*, IDs carry *severity* — so a blocking test defect is
`B3` sitting in the Tests section. Order findings within each section by
severity. Never renumber or reuse an ID across revisions of the same review;
when re-reviewing after a push, continue the sequence and state which earlier
IDs are now resolved.

### Template

```markdown
## Review

<One or two sentences: what the MR does, whether it matches the ticket, and the
overall verdict.>

### Correctness

- **B1** — `path/to/file.go:42` — <the defect in one sentence.>
  <Failure scenario: inputs → wrong outcome.> <Suggested fix, if short.>

### Quality

- **I1** — `path/to/file.py:17` — <what could be better, and concretely how.>
- **N1** — `path/to/file.py:88` — <nit.>

### Tests

- **B2** — <which mutation the test survived, and what that proves.>

### Commit history

- **I2** — `<sha>` — <atomicity or message problem.>

### Notes

- <Not defects, no ID: context, follow-up worth its own MR, things you checked
  and found fine that the author may wonder about.>

---
Reviewed with <harness> using <model id>.
```

Rules for the text:

- **Never use a hash sign to number or reference points** — `#1`, `#2` render as
  issue links on both GitLab and GitHub. This is exactly what the ID scheme is
  for: write "see B2", never "#2". The same applies when replying to someone
  else's numbered points.
- Drop any section that would be empty. If nothing is blocking, say so in the
  summary rather than shipping an empty heading.
- Link every finding to `file:line` from the diff so the reader can jump to it.
- Address the change, not the author. No praise padding, no apologies.
- Do not include the raw diff or long code dumps; quote at most a few lines.
- Close with the harness and exact model id (e.g. "Reviewed with Claude Code
  using claude-opus-5"), so readers can weigh the review's provenance.
  Attribution is **required** on reviews. The no-AI-signature rule applies to
  commit messages and MR descriptions, not here: authored artifacts stay
  unsigned, opinions about them get attributed.

## 6. Post it

Posting is the deliverable — a review that only exists in the terminal has not
been delivered. **Always post, without asking for confirmation.** The only
exception is an explicit prohibition from the user ("don't post", "show me
first", "dry run"); honour that and stop after printing.

1. Print the full comment body in the terminal.
2. Post via a file to preserve line breaks:

   ```bash
   glab mr note create <n> --message "$(cat /tmp/review.md)"
   # or
   gh pr comment <n> --body-file /tmp/review.md
   ```

3. Confirm the working tree is clean of any test mutations from step 3.
4. Report the resulting comment URL back to the user.

If the user prohibited posting, leave the review in the terminal and stop — do
not post a trimmed-down version instead.
