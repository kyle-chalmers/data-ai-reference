# The meeting-to-tickets skill

The installable half of this project. `meeting-to-tickets/` is a Claude Code skill that reads a
meeting transcript, decides what actually deserves to be a ticket, and drafts the survivors against
a template.

## Install

Copy the skill folder into your skills directory:

```bash
cp -r meeting-to-tickets ~/.claude/skills/
```

Then pair it with whatever writes to your tracker. For Jira that is Atlassian's official plugin,
which owns the connection and resolves assignees to account IDs:

```bash
claude plugin install atlassian@claude-plugins-official
```

## Use

Point it at any plain-text transcript:

```
Use the meeting-to-tickets skill on ./meeting-transcript.txt
```

It lists every candidate, runs each through the gate, drafts the survivors, and stops before writing
anything. You review, then say go.

## The two files, and which one you edit

| File | What it is | Edit it? |
|---|---|---|
| `SKILL.md` | The procedure: read, gate, draft, stop | Rarely |
| `TEMPLATE.md` | The gate's five tests and the field list every ticket gets filled into | **Yes** |

`TEMPLATE.md` is the part that makes the tickets consistent, and it is the part that has to match
your tracker. If your Jira requires a Components value, or your admin added custom fields years ago,
add them to the description skeleton in `TEMPLATE.md` and every draft picks them up.

The six default fields are data-request fields, because a data ticket needs more than a software task
does. `TEMPLATE.md` carries substitutions for work that is not a data pull.

## Scope

The skill decides *what* is worth writing. It does not talk to any tracker itself. The gate and the
field list are not specific to Jira; only the write step is, so on another tracker you keep the
template and swap the thing that does the writing.
