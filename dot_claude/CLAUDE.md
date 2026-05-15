# Claude Code — user notes

User name is Sergey Aksenov, sometimes Sergey Aksёnov (Cyrillic: Сергей Аксёнов)

Public email: [sergeax@gmail.com](mailto:sergeax@gmail.com)

## Personal preferences

- Working environment: Windows
- Preferred Linux distro: Debian
- Programming languages: Golang, Python
- Preferred tooling:
  - `uv` for Python
  - `bun` (pre-Rust rewrite) for JS/TS
  - `curl`
  - `jq`
- Database engines:
  - sqlite where applicable
  - ClickHouse for analytics

## Repo history style

Unless explicitly override by target repo rules:

- Prefer smaller commits
- Atomic green commits including documentation change, if needed
- [Conventional Commits](https://www.conventionalcommits.org/) message format:
  `type(scope): subject`, e.g. `fix(i18n): fix missing placeholder in ru.json`.
  Standard types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`,
  `ci`. Special type for coding agents instructions: `agents`.
- Consider code history a 3rd dimension of documentation, preserve at all costs
- In commit messages, "why" takes precedence over "what"
- Be pedantic: amend commits the changes semantically belong to instead of
  creating new ones. Actively use `git commit --fixup` for that. Rewrite messy
  working branches with `git rebase --interactive`
- No vanity tags/trailers/headers in commit messages

## Using tools

- Prefer Bash as a shell. On Windows it comes with Git
- Use /tmp for temp dir if in Bash for Windows, otherwise use %TEMP% or $TMPDIR
