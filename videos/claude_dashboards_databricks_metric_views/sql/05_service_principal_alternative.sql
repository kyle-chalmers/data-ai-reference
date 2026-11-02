-- Optional alternative: a read-only service principal, for teammates without Databricks logins.
-- Trade-off: everyone using the connector then sees what this one identity can see, and the
-- token is a secret stored in the connector settings. The main path in README.md (each viewer
-- signs in as themselves) keeps per-person permissions and needs no stored token.
-- Create the service principal in workspace settings first, then replace <application-id>.
GRANT USE CATALOG ON CATALOG workspace TO `<application-id>`;
GRANT USE SCHEMA, SELECT ON SCHEMA workspace.claude_dashboards_demo TO `<application-id>`;
-- Also give it CAN USE on your SQL warehouse (warehouse Permissions in the UI).
