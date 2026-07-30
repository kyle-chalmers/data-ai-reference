# 1 — Extract candidates and judge them

Run this first. It does not write anything to Jira.

```
Read ./meeting-transcript.txt. Do NOT create anything in Jira yet.

Produce a markdown table of every candidate item with these exact columns:
Item, Who committed, Commitment or Idea, Outcome, Missing fields, Reason.

Outcome must be one of: accept, clarify, decline, recurring.

Judge "Commitment or Idea" by whether a specific named person actually committed to
doing the thing. Someone raising a possibility, wishing out loud, or noting that
another team may have solved it already is an Idea, not a Commitment.

For any item you mark accept or clarify, list which of these are missing:
business question, grain, metric definition, timeframe, deadline.

Also note any item that blocks another item.

Be strict. Most items in a meeting are not tickets.
```

**Expected:** a table covering every candidate, with most marked `decline` or `clarify` and only
a small number marked `accept`. At least one item should be flagged as blocking another.

**If it is too generous** and accepts nearly everything: paste the strictness line back and ask it
to justify each `accept` against the commitment test, naming who committed and in which line.
