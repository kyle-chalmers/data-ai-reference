# Dashboard prompts

## Build the dashboard

```text
Using the Databricks SQL (Unity Gateway) connector, build me a live dashboard on the Unity Catalog metric view workspace.claude_dashboards_demo.sales_metrics. Use its measures with MEASURE(), not the raw tables. Three tiles for 1997: (1) average order value, (2) net revenue for the EUROPE region, (3) total net revenue. Add a monthly net revenue trend for 1997. Keep it live so the Refresh button reruns the queries against Databricks.
```

## If the tiles come back blank

The page can show "Updated now" with empty tiles when it reads the connector's results in the wrong shape. This fixed it in every run we tried:

```text
The dashboard shows "Updated now", and Databricks query history shows all three queries finished, but every tile and the chart are blank. Check the page against the actual result shape the SQL connector returns and fix it.
```
