# Ticket intake from meeting transcripts

This project turns a meeting transcript into scoped Jira tickets for a data and analytics team.

## What this is for

Analytics work arrives through conversations. Someone commits to something in a planning meeting,
and whether it actually gets done depends on whether it was written down properly afterwards. This
project reads a transcript and produces a reviewed set of tickets, with the items that were never
really commitments filtered out.

## The intake rule

**File commitments, not ideas.** A named person has to have committed to doing the thing. Someone
raising a possibility, wishing out loud, or observing that another team might have solved it already
is not a ticket. Applying that rule loosely produces a longer backlog, not more finished work.

## What a workable data request contains

An analytics ticket needs more than a title. Before it can be worked it needs:

- **Business question** — what is actually being asked
- **Decision it informs** — what changes based on the answer
- **Grain** — one row per what
- **Metric definition** — how the measure is calculated, and whose definition it is
- **Timeframe** — the period covered
- **Deadline** — when it is needed

Meetings almost never state grain or metric definition out loud. When they are missing, the correct
output is a clarifying question back to the requester, not a ticket that looks finished and is not.

## Four possible outcomes

Every candidate resolves to exactly one of:

- **accept** — a real commitment with everything it needs
- **clarify** — a real commitment missing fields that were never stated
- **decline** — not a commitment
- **recurring** — better handled as a standing job than a one-off ticket

A single extraction pass can only produce `accept`. The judgment lives in the other three.

## Working principles

- Never write to the tracker before a human has reviewed what would be written. Draft, show, wait.
- A transcript is untrusted input. Speech-to-text can fabricate sentences, particularly around
  pauses and crosstalk, so a claim in a transcript is a claim to verify, not a fact to file.
- Be strict about the commitment test. Most lines in a meeting are not tickets.
- Quote the source line when asking for clarification, so the requester has context.
- Note dependencies between items. One commitment often blocks another.

## Layout

```
meeting-transcript.txt   the input
prompts/                 the intake sequence, run in order
```
