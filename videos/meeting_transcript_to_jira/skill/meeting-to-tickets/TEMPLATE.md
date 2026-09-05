# The intake gate and the ticket template

**This is the file you edit.** `SKILL.md` is the procedure; this file is the standard it applies. If
your tracker requires a field that is not here, add it below and the drafts change with it. If a
field here does not apply to your team, remove it.

Two parts. The gate decides whether a candidate is a ticket. The skeleton is what an `accept` gets
filled into.

> **Editing this for your own tracker.** Two places to edit, and they are not interchangeable. The
> six fields under "The description skeleton" are the prose a data ticket needs beyond a software
> task, so add there whatever you want written down and reasoned about. Structured fields your board
> validates — a required `Components` value, a `Priority` scheme, a custom field your admin added —
> go in the "Tracker fields" block near the bottom instead, because those are data rather than prose.
> The gate's five tests are tracker-independent and rarely need changing.

---

## The gate

Five tests. Run them in order and stop at the first failure — the order is what makes the outcome
correct, and it is why One-off is checked before Specification. A repeating item that is also
missing fields is `recurring`, not `clarify`, because specifying it better would not change the
fact that a one-off ticket is the wrong container. Checking Specification first would return
`clarify` and quietly file a standing job as a task.

1. **Named owner** — a specific person committed to doing the thing, in their own words. Not "we
   should," not "someone could," not "that would be useful."

   **When the source format carries no attribution.** AI-written meeting notes (Notion's, and most
   summarisers) record what was decided and drop who said it. You cannot evidence this test either
   way, and declining everything would be the wrong read of a real meeting. Treat the owner as a
   **missing field rather than a failed test**, which means this test does not fail and does not stop
   the run: carry the item on through tests 2 to 5 as normal. An unattributed item that is also a
   standing job still fails One-off first and is `recurring`, exactly as it would be with a named
   owner. Only if it reaches test 5 does it come out `clarify`, with the owner listed alongside
   whatever else is missing.

   Address the ownership question to whoever ran the meeting or shared the notes, since unattributed
   notes by definition cannot tell you who to ask and that person can. Say in your output that
   attribution was unavailable in the source, so the reader knows it is a format limit rather than a
   judgment about the meeting.
2. **Deliverable** — you can name the artifact that exists when it is done.
3. **Decision** — something changes based on the output. If nothing changes, it is a note.
4. **One-off** — it happens once. If it fires again on a trigger, it is a standing job.
5. **Specification** — everything the ticket needs to be created and worked is present or derivable
   from the transcript. Three groups, and a gap in any of them fails this test:
   - the six description fields: business question, decision it informs, grain, metric definition,
     timeframe, deadline;
   - **a resolvable owner** — a name, and one you can map to a real tracker account. An
     unattributed source fails here, which is where an item that skipped test 1 lands;
   - **every field your board actually requires**, from the Tracker fields block below. A required
     `Components` value you cannot supply is a missing field like any other.

| First test that fails | Outcome |
|---|---|
| Named owner, Deliverable, or Decision | `decline` |
| One-off | `recurring` |
| Specification | `clarify` |
| Nothing fails | `accept` |

One exception on `clarify`: when the requester is also the owner — you are filing your own work — there
is nobody to send a question to. The missing fields get answered before the ticket is created, in the
same sitting. It still fails the Specification test; it just resolves in place rather than becoming a
round trip. Do not create the ticket with the fields left blank on the grounds that you know what you
meant.

### Three rules that do most of the filtering

These are the ones a generous extractor gets wrong, and between them they account for most of what
should never reach the board.

**Appointments are not tickets.** A commitment to be somewhere at a time is a calendar entry, and the
invite is already the record of it. This is the most common false positive a transcript produces,
because agreeing to a meeting looks exactly like agreeing to do work — a named person commits, a time
is fixed, both sides confirm. The test that separates them: does anyone produce something between now
and then? If the only output is having attended, it belongs on the calendar.

**Constraints and context never become tickets.** A rule about how the work must be done is an
acceptance criterion on the tickets it constrains. A background fact someone stated for context is
description context, or nothing. Neither is its own ticket, and filing them that way is how a backlog
grows without any more work getting finished.

**External owner means not your ticket.** Someone else's commitment can be entirely real and still
have no place on your board. It goes in `Depends on`, where it is visible as a thing you are waiting
for rather than a thing you owe. Watch for these blocking an `accept` — an external dependency is the
most common reason a well-specified ticket sits untouched.

### Non-data work

