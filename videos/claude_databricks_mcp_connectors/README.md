# Connect Claude to Databricks with Managed MCP Servers

> **YouTube:** link added when the video publishes.
> Follow-up to [Claude Code Makes Databricks Easy](../integrating_claude_and_databricks/README.md),
> which went CLI-only because the managed MCP connector wasn't working for us at the time. This
> guide is the working version.

This guide follows Anthropic's tutorial,
[Using Databricks for Data Analysis](https://academy.claude.com/tutorials/using-databricks-for-data-analysis),
and adds the setup steps it leaves out: Genie One, the Databricks OAuth app, and the `system.ai`
prerequisite. It is written for two readers: a person clicking through Databricks and Claude, and an
AI agent (such as Claude Code) running the Databricks CLI for you.

**Scope: analysis, not building.** The Genie, Unity Catalog Functions, and AI Search servers let
Claude *use* things that already exist in your workspace. They don't create anything. You (or an
agent working through the CLI) build the function, the index, or the Genie space first. The
Databricks SQL server is the exception: the `/api/2.0/mcp/sql` server can write. Databricks
recommends its `system.ai.dbsql` MCP Service instead, which you can make read-only by setting
`disallow_writes` to true in the `system.ai.dbsql_policy` policy
([Databricks SQL MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/databricks-sql)).

Databricks managed MCP servers are labeled **Public Preview** as of September 2026.

---

## Contents

