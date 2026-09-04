# Meeting script — read this in Zoom to produce a real transcript

Two participants. Both are you, joined from two devices, so Zoom produces genuine speaker labels
without needing anyone else's time.

## Before you start

1. **Join twice.** Laptop and phone (or laptop and tablet) in the same meeting. Mute the second
   device's speaker and use headphones on both, or you will get feedback.
2. **Set the display names before joining** — Zoom labels the transcript by participant display
   name, not by voice. Device one: `Ada Lovelace`. Device two: `Grace Hopper`.
3. **Turn on transcription.** Admin Center → Settings → Meeting → In Meeting (Advanced) →
   Meeting transcript. It is **off by default**. Then in the meeting, Save transcript writes a
   `.TXT` to `~/Documents/Zoom`.
4. Speak from whichever device is "talking". Zoom attributes by active microphone, so only unmute
   the one currently speaking.

## Why two speakers matters

The gate prompt has a `Who committed` column, and Atlassian's skill resolves assignees to account
IDs. A single-speaker transcript collapses both. Two labeled participants is the minimum for the
demo to work.

## What the script is engineered to contain

Nine things that sound like work. Four are genuine commitments, five are not. Do not tidy this up
while reading — the hedging and the tangents are the point.

Outcomes below are the **measured** result of running the gate on 2026-09-04 (1 accept, 3 clarify,
4 decline; items 6 and 7 merge, so 8 candidates rather than 9). An earlier version of this table
predicted 3 accepts and was wrong.

| # | Item | Who | Resolves to |
|---|---|---|---|
| 1 | Fix the silent dashboard refresh | Ada | accept |
| 2 | Churn by region for the QBR | Grace | **clarify** — churn undefined, region taxonomy uncertain |
| 3 | Document the revenue metric definition | Ada | **clarify** — which revenue measure, and who signs off |
| 4 | **Check whether reseller is in the Europe rollup** | Grace | **clarify** — **this is the miss**, and it blocks #2 |
| 5 | Finance might already have a churn number | — | decline, observation |
| 6 | Does anyone still read the weekly deck | — | decline, no owner |
| 7 | Put it in Slack instead | — | decline, wish, explicitly parked |
| 8 | Filter out the test accounts | — | decline, musing, "not urgent" |
| 9 | Move off the BI tool next year | — | decline, no decision |

Item 4 is the one the cold open depends on. It arrives as an afterthought near the end. Deliver it
casually and slightly rushed, the way a real "oh, before I forget" sounds.

---

## The script

**Ada:** Okay, I think that's everyone. Let's start with the dashboard.

**Grace:** Yeah, the exec dashboard broke again on Tuesday. The refresh failed and nobody noticed
until Sanjay pinged me Wednesday afternoon asking why the numbers were two days stale.

**Ada:** Failed as in no alert fired?

**Grace:** No alert. The job status said succeeded, because the extract technically completed. It
just pulled zero rows.

**Ada:** That's the second time this month.

**Grace:** Third, if you count the one in the first week.

**Ada:** Alright, I'll fix the refresh and put a row-count check on it, so it actually fails loudly
when it pulls nothing. End of week, it's not a big change.

**Grace:** Good.

**Ada:** Next thing. The QBR is in three weeks and Sanjay wants churn broken out by region this
time.

**Grace:** By region meaning the sales regions, or the billing regions? Because those don't line up.

**Ada:** I think sales regions. That's what the rest of the deck uses.

**Grace:** Okay. I can pull that. It's going to take me a bit, we've never cut churn that way
before. But yeah, I'll get the churn by region numbers together for the QBR.

**Ada:** You've got three weeks.

**Grace:** Are we defining churn the same way finance does? Because I think they have a version of
this. They showed a churn slide last quarter.

**Ada:** Might be worth looking at.

**Grace:** Yeah, maybe.

**Ada:** Okay. The weekly deck. Honestly, somebody should look at whether we even need it anymore.
I don't think anyone reads it.

**Grace:** I've wondered the same thing. It'd be nice to have this stuff in Slack instead of a deck
nobody opens.

**Ada:** Maybe. Let's park that, we don't have time to redesign reporting right now.

**Grace:** One more on data quality. We've still got all those test accounts in the customer table
showing up in the counts. A few hundred? They all have the internal email domain, so they're easy
to spot.

**Ada:** We could probably just filter those out.

**Grace:** Probably. Not urgent though.

**Ada:** The other thing is the revenue metric. Every team has a slightly different number and I
keep getting asked which one is right. Let me just write down the definition we're actually using,
so we have one place to point people. I'll put it in Confluence.

**Grace:** Perfect, that'd help.

**Grace:** Oh, before I forget. The Europe numbers.

**Ada:** What about them?

**Grace:** I'm not sure whether the Europe rollup includes the reseller channel or not. If it does,
the regional churn cut is going to look wrong and Sanjay will catch it.

**Ada:** That would be bad in front of the board.

**Grace:** Yeah. I'll check whether reseller is in the Europe rollup before I build the churn cut.
Shouldn't take long.

**Ada:** Okay, good.

**Grace:** Are we still thinking about moving off the current BI tool next year?

**Ada:** It comes up every planning cycle. I don't think anything's decided.

**Grace:** Fair enough.

**Ada:** Alright, anything else? No? Thanks.
