# Agent Channel

A [Claude Code](https://claude.com/claude-code) skill for running **two Claude sessions on one repo**: a **BUILDER** that writes the code and an **OVERSIGHT** agent that reviews designs, code and commits, and checks the builder's claims itself instead of trusting its summaries.

The two agents talk through a plain file in the repo:

- **`AGENT_CHANNEL.md`**: an append-only, numbered message log (`STATUS`, `REQUEST`, `QUESTION`, `ANSWER`, `FINDING`, `ACK`, `BLOCKER`).
- **`OPEN_ITEMS.md`**: a small table of anything that outlives one message, such as findings, deferred work and decisions waiting on you.

You (**USER**) can post in the channel too, and your word overrides both agents. Each agent watches the file in the background and reacts when the other one posts, so you don't have to relay messages between terminals.

## The loop

```
BUILDER  QUESTION (design)  ─►  OVERSIGHT reviews, pushes back or GO
BUILDER  builds + tests      ─►  STATUS with evidence
OVERSIGHT verifies itself     ─►  FINDING(s) with severity  or  ACK/approval
BUILDER  ACK #n — fixed/won't fix/deferred
USER approves commit          ─►  BUILDER commits, REQUESTs history check
OVERSIGHT history check       ─►  ACK clean (or BLOCKER)
Live test with USER           ─►  evidence posted  ─►  milestone closed
```

Commits only happen with your approval. An agent's GO doesn't count as yours.

## Requirements

- macOS or Linux
- [Claude Code](https://claude.com/claude-code)
- `bash`, `git` and `python3` (the history check uses Python for its hidden-character scan)

## Install

The skill's instructions call its scripts at `~/.claude/skills/agent-channel/`, so clone it there:

```bash
git clone https://github.com/pranabrbusireddy/Agent-channel.git ~/.claude/skills/agent-channel
```

Start a new Claude Code session and `agent-channel` appears in the skills list. To update later, run `git -C ~/.claude/skills/agent-channel pull`.

## Use

Open two Claude Code sessions in the same repo and give each one its role:

```
Session 1:  you are the builder. Work with the oversight agent through the agent channel.
Session 2:  you are the oversight agent. Review the builder's work through the agent channel.
```

If the repo has no channel yet, the first agent creates `AGENT_CHANNEL.md` and `OPEN_ITEMS.md` from the templates in `assets/` and posts message #1. After that, any session started in a repo containing `AGENT_CHANNEL.md` picks the skill up and catches up on unanswered messages first.

To post as yourself, append a message using the same header shape, or just tell either agent what you want. They relay your words into the channel as "USER told me directly:".

## What's inside

| Path | Purpose |
| --- | --- |
| `SKILL.md` | The protocol both agents follow: orienting, posting, roles, open items, watching, boundaries |
| `references/builder.md` | BUILDER duties: design-first, milestone discipline, evidence, commits only with approval |
| `references/oversight.md` | OVERSIGHT duties: design and code review, findings with severity, GO gates, history check |
| `scripts/post.sh` | Appends a message with the next number and a timestamp, under a lock so simultaneous posts don't collide |
| `scripts/watch.sh` | Streams new headers addressed to a role (or from USER), for Claude Code's Monitor tool |
| `scripts/history_check.sh` | Post-commit scan of every revision for secret files, secret values, build output, personal data and hidden/bidi characters |
| `assets/*.template.md` | Starting `AGENT_CHANNEL.md` and `OPEN_ITEMS.md` for a new repo |

## Notes

- `AGENT_CHANNEL.md` is tracked by git, so **never put secrets or personal data in it**. The protocol forbids it, and `history_check.sh` is there to catch slips.
- Both agents can write at the same moment. That's why posting is a pure append (`>>`) with a lock, never a read-modify-write.
- Your project's `CLAUDE.md` wins over anything said in the channel.

## Licence

MIT (see `LICENSE`).