1. [How it works](#how-it-works)
2. [Which server does what](#which-server-does-what)
3. [Prerequisites](#prerequisites)
4. [Step 1: Create one OAuth app](#step-1-create-one-oauth-app)
5. [Step 2: Build the asset](#step-2-build-the-asset)
6. [Step 3: Find the MCP server URL](#step-3-find-the-mcp-server-url)
7. [Step 4: Add the connector in Claude](#step-4-add-the-connector-in-claude)
8. [Step 5: Verify it works](#step-5-verify-it-works)
9. [Having an AI agent do this for you](#having-an-ai-agent-do-this-for-you)
10. [Troubleshooting](#troubleshooting)
11. [Cost and cleanup](#cost-and-cleanup)
12. [Official documentation](#official-documentation)

---

## How it works

Databricks hosts MCP servers for things registered in Unity Catalog. You don't deploy a server.
Every Databricks MCP server connection follows the same five steps:

1. **Create one OAuth app** in the Databricks account console (once per account).
2. **Build the asset**: a Unity Catalog function, an AI Search index, or a Genie space.
   Databricks-provided services such as Genie One already exist in the `system.ai` schema.
3. **Find its MCP server URL.** Databricks serves each asset at a predictable address.
4. **Add a connector in Claude** with that URL and your OAuth app's Client ID.
5. **Verify** that the tools appear and a real question returns the answer you expect.

Unity Catalog permissions apply to every call, so Claude only sees data you can see
([Databricks managed MCP servers](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp)).

## Which server does what

Replace `<workspace-host>` with your workspace host, for example `dbc-xxxxxxxx-xxxx.cloud.databricks.com`.

| Server | What Claude can do | What you build first | MCP server URL | OAuth scope |
|---|---|---|---|---|
| **Genie One** | Ask questions in plain English across the whole workspace | Nothing, but the `system.ai` schema must exist (see [Prerequisites](#prerequisites)) | `https://<workspace-host>/ai-gateway/mcp-services/system.ai.genie_one_mcp` | `ai-gateway` |
| **Genie Agent** | Ask questions scoped to one Genie space | A Genie space | `https://<workspace-host>/api/2.0/mcp/genie/{genie_space_id}` | `genie` |
| **Unity Catalog Functions** | Call your SQL or Python functions | One or more functions in a schema | `https://<workspace-host>/api/2.0/mcp/functions/{catalog}/{schema}` | `unity-catalog` |
| **AI Search** | Search an index of text by meaning | An AI Search endpoint and index | `https://<workspace-host>/api/2.0/mcp/ai-search/{catalog}/{schema}/{index_name}` | `ai-search` |
| **Databricks SQL** | Run any SQL, including writes | Nothing | `https://<workspace-host>/api/2.0/mcp/sql` | `sql` |

Source: [Databricks managed MCP servers](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp).
Databricks' table lists the functions URL per function (`.../{catalog}/{schema}/{function_name}`).
The schema-level URL above is also used in Databricks' own client examples
([Connect MCPs to AI assistants and coding agents](https://docs.databricks.com/aws/en/agents/mcp-tools/connect-clients)),
and it turns every function in the schema into a tool.

**Don't confuse the Genie URLs.** The per-space Genie Agent URL ends in a space ID. The older
space-less URL, `https://<workspace-host>/api/2.0/mcp/genie`, was Genie One's Beta endpoint and
"will be sunset on October 31, 2026"
([Genie One MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/genie-mcp)). Use the
`ai-gateway/mcp-services/system.ai.genie_one_mcp` URL for Genie One.

Databricks recommends starting with Genie One for analytics and using the Databricks SQL server
when you need to run a specific query you already wrote
([same page](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp)). Genie One gives
Claude tools for asking a question and collecting the answer (`genie_ask`, `genie_poll_response`,
`genie_get_query_result`, `genie_cancel_response`, plus `view_ask` on clients that support MCP
Apps, which Claude does). None of them call your function or search your index, so add the
Functions and AI Search servers when you need an exact calculation or document search.

## Prerequisites

1. **The Databricks CLI, installed and logged in.** This is what lets an AI agent build and test
   everything for you.
   ```bash
   databricks auth login --host https://<workspace-host> --profile <profile>
   databricks current-user me --profile <profile>
   ```
   See [Install the Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/install) and
   [CLI authentication](https://docs.databricks.com/aws/en/dev-tools/cli/authentication).
2. **A workspace with Unity Catalog and serverless compute.** Required for AI Search
   ([Create AI Search endpoints and indexes](https://docs.databricks.com/aws/en/ai-search/create-ai-search)).
3. **Account admin rights**, to create the OAuth app in Step 1.
4. **For Genie One only: the `system.ai` schema.** The Genie One MCP service lives at
   `system.ai.genie_one_mcp` in Unity Catalog
   ([Genie One MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/genie-mcp)).
   Check for it in the SQL editor:
   ```sql
   SHOW SCHEMAS IN system LIKE 'ai';
   ```
   One row means you have it. Zero rows means Genie One will not connect, and you can't add the
   schema yourself: `databricks system-schemas enable <metastore-id> ai` returns *"ai system schema
   can only be enabled by Databricks."* On a brand-new trial workspace we tested, the schema was
   missing at signup and Databricks added it about a day later. That's one observation, not a
   promised timeline. Watch for the look-alike: `system.ai_gateway` is a different schema.
5. **A Claude plan with connectors.** You add connectors yourself under **Customize > Connectors**
   (in Claude's settings panel). On Team and Enterprise plans, an Owner can add a custom connector
   for the whole organization under **Organization settings > Connectors**, and members then
   connect to it. Claude's help center notes that Free plans are limited to one custom connector.
   See [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).
   (Anthropic's tutorial says "Admin settings > Connectors"; the help center wording above is
   newer.)

## Step 1: Create one OAuth app

One app can authorize every server in this guide. The URL you give Claude decides which server it
connects to. Official guide:
[Connect MCPs to AI assistants and coding agents](https://docs.databricks.com/aws/en/agents/mcp-tools/connect-clients).

**In the account console:** **Settings > App connections > Add connection**.

| Field | Value | Why |
|---|---|---|
| Redirect URLs | `https://claude.ai/api/mcp/auth_callback` and `https://claude.com/api/mcp/auth_callback` | Claude's callback addresses, from the Claude Connectors tab of the guide above |
| Access scopes | The scopes for the servers you plan to use (table above), plus `offline_access`. `openid`, `email`, `profile` are optional. Leave out `sql` unless you want Claude to use the Databricks SQL server, which can write. | `offline_access` gives Claude a refresh token so you don't have to sign in again every hour |
| Generate a client secret | **Unchecked** | Both Claude and Databricks document a secret field, but Claude's **Databricks Genie** directory card only asks for a Server URL and Client ID. An app with a secret failed to connect there in our test, and a public app (no secret) worked. This setting can't be changed after the app is created. |
| Single-use refresh tokens | Off | The option says it "requires client support"; we did not confirm Claude supports refresh token rotation |

Save it and copy the **Client ID**. Databricks says changes to OAuth apps "can take 30 minutes to
process" ([Enable or disable partner OAuth applications](https://docs.databricks.com/aws/en/integrations/enable-disable-oauth));
ours worked immediately.

**Where the scope names come from:** each server's scope is in the
[managed MCP servers table](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp), and
you can read it straight from the server (see [Step 5](#step-5-verify-it-works)). The general
[API scopes reference](https://docs.databricks.com/api/workspace/scopes) doesn't list `ai-gateway`
or `offline_access`, so don't rely on it alone.

Scopes to skip unless you have a reason: `all-apis` (broader than needed), `ai-functions`
(Databricks' built-in AI SQL functions, which are different from Unity Catalog functions),
`vector-search` (a legacy alias from before Vector Search was renamed AI Search; use `ai-search`),
and `jobs` (no MCP server uses it).

**With the CLI (alternative, not run for this video):** log in at the account level, then create
the app from [`examples/oauth_app.json`](examples/oauth_app.json). Run it from this guide's folder
so the `@examples/...` path resolves, and edit the scope list in the file first. See the
[custom app integration API reference](https://docs.databricks.com/api/account/customappintegration)
for the full request body.
```bash
databricks auth login --host https://accounts.cloud.databricks.com --account-id <account-id> --profile <account-profile>
databricks account custom-app-integration create --json @examples/oauth_app.json --profile <account-profile>
```

## Step 2: Build the asset

### A Unity Catalog function

Write the function in the SQL editor, or have an agent run it through the CLI. Example:
[`examples/franchise_scorecard.sql`](examples/franchise_scorecard.sql), which uses Databricks'
built-in `samples.bakehouse` data. References:
[CREATE FUNCTION](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function),
[Unity Catalog functions MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/uc-functions).

- **The function's `COMMENT` is the tool description Claude reads**, and each parameter's
  `COMMENT` becomes the argument description. Write them for Claude.
- The MCP server only calls functions that already exist. Claude can't create one through it.
- To run SQL from the CLI without opening the editor, use the
  [Statement Execution API](https://docs.databricks.com/api/workspace/statementexecution/executestatement):
  ```bash
  databricks warehouses list --profile <profile>
  databricks api post /api/2.0/sql/statements --profile <profile> \
    --json '{"warehouse_id":"<warehouse-id>","statement":"SELECT * FROM workspace.default.franchise_scorecard(\"Baked Bliss\")","wait_timeout":"50s"}'
  ```

### An AI Search index

Reference: [Create AI Search endpoints and indexes](https://docs.databricks.com/aws/en/ai-search/create-ai-search).

1. **Start from a table you own, with Change Data Feed on.** For standard endpoints, Databricks
   says "the source table must use a change data feed." Shared data such as `samples` is
   read-only, so copy it first. The index also needs a **unique primary key**. Databricks' own
   sample review table repeats some keys (196 rows, 138 unique), so the example deduplicates:
   [`examples/bakehouse_reviews_table.sql`](examples/bakehouse_reviews_table.sql).
2. **Create an endpoint**, the compute that serves searches. In the UI: **Compute > AI Search >
   Create endpoint**, type Standard. With the CLI (this waits until the endpoint is online; add
   `--no-wait` to return right away):
   ```bash
   databricks vector-search-endpoints create-endpoint bakehouse-demo STANDARD --profile <profile>
   ```
3. **Create the index.** In the UI: open the table in Catalog Explorer, then **Create > Vector
   search index**. Choose **Compute embeddings**, pick the text column, pick the endpoint, keep
   sync mode **Triggered**, and leave "Columns to index" blank so every column comes back in
   results. The embedding model is under Advanced settings. The UI defaulted to
   `databricks-qwen3-embedding-0-6b`; our example uses `databricks-gte-large-en` because that's
   the one we tested searches with. With the CLI, run from this guide's folder using
   [`examples/ai_search_index.json`](examples/ai_search_index.json):
   ```bash
   databricks vector-search-indexes create-index --json @examples/ai_search_index.json --profile <profile>
   ```
4. **Wait for the first sync.** Check until it's ready and the row count matches the table:
   ```bash
   databricks vector-search-indexes get-index workspace.default.bakehouse_reviews_index --profile <profile>
   ```
   The first sync of 138 rows took 14 to 18 minutes in our tests. **Before it finishes, searches
   return an empty list with no error**, which is easy to mistake for "no matching results."
5. **After the table changes**, a Triggered index only updates when you run a sync:
   ```bash
   databricks vector-search-indexes sync-index workspace.default.bakehouse_reviews_index --profile <profile>
   ```

The CLI still calls these `vector-search-*` commands. Databricks renamed Vector Search to AI Search,
and the command names haven't changed.

### A Genie space

Create it in the UI: **Genie Agents > New** ([Create and manage a Genie Agent](https://docs.databricks.com/aws/en/genie-agents/set-up)).
The CLI we used (v0.277) can list spaces but not create them. List spaces to get the ID for the URL:
```bash
databricks genie list-spaces --profile <profile>
```

## Step 3: Find the MCP server URL

Any of these works:

- **AI Gateway > MCPs**: click **AI Gateway** in the workspace sidebar (the page opens titled
  **Unity Gateway**), then the **MCPs** tab. It lists every MCP server, including the `system.ai`
  services and anything you built. Click one to see its URL at the top of the page.
- **The index page in Catalog Explorer** shows an **MCP server URL** field once the index exists.
- **The URL patterns** in the [table above](#which-server-does-what).

## Step 4: Add the connector in Claude

**Genie One** has a card in Claude's connector directory,
[Databricks Genie](https://claude.com/connectors/databricks): open **Customize > Connectors**, find
the Databricks Genie card, click **Connect**, and enter the Server URL and your Client ID. This card
only accepts Genie One URLs. It rejects a per-space Genie Agent URL with "Server URL doesn't match
expected format."

**Everything else** goes in as a custom connector:

1. **Customize > Connectors > + Add > Add custom connector**
2. Name it, for example `Databricks UC Functions`
3. Paste the MCP server URL
4. Open **Advanced settings** and enter your OAuth Client ID. Leave the secret blank, since the app
   from Step 1 has none.
5. Click **Add**, then **Connect**
6. On Databricks' **Authorize as…** screen, choose **yourself** (your own email), not a group. We
   chose our own email in testing. The screen also lists groups because of Databricks' role-based
   access control, which the account console describes this way: when you assume a group, "the
   group's permissions fully replace the user's permissions."

Reference: [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).

## Step 5: Verify it works

**In Claude:** check that the connector lists its tools, then ask a question whose answer you
already know. A "Connected" label alone doesn't prove the connection works.

**From a terminal (optional):** call the server directly with your CLI login to see whether a
problem is on the Databricks side. This uses the CLI's own sign-in, not your OAuth app, so it tests
the server and your permissions.
```bash
TOKEN=$(databricks auth token --profile <profile> | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
curl -s -X POST "https://<workspace-host>/api/2.0/mcp/functions/<catalog>/<schema>" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

To see which OAuth scopes a server asks for, open its metadata. No login is needed:
```bash
curl -s "https://<workspace-host>/.well-known/oauth-protected-resource/api/2.0/mcp/functions/<catalog>/<schema>"
```

## Having an AI agent do this for you

Once the CLI is logged in, an agent such as Claude Code can build and test every asset in Step 2.
The OAuth app (Step 1) and clicking **Connect** in Claude (Step 4) stay with you, because they
involve account admin rights and your own sign-in.

Two rules to give the agent every time:
- **Approval before changes.** It shows you every SQL statement and CLI command that creates or
  changes something, then waits for your yes. AI Search endpoints cost money while they exist.
- **Tokens stay hidden.** When it needs a token from `databricks auth token`, it stores it in a
  shell variable and never prints it.

The prompts below name a CLI profile. If you only have one Databricks login, it's the `DEFAULT`
profile, and the agent can leave out `--profile`.

**Build a function:**
> Using Databricks CLI profile `<profile>`, create a Unity Catalog SQL function in
> `<catalog>.<schema>` that `<what it should calculate>`. Write a clear COMMENT on the function and
> each parameter, because Claude reads them as the tool description. Show me the SQL and wait for
> my approval before you run it. Then test it with a SELECT, and confirm it shows up as a tool by
> calling `tools/list` on `https://<workspace-host>/api/2.0/mcp/functions/<catalog>/<schema>`,
> using a token from `databricks auth token` stored in a shell variable and never printed.

**Build an AI Search index:**
> Using Databricks CLI profile `<profile>`, build an AI Search index over `<table>`, searching the
> `<text column>` column. If I don't own the table, copy it into `<catalog>.<schema>` first. Make
> sure Change Data Feed is on and the primary key is unique. Create a Standard endpoint named
> `<endpoint>` if none exists. Create a delta sync index with Databricks-computed embeddings and
> Triggered sync. Show me every SQL statement and CLI command that creates something, and wait for
> my approval before running it, because the endpoint bills while it exists. Wait until the
> indexed row count matches the table, then run one test search through the MCP URL and show me
> the results.

**Check whether Genie One will work:**
> Using Databricks CLI profile `<profile>`, check whether the `system.ai` schema exists and whether
> `https://<workspace-host>/ai-gateway/mcp-services/system.ai.genie_one_mcp` answers `tools/list`.

**Troubleshoot a failed connection:**
> Claude says authorization failed for `<MCP server URL>`. Using Databricks CLI profile
> `<profile>`, read the OAuth protected resource metadata for that URL, compare the scopes it asks
> for with my OAuth app's scopes, and call `tools/list` with a CLI token (stored in a variable,
> never printed) to tell whether the problem is on the Databricks side or the Claude side. Don't
> change anything; just report what you find.

**Using Claude Code instead of the Claude app?** Databricks documents a Unity Gateway CLI that
connects coding agents such as Claude Code to these servers through your Databricks CLI login,
without creating an OAuth app. See the OAuth examples in
[Connect MCPs to AI assistants and coding agents](https://docs.databricks.com/aws/en/agents/mcp-tools/connect-clients).

## Troubleshooting

| What you see | Likely cause | What to do |
|---|---|---|
| Claude: "Authorization with the MCP server failed," and Genie One returns 403 "Not authorized to invoke MCP service" | The `system.ai` schema is missing, so the Genie One service doesn't exist in your workspace | Run `SHOW SCHEMAS IN system LIKE 'ai';`. If it returns nothing, only Databricks can enable it. The Genie Agent and other servers still work without it. |
| Connection fails with an app that has a client secret | The app is a confidential client, and the Databricks Genie directory card has no secret field | Create a new app with "Generate a client secret" unchecked. (A custom connector's Advanced settings does accept a secret, but we only tested public apps.) |
| "Server URL doesn't match expected format" | The Databricks Genie directory card only accepts Genie One URLs | Add the URL through **Add custom connector** instead |
| Authorization fails for one server but not another | The app is missing that server's scope | Check `scopes_supported` in the server's metadata (Step 5) and add the scope to the app |
| Search returns `[]` | The index hasn't finished its first sync | Wait until the indexed row count matches the table |
| Search returns the wrong items | Search ranks results by meaning. It isn't a filter. | Search with words that actually appear in the text, and check the returned columns (for example a name or city) before trusting a result |
| A function doesn't appear as a tool | It's in a different schema, or you lack `EXECUTE` on it | Check the URL's catalog and schema, and your grants |

Claude's own guide for connector errors: [Connector troubleshooting](https://claude.com/docs/connectors/building/troubleshooting).

## Cost and cleanup

AI Search endpoints cost money while they exist, even when idle. Delete the index first, then the
endpoint:
```bash
databricks vector-search-indexes delete-index workspace.default.bakehouse_reviews_index --profile <profile>
databricks vector-search-endpoints delete-endpoint bakehouse-demo --profile <profile>
```
Pricing for each server type: [Databricks managed MCP servers, Pricing](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp).
Genie One's pricing is on the [Genie One MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/genie-mcp)
page (it runs on Chat in Genie One).

## Official documentation

**Anthropic / Claude**
- [Using Databricks for Data Analysis](https://academy.claude.com/tutorials/using-databricks-for-data-analysis) (the tutorial this guide builds on)
- [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp)
- [Databricks Genie connector](https://claude.com/connectors/databricks)
- [Connector troubleshooting](https://claude.com/docs/connectors/building/troubleshooting)

**Databricks: MCP servers**
- [Databricks managed MCP servers](https://docs.databricks.com/aws/en/agents/mcp-tools/managed-mcp)
- [Genie One MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/genie-mcp)
- [Unity Catalog functions MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/uc-functions)
- [AI Search MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/ai-search)
- [Databricks SQL MCP server](https://docs.databricks.com/aws/en/agents/mcp-tools/databricks-sql)
- [Connect MCPs to AI assistants and coding agents](https://docs.databricks.com/aws/en/agents/mcp-tools/connect-clients)
- [Genie One MCP launch post](https://www.databricks.com/blog/genie-one-mcp-give-any-ai-agent-right-business-context)

**Databricks: building the assets**
- [CREATE FUNCTION (SQL)](https://docs.databricks.com/aws/en/sql/language-manual/sql-ref-syntax-ddl-create-sql-function)
- [Unity Catalog user-defined functions](https://docs.databricks.com/aws/en/udf/unity-catalog)
- [Databricks AI Search](https://docs.databricks.com/aws/en/ai-search/ai-search)
- [Create AI Search endpoints and indexes](https://docs.databricks.com/aws/en/ai-search/create-ai-search)
- [Query an AI Search index](https://docs.databricks.com/aws/en/ai-search/query-ai-search)
- [Create and manage a Genie Agent](https://docs.databricks.com/aws/en/genie-agents/set-up)

**Databricks: CLI, OAuth, and APIs**
- [Install the Databricks CLI](https://docs.databricks.com/aws/en/dev-tools/cli/install)
- [CLI authentication](https://docs.databricks.com/aws/en/dev-tools/cli/authentication)
- [Vector search index CLI commands](https://docs.databricks.com/aws/en/dev-tools/cli/reference/vector-search-indexes-commands)
- [API scopes reference](https://docs.databricks.com/api/workspace/scopes)
- [Custom app integration API](https://docs.databricks.com/api/account/customappintegration)
- [Enable or disable partner OAuth applications](https://docs.databricks.com/aws/en/integrations/enable-disable-oauth)
- [Statement Execution API](https://docs.databricks.com/api/workspace/statementexecution/executestatement)

*Last verified: September 2026. Databricks and Claude change these screens and endpoints often, so
check the official pages above if something doesn't match.*
