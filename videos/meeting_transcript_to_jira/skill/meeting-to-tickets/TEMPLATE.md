# The intake gate and the ticket template

**This is the file you edit.** `SKILL.md` is the procedure; this file is the standard it applies. If
your tracker requires a field that is not here, add it below and the drafts change with it. If a
field here does not apply to your team, remove it.

Two parts. The gate decides whether a candidate is a ticket. The skeleton is what an `accept` gets
filled into.

> **Editing this for your own tracker.** The six fields under "The description skeleton" are
> data-request fields, chosen because a data ticket needs more than a software task does. Common
> additions: a required `Components` value, a `Priority` scheme your board enforces, a custom field
> your admin added. Add them to the skeleton and they get filled on every draft. The gate's five
> tests are tracker-independent and rarely need changing.

---

## The gate

Five tests. Run them in order and stop at the first failure — the order is what makes the outcome
correct. A repeating item that is also missing fields is `recurring`, not `clarify`, because
specifying it better would not change the fact that a one-off ticket is the wrong container.

1. **Named owner** — a specific person committed to doing the thing, in their own words. Not "we
   should," not "someone could," not "that would be useful."
2. **Deliverable** — you can name the artifact that exists when it is done.
3. **Decision** — something changes based on the output. If nothing changes, it is a note.
4. **Specification** — business question, decision it informs, grain, metric definition, timeframe,
   and deadline are all present or derivable from the transcript.
5. **One-off** — it happens once. If it fires again on a trigger, it is a standing job.

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

```
Business question:
Decision it informs:
Grain:
Metric definition:
Timeframe:
Deadline:

Owner:
Depends on:            [external commitments this waits on, and who owns them]
Source:                [transcript file + the quoted line that prompted this]

Acceptance criteria
-
-

Decided not to include
- <thing>  —  <why>
```

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
