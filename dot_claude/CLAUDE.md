# Claude Code — user notes

User name is Sergey Aksenov, sometimes Sergey Aksёnov (Cyrillic: Сергей Аксёнов)

Public email: [sergeax@gmail.com](mailto:sergeax@gmail.com)

## Personal preferences

- Working environment: Windows
- Preferred Linux distro: Debian
- Programming languages: Golang, Python
- Preferred tooling:
  - `uv` for Python
  - `bun` (pre-Rust rewrite, <=1.3.14) for JS/TS
  - `curl`
  - `jq`
- Database engines:
  - sqlite where applicable
  - ClickHouse for analytics

## Be compatible, adhere open standards

- **Always** fully read and obey `AGENTS.md`, even if there's a dedicated
  `CLAUDE.md` nearby.
- Prioritize user's directives over harness' defaults

## Repo history style

Unless explicitly override by target repo rules:

- Prefer smaller commits
- Atomic green commits including documentation change, if needed
- [Conventional Commits](https://www.conventionalcommits.org/) message format:
  `type(scope): subject`, e.g. `fix(i18n): fix missing placeholder in ru.json`.
  Standard types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`,
  `ci`. Special type for coding agents instructions: `agents`.
- Wrap the commit message body at 72 columns — it is hard-wrapped prose,
  not one long line (keep the subject concise, ~50 cols). `git commit -m`
  does NOT wrap text, so insert the line breaks yourself, or pass the
  body via a file or heredoc (`git commit -F -`).
- Consider code history a 3rd dimension of documentation, preserve at all costs
- In commit messages, "why" takes precedence over "what"
- Be pedantic: amend commits the changes semantically belong to instead of
  creating new ones. Actively use `git commit --fixup` for that. Rewrite messy
  working branches with `git rebase --interactive`
- Do not leave fuxup commit to hang, autosquash it immediately
- No vanity tags/trailers/headers in commit messages

## Commenting

- Inline comment only when necessary. Most of the time good code is
  self-documenting
- No obvious statements or re-statements
- Never comment on "what", only "why"

## Using tools

- Prefer Bash as a shell. On Windows it comes with Git
- Use /tmp for temp dir if in Bash for Windows, otherwise use %TEMP% or $TMPDIR
- On Windows you may use WSL shell to run Windows-incompatible commands and
  scripts. Note that `C:` drive may be mounted as `/c/`, not `/mnt/c/`
- Use `gh` and `glab` to access repositories, issues, pull/merge requests,
  commentaries, CI pipeline logs etc. Prefer specific CLI commands instead
  of generic calls like `glab api "..."`
- Use `rg` instead of internal Find tool
