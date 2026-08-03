# AI Agent Instructions

Reference repo for the Kyle Chalmers Data & AI YouTube channel: real video work examples
(`videos/`, `tickets/`) plus a template others can adopt for AI-assisted data-ticket work.

Modern models handle judgment calls well — this file stays small on purpose. It holds the
boundaries, repo conventions, and gotchas an agent can't infer; everything else lives in
linked docs loaded only when needed.

## Boundaries (always apply)

- **Database writes need explicit approval.** SELECT/DESCRIBE freely; before any
  UPDATE/INSERT/DELETE/ALTER/DROP/CREATE OR REPLACE/TRUNCATE, show the exact SQL, explain
  the impact, and wait for a clear yes.
- **Outward actions need explicit approval**: Jira comments, Slack messages, git pushes,
  Google Drive backups. Draft first, send after confirmation.
- Never hardcode credentials; use env vars or secure stores.

## Tool selection

- **Jira/Confluence: official Atlassian MCP first**; `acli` only as fallback when the MCP
  is unavailable or unauthenticated. acli can't attach files or reliably tag users — mention
  file locations by name instead.
- **Everything else: CLI first** (`snow`, `gh`, `databricks`, `aws`), other MCPs as fallback.
- `snow` auths via Duo — repeated failures trigger a 15-minute lockout, so capture error
  timestamps. `databricks` uses the DEFAULT profile (no `--profile` flag).
- SQL first for exploration and validation; Python (pandas/matplotlib) for complex
  transformation, stats, or viz. SQL output as CSV (`--format csv`), headers in row 1,
  no blank trailing rows.
- Tool installation and setup: [documentation/helpful_mac_installations.md](documentation/helpful_mac_installations.md)

## Ticket workflow conventions

Folder per ticket, files numbered in review order:

```
tickets/[team_member]/TICKET-XXX/
├── README.md              # business context + ALL assumptions with reasoning
├── CLAUDE.md              # context for future sessions: approach, gotchas, related tickets
├── source_materials/
├── final_deliverables/    # numbered: 1_*.sql, 2_*.csv, … + qc_queries/ subfolder
├── original_code/         # saved DDL when modifying existing objects
└── exploratory_analysis/  # optional, consolidated
```

- Overwrite and consolidate rather than creating file versions; name outputs descriptively
  with record counts (e.g. `payment_history_193_transactions.csv`).
- Document assumptions as you go and proceed — don't halt for confirmation unless asked.
  Enumerate them all in README.md.
- When modifying a database object, save its original DDL first:
  `snow sql -q "SELECT GET_DDL('VIEW', 'schema.view_name')" --format csv`

## Quality control

Every finalized query gets QC before delivery: run it and fix errors, verify filters,
check duplicates, reconcile record counts, validate joins and business logic. Put QC
queries in `final_deliverables/qc_queries/`, numbered.

Gotcha — QC against large/slow views: materialize each side once into TEMP TABLEs (on a
larger warehouse if needed) and run all checks against the temps instead of re-querying
the views each time.

## Git / PRs

- Branch per ticket (`TICKET-XXX`), commit message `TICKET-XXX: description`.
- **PR titles must be semantic** (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, …) —
  the Semantic PR check blocks merge otherwise.
- Jira comments and Slack messages: plain text (no markdown — Jira renders it literally),
  under 100 words, business-first with specific numbers. PR descriptions under 200 words.

## Deeper context (load when relevant)

- [documentation/data_catalog.md](documentation/data_catalog.md) — schemas, core objects, query patterns, known data-quality issues
- [documentation/data_business_context.md](documentation/data_business_context.md) — loan statuses, collections/placements, roll rates, fraud analysis
- [documentation/jira_ticket_creation_template.md](documentation/jira_ticket_creation_template.md) — creating well-formed tickets

## Adopting this template for your org

Fill in your own equivalents of the two docs above (architecture layers, source-selection
rules like "prefer ANALYTICS, avoid legacy schemas", entities, metrics, pitfalls) and keep
this file to boundaries + conventions + gotchas. The portable evolution of this workflow is
[Ticketwright](https://github.com/kyle-chalmers/ticketwright).
