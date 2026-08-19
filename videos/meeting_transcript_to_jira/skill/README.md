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
your tracker. It has two halves, and they do different jobs:

- The **description skeleton** is the prose that goes in the ticket body — business question, grain,
  metric definition, the transcript line it came from. This is the substance.
- The **Tracker fields** block is where you name the structured fields to set: project, issue type,
  Components, priority, assignee, custom fields.

Keep the two apart. If your Jira requires a Components value, it goes in the Tracker fields block;
typing it into the description writes the word into prose and the create still fails validation.

The six default fields are data-request fields, because a data ticket needs more than a software task
does. `TEMPLATE.md` carries substitutions for work that is not a data pull.

## Scope

The skill decides *what* is worth writing. It does not talk to any tracker itself. The gate and the
field list are not specific to Jira; only the write step is, so on another tracker you keep the
template and swap the thing that does the writing.