The six fields are data-request fields. For work that is not a data pull, substitute:

| Field | Non-data equivalent |
|---|---|
| Business question | The need the work answers |
| Grain | The unit of the deliverable (one page per, one section per) |
| Metric definition | Definition of done |

Decision it informs, timeframe, and deadline carry over unchanged.

---

## The description skeleton

Paste this into the Jira description and fill it in. Every `accept` gets all of it; a field that
genuinely does not apply says so and says why, because a blank field and an inapplicable field read
identically six weeks later.

````markdown
- **Business question**
  - <what is actually being asked>
- **Decision it informs**
  - <what changes based on the answer>
- **Grain**
  - <one row per what>
- **Metric definition**
  - <how the measure is calculated, and whose definition it is>
- **Timeframe**
  - <the period covered>
- **Deadline**
  - <when it is needed>

---

- **Owner**
  - <the named owner from the gate>
- **Depends on**
  - <external commitments this waits on, and who owns them>
- **Source**
  - <transcript file + the quoted line that prompted this>

### Acceptance criteria

- <criterion>
  - <the quoted line or detail it rests on, when it needs one>
- <criterion>

### Decided not to include

- <thing>
  - <why>
````

**Write it as Markdown, and let the tracker render it.** The block above is Markdown on purpose:
Jira converts it on the way in, so `**bold**` becomes bold, `###` becomes a heading, and the
indented bullets become genuinely nested lists rather than indented text. Verified against Jira
Cloud on 2026-09-05. Linear, GitHub and Notion render the same source, and a tracker that renders
nothing still shows readable text — which a space-aligned block does not, because padding set for a
monospace column goes ragged the moment it hits a proportional font.

**Label on the bullet, value on the sub-bullet.** Two reasons. A field whose value runs to two or
three sentences stays readable, where the same text squeezed into a table cell does not. And a field
nobody filled shows up as a label with nothing under it, which is visible in a way a blank line is
not — spotting the field the meeting never filled is most of the value here.

Indent sub-bullets by two spaces. The `---` between the fields and the provenance block is load
bearing: without it Markdown reads all nine as one list, because a blank line does not start a new
one.


Two of these fields carry more weight than their size suggests.

**Source** is what makes the ticket auditable. A transcript is untrusted input — speech-to-text
fabricates sentences, and the README covers the measured error rate — so quoting the line that
prompted the ticket is what lets the next reader verify it against the record instead of trusting it.
A ticket that cannot be traced back to something a person actually said is a ticket that should not
have been filed.

**Decided not to include** is the field people skip and then regret. Scope you consciously rejected
looks identical to scope you never considered, right up until someone asks about it. Writing down the
rejection and the reason is what turns "we did not think of that" into "we decided against that, for
this reason."

---

## Tracker fields

The skeleton above is the ticket's **description**: the prose substance, and the biggest part of what
makes a ticket workable. This section is the other half of customising this file, and it is a
different mechanism.

Your tracker validates **structured fields** at creation time: project, issue type, Components,
priority, assignee, and whatever custom fields your admin added years ago. Those are data, not prose.
A `Components` line typed into a description is text that looks like a field and satisfies nothing,
so Jira will reject the create.

So say what you want set, here, as fields rather than as description prose. Everything above this
section goes in the description; everything in this block is a field.

**This is a specification, not a mechanism.** This skill drafts and stops, so nothing here writes
itself. The block exists so that when you or your tracker integration create the ticket, the field
values are already decided and written down instead of being invented at the keyboard. If your
integration can read it, good. If you are creating the ticket by hand, this is the list you fill in
from.

```
Project:        <key, e.g. DATA>
Issue type:     Task
Components:     <required on many boards — set it or creation fails>
Priority:       <your board's scheme, if it enforces one>
Assignee:       <the named owner from the gate, resolved to a tracker account>
Labels:         from-meeting-transcript
<custom field>: <value, or "ask" to make it a clarify question>
```

Three things worth knowing before your first real run:

- **Leave a field out and the create can still fail.** If your board marks something required, it is
  required whether or not this block mentions it. Adding it here is how you fix that.
- **A field you cannot fill is a `clarify`, not a guess.** This is enforced by the gate rather than
  left to good intentions: test 5 covers the fields in this block, so an unsupplied required value
  fails Specification and routes the item to `clarify`. Assignee is the common one, because the gate
  can find a name in the transcript that still does not resolve to a tracker account. Ask rather than
  assigning it to yourself.
- **This block is instructions to the writer, not part of the ticket.** It never appears in the
  description.
