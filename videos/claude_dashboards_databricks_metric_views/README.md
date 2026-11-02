# Live Claude Dashboards on a Databricks Metric View

> **YouTube:** link added when the video publishes.
> Builds on [Claude + Databricks Managed MCP Servers](../claude_databricks_mcp_connectors/README.md),
> which sets up the OAuth app this guide reuses.

A Claude Dashboard pointed at a Unity Catalog metric view through Databricks' SQL server stays live:
every Refresh reruns the governed definitions, so the tiles move when the data does, and each number
still matches a query you write by hand.

Want this for your own data? The free [`metric-view-dashboard` skill](https://github.com/kyle-chalmers/kyle-chalmers-skills/tree/main/skills/metric-view-dashboard)
reads any metric view you point it at, writes the dashboard prompt, and builds the tie-out and refresh
checks for it.

---

## Contents

1. [How it works](#how-it-works)
2. [Prerequisites](#prerequisites)
3. [Step 1: Create the demo table and metric view](#step-1-create-the-demo-table-and-metric-view)
4. [Step 2: Connect Claude to the Databricks SQL server](#step-2-connect-claude-to-the-databricks-sql-server)
5. [Step 3: Build the dashboard](#step-3-build-the-dashboard)
6. [Step 4: Check the numbers by hand](#step-4-check-the-numbers-by-hand)
7. [Step 5: Prove it is live](#step-5-prove-it-is-live)
8. [Alternative: a service principal](#alternative-a-service-principal)
9. [Troubleshooting](#troubleshooting)
10. [Cleanup](#cleanup)
11. [Official documentation](#official-documentation)

---

## How it works

- **The metric view holds the definitions.** Measures such as net revenue and average order value
  are written once in Unity Catalog. Anyone who queries them with `MEASURE()`, including Claude,
  gets the same math.
- **The SQL server runs the queries.** `system.ai.dbsql`, served through Unity Gateway, is the
  Databricks SQL MCP server Databricks recommends for new integrations. Claude writes the SQL;
  Databricks runs it with your permissions.
- **The dashboard reruns them on Refresh.** Each tile is a stored query, so a refresh asks the
  warehouse again instead of reusing a copy.

Why the metric view matters: in this dataset, averaging the order total over the line-item table
gives an average order value of 188,857 for 1997, while the metric view's definition (net revenue
divided by distinct orders) gives 145,294. The quick version counts a multi-line order once per
line and includes tax.

## Prerequisites

- A Databricks workspace with Unity Catalog and a SQL warehouse.
- The **Unity Gateway beta** enabled by an account admin on the account console Previews page
  ([Databricks SQL MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/databricks-sql)).
- A Databricks OAuth app with the `ai-gateway` scope and Claude's redirect URLs. The
  [connectors guide](../claude_databricks_mcp_connectors/README.md#step-1-create-one-oauth-app)
  walks through creating it.
- Permission to create a schema, table and metric view (or an admin who can).
- A Claude plan with Dashboards (beta on Pro, Max, Ultra, Team and Enterprise per the
  [Claude Help Center](https://support.claude.com/en/articles/17454700-get-started-with-claude-dashboards)).

## Step 1: Create the demo table and metric view

Run these in the Databricks SQL editor, changing `workspace.claude_dashboards_demo` to a catalog and
schema you can write to:

1. [`sql/01_create_demo_table.sql`](sql/01_create_demo_table.sql): an editable copy of the TPC-H
   sample data (about 30 million line items).
2. [`sql/02_metric_view.sql`](sql/02_metric_view.sql): the `sales_metrics` metric view with
   dimensions (order date, year, month, region, nation, segment, status) and measures (net and
   gross revenue, order count, average order value, discount rate).

## Step 2: Connect Claude to the Databricks SQL server

In Claude: **Customize > Connectors > Add > Add custom connector**.

| Field | Value |
|---|---|
| Name | `Databricks SQL (Unity Gateway)` |
| MCP server URL | `https://<workspace-host>/ai-gateway/mcp-services/system.ai.dbsql` |
| Authentication | Sign in now |
| OAuth client | Use your own OAuth client, with your OAuth app's Client ID and no secret |

Click **Add**, then **Connect**, and approve the Databricks sign-in. Then set the connector's tools
to **Always allow**, because a dashboard refresh cannot stop to ask for approval.

You sign in as yourself, so every query runs with your Unity Catalog permissions and Query History
records who ran it. To make the server read-only for everyone, Databricks offers a beta policy:
set `disallow_writes` to true in the built-in `system.ai.dbsql_policy` (requires the Unity Gateway
Service Policies workspace preview; see
[Govern an MCP](https://docs.databricks.com/aws/en/ai-gateway/govern-mcp-service)).

## Step 3: Build the dashboard

Paste the build prompt from [`prompts/dashboard_prompts.md`](prompts/dashboard_prompts.md) into a
new Claude chat. When the dashboard appears, allow it to use the connector. Open **Sources** and
check that each tile's query reads the metric view with `MEASURE()`.

## Step 4: Check the numbers by hand

Run [`sql/03_tie_out.sql`](sql/03_tie_out.sql). Query 1 computes the expected values from the base
table with the definitions spelled out; query 2 gets the same numbers through the metric view. Both
should match the tiles: average order value 145,293.96, Europe net revenue 33,100,640,837.46 and
total net revenue 165,246,449,758.48 for 1997.

## Step 5: Prove it is live

Run the `INSERT` in [`sql/04_refresh_test.sql`](sql/04_refresh_test.sql), click **Refresh** on the
dashboard, and check that total and Europe net revenue each rose by exactly 10 billion and the
December point jumped. Then run the `DELETE` and refresh again. Query History shows a new query for
each source on every refresh.

## Alternative: a service principal

If teammates without Databricks logins need the dashboard, put a read-only service principal behind
the connector instead: grant it access with
[`sql/05_service_principal_alternative.sql`](sql/05_service_principal_alternative.sql), create a
token for it, and add the connector with **No sign-in** and an `Authorization: Bearer <token>`
request header. Everyone using that connector then sees what the service principal can see, and the
token is a secret stored in the connector settings, so keep it read-only and short-lived.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Tiles say "Updated now" but are blank | The page read the connector's results in the wrong shape. Send the second prompt in [`prompts/dashboard_prompts.md`](prompts/dashboard_prompts.md). |
| Sign-in opens a 404 page | You are probably on the older `/api/2.0/mcp/sql` endpoint, which Claude cannot sign in to today ([claude-ai-mcp#1212](https://github.com/anthropics/claude-ai-mcp/issues/1212)). Use the Unity Gateway URL above. |
| Tiles time out after about 3 minutes | A Genie-backed dashboard starts a Genie conversation on every refresh and can run past the dashboard's load limit. Use the SQL server for live dashboards. |
| "MCP service does not exist, or you do not have access" | You need `EXECUTE` on the MCP service plus `USE CATALOG` and `USE SCHEMA` on `system.ai`, and the Unity Gateway beta must be on. |

## Cleanup

```sql
DROP SCHEMA IF EXISTS workspace.claude_dashboards_demo CASCADE;
```

Remove the connector from Claude when you are done, and revoke any service principal token.

## Official documentation

- [Databricks SQL MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/databricks-sql)
- [Govern an MCP](https://docs.databricks.com/aws/en/ai-gateway/govern-mcp-service)
- [Unity Catalog metric views: query](https://docs.databricks.com/aws/en/uc-semantics/metric-views/query)
- [Get started with Claude Dashboards](https://support.claude.com/en/articles/17454700-get-started-with-claude-dashboards)
