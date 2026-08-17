---
name: meeting-to-tickets
description: >-
  Turn a meeting transcript into scoped tickets against a ticket template. Use when the user points
  at a transcript file and wants tickets, or says "turn this meeting into tickets", "read the
  transcript and draft tickets", "what did we commit to in this meeting". Reads any plain-text
  transcript from any meeting tool, applies the intake gate in TEMPLATE.md, drafts the survivors
  against the field list, and STOPS before writing anything to a tracker.
---

# Meeting transcript to scoped tickets

Read a meeting transcript, decide what actually deserves to be a ticket, and draft the survivors
against a template so every ticket comes out the same shape.

The judgment lives in `TEMPLATE.md`, not in this file. That is deliberate: `TEMPLATE.md` is the part
you edit to match what your own tracker requires. This file is the procedure that runs it.

## Input

A path to a plain-text file. That is the whole interface.

It does not matter which meeting tool produced it. A Zoom `.TXT` with speaker labels and timestamps,
a Notion AI Meeting Notes export in Markdown, a Teams or Meet `.vtt`, or someone pasting text into a
file all work. Do not parse for a specific tool's format, and do not fail when speaker labels are
absent.

**Format degradation is expected and should be reported, never hidden.** A Notion export loses
speaker turns, which makes the Named owner test harder. When the input format costs you confidence on
a test, say so in the output rather than guessing.

## Procedure

Run these in order. Do not skip to drafting.

### 1. Read the transcript and list every candidate

Every item that sounds like work, including the ones you expect to reject. A candidate is anything a
reader might plausibly turn into a ticket. Listing the rejects is not busywork: showing what was
considered and dropped is what makes the pass reviewable.

### 2. Run each candidate through the gate in TEMPLATE.md

Five tests, in order, stopping at the first failure. The order is what makes the outcome correct.
Read `TEMPLATE.md` and apply it as written.

Every candidate resolves to exactly one of `accept`, `clarify`, `decline`, or `recurring`.

Be strict. Most of what gets said in a meeting is not a task. A pass that accepts most of its
candidates is miscalibrated. If nearly everything survives, re-read the Named owner test and apply it
again: "we should", "someone could" and "it would be nice if" are not commitments.

### 3. Present the candidate table

One row per candidate. Columns: Item, Who committed, Outcome, Missing fields, Reason.

For every `decline` and `recurring`, the Reason must name which test failed. "Not a commitment" is
not a reason; "no named owner, the phrasing was 'somebody should look at'" is.

### 4. Draft the `accept` and `clarify` items

- **`accept`** items get drafted into the description skeleton in `TEMPLATE.md`, every field filled.
- **`clarify`** items get a short message back to the requester asking only for the fields that are
  actually missing, quoting the transcript line that prompted it so they have context.

**Never invent a value for a missing field.** Grain and metric definition are almost never spoken
aloud in a meeting, so they will frequently be missing. That is not a prompting failure to work
around. The honest output is a question. A ticket that looks finished and is not costs the requester
a week; a specific question costs them an afternoon.

### 5. Stop

Show everything and wait. Do not create, update, or transition anything in a tracker until a human
has read the drafts and said go.

This is not politeness. A transcript is a record of what a piece of software thought it heard,
speech-to-text does fabricate sentences around pauses and crosstalk, and a fabricated line becoming a
ticket with a real person's name on it is a failure worth fifteen seconds of review to avoid.

## Writing to a tracker

Once a human approves, write the accepted tickets.

This skill does not talk to any tracker itself, on purpose. It decides *what* is worth writing; a
tracker integration decides *how* it gets written. Pair it with whatever your team uses:

- **Jira** — Atlassian's official Claude Code plugin
  (`claude plugin install atlassian@claude-plugins-official`) handles the connection and resolves
  assignees to account IDs.
- **Anything else** — use that tracker's own integration. The gate and the field list are not
  specific to Jira; only the write step is.

If a required field on your tracker is not in `TEMPLATE.md`, add it there rather than working around
it here.

## Adapting this

`TEMPLATE.md` is meant to be edited. Every organization asks for different things: a required
Components field, custom fields an admin added years ago, a different definition of done. Change the
field list to match what your tracker actually requires, and the drafts change with it.

The six default fields are data-request fields. `TEMPLATE.md` carries substitutions for work that is
not a data pull.
