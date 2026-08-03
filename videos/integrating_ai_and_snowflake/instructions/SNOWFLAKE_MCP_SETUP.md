# Snowflake MCP Setup

Quick setup guide for Snowflake MCP - enables Claude to query and explore Snowflake interactively.

## Prerequisites

Before setting up the MCP server, you need:

1. **Clone the Snowflake MCP repository:**
```bash
cd ~/Development  # or your preferred directory
git clone https://github.com/Snowflake-Labs/mcp.git
cd mcp
```

2. **Install uvx (if not already installed):**
```bash
pip install uv
which uvx  # Note the full path for later
```

> **Note:** The service configuration file (`services/configuration.yaml`) is located in the cloned repository. You'll copy this to create your custom configuration.

## Quick Start (5 minutes)

```bash
# 1. Ensure you're in the MCP repository directory
cd ~/Development/mcp

# 2. Verify uvx is installed
which uvx  # Note the path

# 3. Create service configuration file
mkdir -p ~/.mcp
cp ~/Development/mcp/services/configuration.yaml ~/.mcp/snowflake_config.yaml
# Edit ~/.mcp/snowflake_config.yaml as needed (see Service Configuration File section)

# 4. Add to Claude Code at USER LEVEL (available in all projects)
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8

# 5. Verify
claude mcp list
# Should show: snowflake - ✓ Connected

# 6. Test in Claude Code
# Ask: "List all databases in Snowflake"
```

**Time:** 5-10 minutes | **Scope:** User-level (all projects)

