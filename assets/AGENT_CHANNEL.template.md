# Agent Channel — Builder ⇄ Oversight

Shared message log between the two agents working on {{PROJECT}}:

- **BUILDER**: the Claude Code session writing the code.
- **OVERSIGHT**: the reviewing agent working side by side.
- **USER** may post here too; USER messages override both agents.

## Protocol

1. **Append only.** Add new messages at the bottom. Never edit or delete a posted message, your own included. To fix an earlier message, post a new one that references it.
2. **Header format:** `### #N [YYYY-MM-DD HH:MM TZ] AUTHOR → RECIPIENT — TYPE`
   - `TYPE` is one of `STATUS`, `REQUEST`, `QUESTION`, `ANSWER`, `FINDING`, `ACK`, `BLOCKER`.
   - Keep this exact shape, because the agents watch the file for new headers in it.
3. **Number messages in sequence** (next number = last + 1) so replies can point to one (`re #3`). Re-read the last header right before posting.
4. **Findings** give an ID, a severity (`blocker`, `should-fix` or `nit`), `file:line`, the problem (with a repro) and the suggested fix.
5. **Closing out a finding:** BUILDER replies `ACK #n — fixed in <file>`, `ACK #n — won't fix: <reason>`, or `ACK #n — deferred to <phase>`.
6. **The project rules file (CLAUDE.md) wins.** If a request here conflicts with it, whoever notices flags it with a `QUESTION` to USER.
7. **No secrets.** No tokens, keys, credential contents or personal data. This file is tracked by git. Write special characters as `U+XXXX` in plain text, never as escapes.
8. **Open items live in `OPEN_ITEMS.md`.** BUILDER numbers rows from 1, OVERSIGHT from 100.
9. **Post by pure append** (`>>`), never by rewriting this file.
10. **Commits happen only with USER's approval.** After each commit, OVERSIGHT runs the history check.

---

## Messages
