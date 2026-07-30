# 3 — Draft the tickets, then ship on approval

Run last. The stop instruction is the point of this prompt.

```
Now take only the items marked accept. For each one, draft the Jira ticket you would
create: summary, description, the business question it answers, the grain, and the
metric definition.

Show me all of them and stop. Do not create anything in Jira until I say go.
```

**Expected:** drafted tickets printed in the terminal, and nothing written to Jira.

**If it creates them anyway:** that is the review gate failing, and it is the reason to draft
before writing rather than trusting the instruction. Delete the created issues and re-run with the
stop instruction stated first rather than last.

Once the drafts look right, approve and let it create them.