> ⚠️ **Critical:**
> - Clone the Snowflake MCP repository first (contains required configuration template)
> - Use `--scope user`, and identify the connection with `--account` and `--user` rather than
>   `--connection-name`. The exception is OAuth, which this server can only reach through a named
>   connection (see [OAuth Authentication](#4-oauth-authentication))
> - Create the service configuration file before adding the MCP server

---

## Authentication Options

The Snowflake MCP server supports all authentication methods from the [Snowflake Python Connector](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector-connect). Choose the method that matches your organization's security requirements.

> ⚠️ **Never pass a password, passcode, or token as a CLI argument.**
>
> `claude mcp add` stores every argument you give it verbatim in `~/.claude.json`. See the
> [Verify Your Configuration](#verify-your-configuration) section below for what that file looks
> like. A secret passed as a flag is written to that file in plaintext and stays there for every
> future session.
>
> This is true even when you write `--password "$SNOWFLAKE_PASSWORD"`. Your shell expands the
> variable before `claude mcp add` ever runs, so the literal value is what gets stored.
>
> So keep secrets out of the flags and supply them through the environment instead. The examples
> below pass `--account`, `--user`, and `--role` as flags, because those identify the connection
> rather than authorize it, and leaving them out has a failure mode of its own (see the warning
> under [Password Authentication](#5-password-authentication)).
>
> **What this does and does not buy you.** Both `~/.claude.json` and your process environment are
> readable only by your own user account, so this does not hide the secret from anyone who could
> not already read it. What it buys is *ephemerality*: an exported variable dies with the shell,
> while `~/.claude.json` persists indefinitely and travels into backups, support bundles, and
> screen shares. That is a real gain, and it is the specific gain.
>
> It also carries a matching hazard. Every process Claude Code launches inherits that variable,
> including commands the model runs for you, and Claude Code writes tool output to plaintext
> transcripts under `~/.claude/projects/`. Avoid running `env`, `printenv`, `set`, or scripts that
> dump their environment during a session where a credential is exported.
>
> Typing a secret directly on the command line is worse than either: it lands in `~/.zsh_history`
> or `~/.bash_history`, and its argv is visible to your other processes via `ps`.
>
> **Key pair authentication sidesteps all of this**, because `--private-key-file` is a path rather
> than a secret. Prefer it for anything long-running.
>
> **On the `read -rs` prompts below:** they read a value without echoing it, so the secret never
> appears on screen or in your history. Run the `read` line **on its own** rather than pasting a
> whole block: a pasted block feeds its next line into `read` as the value, and because `-s`
> hides the input you get no sign that it happened. The examples use zsh syntax, the macOS
> default. On bash, swap the argument order and export separately:
> `read -rsp "Password: " SNOWFLAKE_PASSWORD; export SNOWFLAKE_PASSWORD`.

### 1. Private Key Authentication

```bash
# Ensure key is unencrypted
head -1 ~/.snowflake/keys/rsa_key.p8
# Must show: -----BEGIN PRIVATE KEY-----
# NOT: -----BEGIN ENCRYPTED PRIVATE KEY-----

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8
```

**With encrypted private key:**
```bash
# The key password is a secret, so supply it through the environment, not a flag
read -rs "SNOWFLAKE_PRIVATE_KEY_FILE_PWD?Key password: "; export SNOWFLAKE_PRIVATE_KEY_FILE_PWD

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/encrypted_key.p8
```

### 2. Multi-Factor Authentication (MFA/2FA)

**Option A: Passcode in Password (Most Common)**

When your Snowflake account requires MFA, append the passcode to your password and pass the
combined value as `SNOWFLAKE_PASSWORD`. `--passcode-in-password` takes a value, so write
`--passcode-in-password True`; it carries no secret, so it is safe as a CLI argument.

```bash
# Run this line by itself. Format: PASSWORD + MFA_CODE (6 digits), no space between them.
# If your password is "MyPass123" and the MFA code is "987654", enter "MyPass123987654"
read -rs "SNOWFLAKE_PASSWORD?Password followed by MFA code: "; export SNOWFLAKE_PASSWORD
```

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --passcode-in-password True
```

**Option B: Separate Passcode Parameter**

```bash
# Run each read line by itself
read -rs "SNOWFLAKE_PASSWORD?Password: "; export SNOWFLAKE_PASSWORD
read -rs "SNOWFLAKE_PASSCODE?MFA passcode: "; export SNOWFLAKE_PASSCODE
```

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE
```

**Option C: Persist the Non-Secret Values**

Account, user, and role are not secrets, so they can live in your shell profile if you would
rather not repeat them. Keep the password and passcode out of it.

```bash
# Add to ~/.zshrc or ~/.bashrc
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
```

Supply the password each session as in Options A and B. If you set all three variables here, you
can drop the matching flags from `claude mcp add`, but read the warning under
[Password Authentication](#5-password-authentication) first.

**MFA Important Notes:**
- MFA passcodes expire quickly (typically 30-60 seconds)
- You'll need to regenerate and re-export the passcode for each new session. This is the second
  reason not to pass one as a CLI argument: a value baked into `~/.claude.json` is stale within
  the minute, so the config would be both insecure and wrong
- Because Claude Code launches the MCP server as a subprocess, it sees the environment of the
  shell that started Claude Code. Export the variables, then start Claude Code from that shell
- Consider using SSO or key pair authentication for long-running MCP sessions

### 3. Single Sign-On (SSO)

```bash
# For externalbrowser SSO (opens browser for authentication)
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --authenticator externalbrowser \
  --role YOUR-ROLE
```

**Supported SSO authenticators:**
- `externalbrowser` - Opens system browser for authentication
- `https://YOUR-OKTA-DOMAIN.okta.com` - Okta SSO
- `https://YOUR-ADFS-DOMAIN/adfs/services/trust` - ADFS

### 4. OAuth Authentication

> ⚠️ **This server has no OAuth token parameter.** As of `snowflake-labs-mcp` 1.3.4 there is no
> `--token` flag and no `SNOWFLAKE_OAUTH_TOKEN` environment variable; the only built-in OAuth path
> is the token file that Snowpark Container Services mounts inside a container. Passing
> `--authenticator oauth` on its own gives the connector no token to use.
>
> Check `uvx snowflake-labs-mcp --help` for your installed version before relying on this.

If you need OAuth outside a container, define the connection in `~/.snowflake/connections.toml`
(or the `[connections.NAME]` section of `~/.snowflake/config.toml`, which is where
`snow connection add` writes) and point the server at it by name. That keeps the token out of both
the command line and `~/.claude.json`:

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --connection-name YOUR-CONNECTION
```

One catch: `SNOWFLAKE_*` environment variables take precedence over the values in the named
connection. If you followed Option C and put `SNOWFLAKE_ACCOUNT` and friends in your shell
profile, unset them before using `--connection-name`, or they will quietly win.

Otherwise use SSO (Option 3) or key pair authentication (Option 1), both of which this server
supports directly.

### 5. Password Authentication

```bash
# Run this line by itself
read -rs "SNOWFLAKE_PASSWORD?Password: "; export SNOWFLAKE_PASSWORD
```

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE
```

> ⚠️ **Keep `--account`, `--user`, and `--role` as flags.** If you pass no connection parameters
> at all, the server does not stop and warn you. It falls back to the default entry in
> `~/.snowflake/connections.toml`, so you get `✓ Connected` as whatever identity and role that
> file happens to hold. Launch Claude Code from a shell where you never ran the exports, and it
> connects as something other than what you intended, silently.
>
> After setup, confirm who you actually are:
>
> ```bash
> snow sql -q "SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_ACCOUNT()"
> ```
>
> or ask Claude the same question through the MCP server.

### 6. Programmatic Access Token (PAT)

```bash
# PATs are supplied through SNOWFLAKE_PASSWORD. Run this line by itself.
read -rs "SNOWFLAKE_PASSWORD?PAT: "; export SNOWFLAKE_PASSWORD
```

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE
```

**PAT Important Notes:**
- PATs do NOT evaluate secondary roles
- Select appropriate role when creating the PAT
- More secure than password authentication for automated workflows, because a PAT can be revoked
  on its own without changing the account password
- Do not pass the PAT as `--password "$SNOWFLAKE_PASSWORD"`. The shell expands it and the token
  is written to `~/.claude.json` in plaintext

---

## Service Configuration File

Create a configuration file to enable MCP tools and set SQL permissions. This file is based on the template from the cloned Snowflake MCP repository:

```bash
# Create MCP config directory
mkdir -p ~/.mcp

# Copy the template from the cloned repository and customize
cp ~/Development/mcp/services/configuration.yaml ~/.mcp/snowflake_config.yaml

# OR create a new one with these settings:
cat > ~/.mcp/snowflake_config.yaml << 'EOF'
# Enable the tools you want
other_services:
  object_manager: true    # Database/table/view management
  query_manager: true     # SQL execution
  semantic_manager: true  # Semantic views

# Set SQL permissions - CUSTOMIZE FOR YOUR SECURITY REQUIREMENTS
# This template starts with table-data writes disabled. Turn one on as a task needs it.
# Read the note on Command below before treating this as a read-only setup.
sql_statement_permissions:
  - Select: true          # Allow SELECT queries
  - Create: false         # RECOMMENDED: Disable CREATE until you need it
  - Insert: false         # RECOMMENDED: Disable INSERT until you need it
  - Update: false         # RECOMMENDED: Disable UPDATE until you need it
  - Drop: false           # RECOMMENDED: Disable DROP for safety
  - Delete: false         # RECOMMENDED: Disable DELETE for safety
  - Alter: false          # RECOMMENDED: Disable ALTER until you need it
  - Merge: false          # RECOMMENDED: Disable MERGE until you need it
  - TruncateTable: false  # RECOMMENDED: Disable TRUNCATE for safety
  - Describe: true        # Allow DESCRIBE operations
  - Command: true         # Allow SHOW and anything else the parser does not model (see note)
  - Comment: true         # Allow COMMENT statements
  - Commit: true          # Allow COMMIT
  - Rollback: true        # Allow ROLLBACK
  - Transaction: true     # Allow BEGIN/END
  - Use: true             # Allow USE DATABASE/SCHEMA
  - Unknown: false        # RECOMMENDED: Block unknown statement types
EOF
```

**Reference this file in your `claude mcp add` command:**
```bash
--service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
```

**Turning on a write statement:** when a task genuinely needs one, flip that single key to `true`,
restart Claude Code so the server reloads the config, and flip it back when the task is done. A
config that starts closed and opens one door at a time is much easier to reason about than one
that starts open.

**Security Best Practices:**
- Start with minimal permissions and add as needed
- Keep `Drop`, `Delete`, and `TruncateTable` set to `false` for safety
- Set `Unknown: false` to block unrecognized SQL statements
- Review the [SQL Execution documentation](https://github.com/Snowflake-Labs/mcp#sql-execution) for more details

> ⚠️ **`Command` is a catch-all, and it is wider than it looks.** The server classifies statements
> with a SQL parser, and everything the parser does not model separately lands in `Command`. On
> Snowflake that includes `CREATE ROLE`, `CREATE USER`, `CALL`, `GRANT ROLE ... TO USER`, and,
> most importantly, `EXECUTE IMMEDIATE` — which can carry a `DROP` inside a string and so route
> straight around `Drop: false`.
>
> Privilege grants such as `GRANT SELECT ON TABLE ... TO ROLE ...` are recognized separately and
> blocked, since the template has no `Grant` key. Role membership grants are not, so
> `GRANT ROLE ... TO USER ...` goes through as a `Command`.
>
> The template above leaves `Command: true` because `SHOW` drives nearly all exploration and the
> guide is not much use without it. Accept that trade knowingly: **this config is not a write
> barrier.** Set `Command: false` if you want one, and expect to lose `SHOW`.
>
> Either way, the durable control is the Snowflake role. Grant the role only the access the work
> needs, so the database refuses what the config might let through. Treat
> `sql_statement_permissions` as a guardrail against accidents, not as a defense against a
> determined caller.

---

## Verify Your Configuration

**Check the user-level config file:**
```bash
# Location: ~/.claude.json
cat ~/.claude.json | python3 -m json.tool | grep -A 20 '"mcpServers"'
```

**Should look like:**
```json
{
  "mcpServers": {
    "snowflake": {
      "type": "stdio",
      "command": "/Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx",
      "args": [
        "snowflake-labs-mcp",
        "--account",
        "YOUR-ACCOUNT",
        "--user",
        "YOUR-USER",
        "--role",
        "YOUR-ROLE",
        "--private-key-file",
        "/Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8"
      ],
      "env": {}
    }
  }
}
```

**Verify connection:**
```bash
claude mcp get snowflake
# Should show:
# Scope: User config (available in all your projects)
# Status: ✓ Connected
```

---

## What MCP Does

Once set up, Claude can:
- Query Snowflake interactively
- Explore tables and schemas
- Analyze results automatically
- Remember context across questions
- Available in **all your Claude Code projects**

**Example conversation:**
```
You: "Show me the schema for ANALYTICS database"
Claude: [Lists schemas and tables]

You: "What tables have customer data?"
Claude: [Searches and finds relevant tables]

You: "Query the top 10 customers by revenue"
Claude: [Executes SQL and shows results]
```

---

## Troubleshooting

### General Connection Issues

**Connection failed:**
```bash
# Remove and re-add with correct credentials
claude mcp remove snowflake -s user
# Then re-add using the appropriate authentication command from above
```

**Find uvx path:**
```bash
which uvx
# Use the full path: /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx
```

**Test MCP server manually with inspector:**
```bash
npx @modelcontextprotocol/inspector \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
```

### Authentication-Specific Issues

**Private Key Authentication Issues:**

Check if key is encrypted:
```bash
head -1 ~/.snowflake/keys/rsa_key.p8
# Should show: -----BEGIN PRIVATE KEY-----
# If shows: -----BEGIN ENCRYPTED PRIVATE KEY----- then decrypt it
```

Decrypt encrypted private key:
```bash
openssl rsa -in encrypted_key.p8 -out rsa_key.p8
# Enter the key password when prompted
```

Verify key format:
```bash
# Key should be in PKCS#8 format, not PKCS#1
# If conversion needed:
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt \
  -in rsa_key_pkcs1.pem -out rsa_key.p8
```

**MFA/2FA Issues:**

MFA passcode expired:
```bash
# MFA codes expire every 30-60 seconds
# Because the credential lives in the environment rather than in ~/.claude.json,
# you do not need to remove and re-add the server. Re-export and restart Claude Code:
read -rs "SNOWFLAKE_PASSWORD?Password followed by a fresh MFA code: "; export SNOWFLAKE_PASSWORD
```

Wrong passcode format:
```bash
# Passcode should be 6 digits appended to password
# Correct: "MyPassword123456" (password + 6-digit code)
# Wrong: "MyPassword 123456" (space breaks it)
```

**SSO/OAuth Issues:**

External browser not opening:
```bash
# Check if browser is blocked by firewall
# Try alternative authenticator URL format
--authenticator https://YOUR-SSO-DOMAIN.com
```

OAuth token expired:
```bash
# This server has no OAuth token parameter (see the OAuth section above).
# Regenerate the token with your provider and update the connections.toml entry
# you point at with --connection-name, then restart Claude Code.
```

**Account Identifier Issues:**

SSL error with underscores in account name:
```bash
# If account has underscores: acme-marketing_test_account
# Try dashed version: acme-marketing-test-account
--account acme-marketing-test-account
```

**Permission Errors:**

Role doesn't have access:
```bash
# Verify role has necessary permissions in Snowflake
# Switch to a role that is granted access to the objects you are querying
# Prefer the narrowest role that works, rather than reaching for ACCOUNTADMIN
--role YOUR-ROLE
```

PAT not evaluating secondary roles:
```bash
# PATs only use the role specified when created
# Create a new PAT with the correct role selected
# Cannot be changed after creation
```

### Debug Logging

Enable verbose output to see detailed connection information:
```bash
# Test with verbose logging
uvx snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
```

Note: this server has no `--verbose` flag. Run it in the foreground as above and read what it
prints on stderr.

---

## Working Example

**A working configuration looks like this:**
```bash
Account: YOUR-ACCOUNT
User: YOUR-USER
Role: YOUR-ROLE  (use a read-scoped role, not ACCOUNTADMIN)
Auth: JWT (private key)
Scope: User (available in all projects)
Status: ✓ Connected
```

---

## When to Use

**Use MCP for:**
- "Show me the schema"
- "Find outliers in this data"
- Interactive exploration
- Iterative analysis

**Use CLI for:**
- CSV exports
- Large datasets (>10K rows)
- Automation scripts
- Scheduled jobs

---

## Quick Reference Guide

### Authentication Method Selection

| Scenario | Recommended Method | Setup Time | Session Duration |
|----------|-------------------|------------|------------------|
| Production, no user interaction | Private Key Authentication | 10 min (initial) | Permanent |
| Company requires 2FA | MFA with Passcode in Password | 2 min | 30-60 sec |
| Organization uses SSO | SSO (externalbrowser/Okta/ADFS) | 5 min | Session-based |
| Service accounts | PAT or Private Key | 5 min | Until revoked |
| Local testing only | Password Authentication | 1 min | Session-based |
| OAuth-enabled apps | Named connection, or SSO instead | 10 min | Token expiry |

### Common Command Patterns

**Add MCP server (user-level):**
```bash
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  [AUTH_PARAMETERS]
```

**Remove and re-add:**
```bash
claude mcp remove snowflake -s user
# Then add again with correct parameters
```

**Check status:**
```bash
claude mcp list              # List all MCP servers
claude mcp get snowflake     # Show details for Snowflake server
```

**Test connection:**
```bash
npx @modelcontextprotocol/inspector \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  [AUTH_PARAMETERS]
```

### Authentication Parameters Quick Reference

Non-secret values can go in either column. Secrets belong in the environment, never in a CLI
argument, for the reason given at the top of [Authentication Options](#authentication-options).

| Method | Safe as CLI flags | Supply via environment |
|--------|-------------------|------------------------|
| **Private Key** | `--account`, `--user`, `--role`, `--private-key-file`, `--warehouse` | `SNOWFLAKE_PRIVATE_KEY_FILE_PWD` (encrypted keys only) |
| **MFA/2FA** | `--account`, `--user`, `--role`, `--passcode-in-password True`, `--warehouse` | `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_PASSCODE` |
| **SSO** | `--account`, `--user`, `--authenticator`, `--role`, `--warehouse` | none |
| **OAuth** | not supported directly; see [OAuth Authentication](#4-oauth-authentication) | none |
| **Password** | `--account`, `--user`, `--role`, `--warehouse` | `SNOWFLAKE_PASSWORD` |
| **PAT** | `--account`, `--user`, `--role`, `--warehouse` | `SNOWFLAKE_PASSWORD` (holds the PAT) |

### Environment Variables

All authentication methods can use environment variables instead of CLI arguments. For anything
secret this is the recommended path, not merely an alternative, because CLI arguments are stored
in `~/.claude.json` in plaintext.

```bash
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
export SNOWFLAKE_WAREHOUSE="YOUR-WAREHOUSE"
export SNOWFLAKE_PRIVATE_KEY_FILE="$HOME/.snowflake/keys/rsa_key.p8"  # not ~, it will not expand

# Secrets: prompt for these rather than typing them, so they stay out of shell history.
# Run each read line by itself.
read -rs "SNOWFLAKE_PASSWORD?Password or PAT: "; export SNOWFLAKE_PASSWORD
read -rs "SNOWFLAKE_PASSCODE?MFA passcode: "; export SNOWFLAKE_PASSCODE
read -rs "SNOWFLAKE_PRIVATE_KEY_FILE_PWD?Key password: "; export SNOWFLAKE_PRIVATE_KEY_FILE_PWD

# Then add server without explicit credentials
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml
```

---

**Config File:** `~/.claude.json` (top-level `mcpServers` key)
**Repository:** https://github.com/Snowflake-Labs/mcp/tree/main
**Documentation:** https://github.com/Snowflake-Labs/mcp#readme
