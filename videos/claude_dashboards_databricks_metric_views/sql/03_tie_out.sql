-- Check the dashboard by hand. Write these before you look at the dashboard's numbers.

-- 1. Expected values straight from the base table, with the definitions spelled out.
SELECT
  ROUND(SUM(CASE WHEN YEAR(o_orderdate) = 1997 THEN l_extendedprice * (1 - l_discount) END), 2) AS total_net_revenue_1997,
  ROUND(SUM(CASE WHEN YEAR(o_orderdate) = 1997 AND region = 'EUROPE' THEN l_extendedprice * (1 - l_discount) END), 2) AS europe_net_revenue_1997,
  ROUND(SUM(CASE WHEN YEAR(o_orderdate) = 1997 THEN l_extendedprice * (1 - l_discount) END)
        / COUNT(DISTINCT CASE WHEN YEAR(o_orderdate) = 1997 THEN o_orderkey END), 2) AS avg_order_value_1997
FROM workspace.claude_dashboards_demo.order_lines;

-- 2. The same three numbers through the metric view. These should match query 1.
SELECT ROUND(MEASURE(net_revenue), 2) AS total_net_revenue_1997,
       ROUND(MEASURE(net_revenue) FILTER (WHERE region = 'EUROPE'), 2) AS europe_net_revenue_1997,
       ROUND(MEASURE(avg_order_value), 2) AS avg_order_value_1997
FROM workspace.claude_dashboards_demo.sales_metrics
WHERE order_year = 1997;

-- 3. The quick way, for contrast. Averaging the order total over the line-item table counts
--    a multi-line order once per line, and the order total includes tax.
SELECT ROUND(AVG(o_totalprice), 2) AS naive_avg_order_value_1997
FROM workspace.claude_dashboards_demo.order_lines
WHERE YEAR(o_orderdate) = 1997;
