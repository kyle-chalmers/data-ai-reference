CREATE OR REPLACE VIEW workspace.claude_dashboards_demo.sales_metrics
WITH METRICS
LANGUAGE YAML
COMMENT 'Governed sales metrics on TPC-H order lines'
AS $$
version: 1.1
source: workspace.claude_dashboards_demo.order_lines
dimensions:
  - name: order_date
    expr: o_orderdate
  - name: order_year
    expr: YEAR(o_orderdate)
  - name: order_month
    expr: DATE_TRUNC('MONTH', o_orderdate)
  - name: region
    expr: region
  - name: nation
    expr: nation
  - name: market_segment
    expr: c_mktsegment
  - name: order_status
    expr: o_orderstatus
measures:
  - name: net_revenue
    expr: SUM(l_extendedprice * (1 - l_discount))
    comment: Revenue after line discounts
  - name: gross_revenue
    expr: SUM(l_extendedprice)
  - name: order_count
    expr: COUNT(DISTINCT o_orderkey)
  - name: avg_order_value
    expr: SUM(l_extendedprice * (1 - l_discount)) / COUNT(DISTINCT o_orderkey)
    comment: Net revenue per order
  - name: discount_rate
    expr: SUM(l_extendedprice * l_discount) / SUM(l_extendedprice)
    comment: Dollar-weighted discount rate
$$
