# Weekly Analytics Sync

**Date:** Thursday, 10:00 AM
**Attendees:** Ada Lovelace, Grace Hopper

---

## AI Meeting Notes

### Summary

The team reviewed a recurring failure in the executive dashboard, planned the churn breakdown needed
for the upcoming QBR, and raised several open questions about reporting and data quality that were
not resolved in the call.

### Discussion

- The exec dashboard broke again on Tuesday. The refresh failed silently: the job reported success
  because the extract completed, but it pulled zero rows. Nobody noticed until Wednesday afternoon,
  when stale numbers were flagged. This is the third occurrence this month.
- A fix was agreed: repair the refresh and add a row-count check so the job fails loudly when it
  returns nothing. Committed for end of week, described as a small change.
- The QBR is in three weeks and churn is wanted broken out by region this time. There was an open
  question about whether "region" means sales regions or billing regions, since the two do not line
  up. Sales regions were assumed, on the grounds that the rest of the deck uses them.
- Churn by region has never been cut this way before, so it was flagged as taking some time. It was
  also raised that finance may already have a version of this, since they presented a churn slide
  last quarter. No decision was reached on whether to align the definitions.
- The weekly deck was questioned. There is a sense that nobody reads it, and a preference was voiced
  for having the information in Slack instead. This was explicitly parked, as there is no time to
  redesign reporting right now.
- Test accounts are still appearing in customer counts, a few hundred of them, all identifiable by
  the internal email domain. Filtering them out was floated but described as not urgent.
- Every team is using a slightly different revenue number. A commitment was made to write down the
  definition actually in use and publish it in Confluence, so there is one place to point people.
- A question was raised late in the call about whether the Europe rollup includes the reseller channel.
  If it does, the regional churn cut will be wrong. A commitment was made to check this before
  building the churn cut.
- Moving off the current BI tool next year came up again. It was noted that this surfaces every
  planning cycle and nothing has been decided.

### Action items

- Fix the dashboard refresh and add a row-count check. End of week.
- Pull churn by region for the QBR. Three weeks.
- Document the revenue metric definition in Confluence.
- Confirm whether reseller is included in the Europe rollup, before the churn cut is built.
