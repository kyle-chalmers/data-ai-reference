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
> - Use `--scope user` and CLI arguments (`--account`, `--user`) NOT `--connection-name`
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
> Two consequences worth knowing:
> - Typing a secret directly on the command line also puts it in your shell history
>   (`~/.zsh_history`, `~/.bash_history`) and makes it visible to other local users via `ps` for
>   as long as the command runs.
> - Export credentials as environment variables instead and omit the flags. The MCP server reads
>   them at connection time, so nothing sensitive lands in `~/.claude.json`.
>
> Key pair authentication sidesteps this entirely: `--private-key-file` is a path, not a secret.
> Prefer it for anything long-running.
>
> **On the `read -rs` prompts below:** they read a value without echoing it, so the secret never
> appears on screen or in your history. The examples use zsh syntax, the macOS default. On bash,
> swap the argument order: `read -rsp "Password: " SNOWFLAKE_PASSWORD`.

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
combined value as `SNOWFLAKE_PASSWORD`. The `--passcode-in-password` flag tells the server to
read it that way; the flag carries no secret, so it is safe as a CLI argument.

```bash
# Format: PASSWORD + MFA_CODE (6 digits), no space between them
# If your password is "MyPass123" and the MFA code is "987654",
# the combined value is "MyPass123987654"
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
read -rs "SNOWFLAKE_PASSWORD?Password followed by MFA code: "; export SNOWFLAKE_PASSWORD

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --passcode-in-password
```

**Option B: Separate Passcode Parameter**

```bash
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
read -rs "SNOWFLAKE_PASSWORD?Password: "; export SNOWFLAKE_PASSWORD
read -rs "SNOWFLAKE_PASSCODE?MFA passcode: "; export SNOWFLAKE_PASSCODE

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
```

**Option C: Persist the Non-Secret Values**

Account, user, and role are not secrets, so they can live in your shell profile. Keep the
password and passcode out of it.

```bash
# Add to ~/.zshrc or ~/.bashrc
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"

# Then supply the password each session, as in Options A and B
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
```

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

```bash
# The token is a secret, so prompt for it rather than typing it into your history
read -rs "SNOWFLAKE_OAUTH_TOKEN?OAuth token: "; export SNOWFLAKE_OAUTH_TOKEN

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --authenticator oauth \
  --role YOUR-ROLE
```

### 5. Password Authentication

```bash
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
read -rs "SNOWFLAKE_PASSWORD?Password: "; export SNOWFLAKE_PASSWORD

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
```

### 6. Programmatic Access Token (PAT)

```bash
# PATs are supplied through SNOWFLAKE_PASSWORD
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_ROLE="YOUR-ROLE"
read -rs "SNOWFLAKE_PASSWORD?PAT: "; export SNOWFLAKE_PASSWORD

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
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
# This template starts read-only. Turn on individual write statements as a task needs them.
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
  - Command: true         # Allow SHOW, GRANT, etc.
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
config that starts read-only and opens one door at a time is much easier to reason about than one
that starts open.

**Security Best Practices:**
- Start with minimal permissions and add as needed
- Keep `Drop`, `Delete`, and `TruncateTable` set to `false` for safety
- Set `Unknown: false` to block unrecognized SQL statements
- `Command: true` is left on because `SHOW` drives most exploration, but note it also permits
  `GRANT`. Set it to `false` if you do not want the server changing privileges
- The config file is a second line of defense, not the first. Pair it with a Snowflake role that
  is only granted the access you actually need, so the database enforces the same limits
- Review the [SQL Execution documentation](https://github.com/Snowflake-Labs/mcp#sql-execution) for more details

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
# Regenerate the OAuth token through your provider, then re-export it
# and restart Claude Code. The server config itself does not change.
read -rs "SNOWFLAKE_OAUTH_TOKEN?New OAuth token: "; export SNOWFLAKE_OAUTH_TOKEN
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
  --private-key-file ~/.snowflake/keys/rsa_key.p8 \
  --verbose
```

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
| OAuth-enabled apps | OAuth Token | 5 min | Token expiry |

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
| **MFA/2FA** | `--account`, `--user`, `--role`, `--passcode-in-password`, `--warehouse` | `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_PASSCODE` |
| **SSO** | `--account`, `--user`, `--authenticator`, `--role`, `--warehouse` | none |
| **OAuth** | `--account`, `--user`, `--authenticator oauth`, `--role`, `--warehouse` | `SNOWFLAKE_OAUTH_TOKEN` |
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
export SNOWFLAKE_PRIVATE_KEY_FILE="~/.snowflake/keys/rsa_key.p8"

# Secrets: prompt for these rather than typing them, so they stay out of shell history
read -rs "SNOWFLAKE_PASSWORD?Password or PAT: "; export SNOWFLAKE_PASSWORD
read -rs "SNOWFLAKE_PASSCODE?MFA passcode: "; export SNOWFLAKE_PASSCODE
read -rs "SNOWFLAKE_PRIVATE_KEY_FILE_PWD?Key password: "; export SNOWFLAKE_PRIVATE_KEY_FILE_PWD
read -rs "SNOWFLAKE_OAUTH_TOKEN?OAuth token: "; export SNOWFLAKE_OAUTH_TOKEN

# Then add server without explicit credentials
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml
```

---

**Config File:** `~/.claude.json` (top-level `mcpServers` key)
**Repository:** https://github.com/Snowflake-Labs/mcp/tree/main
**Documentation:** https://github.com/Snowflake-Labs/mcp#readme
