-- Unity Catalog function served as an MCP tool by the Unity Catalog Functions MCP server.
-- Uses Databricks' built-in samples.bakehouse data. Change the catalog and schema to your own.
-- The function COMMENT becomes the tool description Claude reads; the parameter COMMENT becomes
-- the argument description.

CREATE OR REPLACE FUNCTION workspace.default.franchise_scorecard(
  franchise STRING COMMENT 'Exact franchise name, for example Baked Bliss'
)
RETURNS TABLE (
  franchise_name STRING,
  total_revenue BIGINT,
  transactions BIGINT,
  avg_ticket DOUBLE,
  top_product STRING,
  top_product_revenue BIGINT
)
COMMENT 'Standard scorecard for one bakehouse franchise: total revenue, number of transactions, average ticket, and best-selling product by revenue. Use this whenever a franchise needs to be evaluated so the numbers are calculated the same way every time.'
RETURN
  WITH t AS (
    SELECT s.product, s.totalPrice
    FROM samples.bakehouse.sales_transactions s
    JOIN samples.bakehouse.sales_franchises f ON s.franchiseID = f.franchiseID
    WHERE f.name = franchise
  ),
  agg AS (
    SELECT SUM(totalPrice) AS total_revenue,
           COUNT(*) AS transactions,
           ROUND(AVG(totalPrice), 2) AS avg_ticket
    FROM t
  ),
  p AS (
    SELECT product AS top_product, SUM(totalPrice) AS top_product_revenue
    FROM t
    GROUP BY product
    ORDER BY top_product_revenue DESC
    LIMIT 1
  )
  SELECT franchise AS franchise_name,
         agg.total_revenue, agg.transactions, agg.avg_ticket,
         p.top_product, p.top_product_revenue
  FROM agg LEFT JOIN p ON TRUE;

-- Test it:
-- SELECT * FROM workspace.default.franchise_scorecard('Baked Bliss');
-- Expected: Baked Bliss | 6642 | 63 | 105.43 | Golden Gate Ginger | 1422
