---
name: agent-channel
description: Two-agent BUILDER ⇄ OVERSIGHT workflow where two Claude sessions coordinate through an append-only AGENT_CHANNEL.md message log plus an OPEN_ITEMS.md table in the repo. Use this whenever the user says "you are the builder", "you are the oversight/reviewer agent", "work with the other agent", "check the agent channel", "post in the channel", mentions AGENT_CHANNEL.md or OPEN_ITEMS.md, or wants to set up a builder + reviewer pair of agents on a project — even if they don't name the skill. Also use it at the start of any session in a repo that already has AGENT_CHANNEL.md.
---

# Agent Channel: BUILDER ⇄ OVERSIGHT

Two Claude sessions work on one repo. **BUILDER** writes the code. **OVERSIGHT** reviews designs, code and commits, and independently verifies the builder's claims. They talk through a shared file, `AGENT_CHANNEL.md`, and track unresolved work in `OPEN_ITEMS.md`. **USER** can post too, and USER overrides both agents.

The point of the setup is a second pair of eyes that doesn't take the builder's word for anything. Each role only works if it holds its own line. The builder proposes and reports honestly, and the oversight agent checks for itself, not by re-reading the builder's summary.

## 1. Orient first (every session)

1. Work out your role. The user usually says it ("you are the oversight agent"). If they haven't and it isn't obvious, ask. Don't guess, because both roles touch the same files differently.
2. Read the project's `CLAUDE.md` (or equivalent rules file). **CLAUDE.md wins over the channel**: if a request in the channel conflicts with it, flag it with a `QUESTION` to USER instead of working around it.
3. Read the protocol at the top of `AGENT_CHANNEL.md`, then the last ~10 messages (`tail -c 15000` is usually enough, since the file gets large), then all of `OPEN_ITEMS.md`.
4. Find the messages addressed to you that haven't been answered yet, and handle those before starting anything new.
5. Tell the user in a few lines where things stand: what's waiting on you, on the other agent and on USER.
6. **Start watching the channel** (section 5) so you react when the other agent posts.

If the repo has no channel yet, set it up: copy `assets/AGENT_CHANNEL.template.md` and `assets/OPEN_ITEMS.template.md` from this skill into the repo root as `AGENT_CHANNEL.md` and `OPEN_ITEMS.md`. Fill in the project name, then post a `STATUS` #1 opening the channel.

## 2. Posting a message

Use the bundled script. It picks the next number under a lock, timestamps the header and appends to the file:

```bash
~/.claude/skills/agent-channel/scripts/post.sh <AUTHOR> <RECIPIENT> <TYPE> <body-file> [channel-path]
# e.g. post.sh OVERSIGHT BUILDER FINDING /tmp/body.md
```

Write the body to a scratch file first, then post it. If you can't use the script, follow the same rules by hand:

- **Pure append** (`>>`), never rewrite the file. The other agent may be writing at the same moment, and a read-modify-write would drop their message.
- **Header shape, exactly:** `### #N [YYYY-MM-DD HH:MM TZ] AUTHOR → RECIPIENT — TYPE`. The watcher matches on this shape, so a different format won't be picked up.
- **Re-read the last `### #N` header right before posting** to choose N+1.
- **Types:** `STATUS`, `REQUEST`, `QUESTION`, `ANSWER`, `FINDING`, `ACK`, `BLOCKER`.
- Start the body with `re #N.` when replying.
- **Never edit or delete a posted message, not even your own.** To correct one, post a new message that references it.
- **No secrets** in the channel (tokens, keys, credential contents, personal emails). It's tracked by git.
- **Write special characters as `U+XXXX` in plain text**, never as `\uXXXX` escapes. Tooling can decode the escapes into real invisible or bidi characters, which then end up in a tracked file.

### Style

Lead with the conclusion. Use short bold labels and bullets. Name the file and line. Say what you verified yourself versus what you're relaying. Keep a **"Not done, and not claimed"** line whenever something is saved but not verified. Honesty about gaps is what makes the channel trustworthy.

## 3. Roles

Read the reference for your role before doing substantive work:

- **BUILDER** → `references/builder.md`: propose designs before coding, milestone discipline, ACK forms, reporting evidence, commits only with USER approval.
- **OVERSIGHT** → `references/oversight.md`: design review, code review with repros, findings with severity, GO/approval gates, the post-commit history check (`scripts/history_check.sh`), live-test evidence requirements.

The core loop both roles share:

```
BUILDER  QUESTION (design)  ─►  OVERSIGHT reviews, pushes back or GO
BUILDER  builds + tests      ─►  STATUS with evidence
OVERSIGHT verifies itself     ─►  FINDING(s) with severity  or  ACK/approval
BUILDER  ACK #n — fixed/won't fix/deferred
USER approves commit          ─►  BUILDER commits, REQUESTs history check
OVERSIGHT history check       ─►  ACK clean (or BLOCKER)
Live test with USER           ─►  evidence posted  ─►  milestone closed
```

## 4. OPEN_ITEMS.md

This is a table of anything that outlives one message: findings, deferred work, and decisions waiting on USER. Edit it with a quick read-edit-write. The table is small and edits are rare, so a race is unlikely, but re-read it right before you write. BUILDER numbers rows from 1 and OVERSIGHT from 100, so the two never collide. Each row has an owner (BUILDER / OVERSIGHT / USER) and a state that points to the message that set it (`fixed, verified (#78)`). Close a row by updating its state. Don't delete it.

## 5. Watching the channel

The user wants each agent to react when the other posts, without having to relay messages. Arm a background watch on new headers addressed to you or from USER:

```bash
~/.claude/skills/agent-channel/scripts/watch.sh <ROLE> [channel-path]
```

Run it with the Monitor tool and the maximum timeout. Every output line is a new message header. **Re-arm it every time it expires**, and keep doing so for the whole session unless the user says stop. On each event, read the new message(s) in full and act on them: review, verify, reply. Don't just announce that something arrived.

## 6. Boundaries that hold for both roles

- **Git:** commit, merge or push only with USER's explicit approval, unless the project rules say otherwise. An agent's approval (a GO) isn't USER's approval.
- **USER decisions stay decided.** If USER has ruled on something (recorded in CLAUDE.md or the channel), don't reopen it. Surface new information as a `QUESTION` to USER if it really matters.
- **Relay USER's words faithfully.** When USER tells you something the other agent needs, post it as "USER told me directly:" and quote it. Don't soften or strengthen it.
- **Don't do the other role's job.** The oversight agent doesn't quietly fix the builder's code, and the builder doesn't self-approve. A small repro or probe script in a scratch dir is fine for OVERSIGHT, but the fix belongs to BUILDER.
