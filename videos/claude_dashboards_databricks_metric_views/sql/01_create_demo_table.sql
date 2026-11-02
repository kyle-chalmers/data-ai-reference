-- Editable copy of the TPC-H sample data, one row per order line item.
-- samples.tpch is read-only, and the refresh test in 04_refresh_test.sql needs to change data.
-- Change workspace.claude_dashboards_demo to a catalog and schema you can write to.
CREATE SCHEMA IF NOT EXISTS workspace.claude_dashboards_demo;

CREATE OR REPLACE TABLE workspace.claude_dashboards_demo.order_lines AS
SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice,
       c.c_mktsegment, r.r_name AS region, n.n_name AS nation,
       l.l_linenumber, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_returnflag
FROM samples.tpch.lineitem l
JOIN samples.tpch.orders o ON l.l_orderkey = o.o_orderkey
JOIN samples.tpch.customer c ON o.o_custkey = c.c_custkey
JOIN samples.tpch.nation n ON c.c_nationkey = n.n_nationkey
JOIN samples.tpch.region r ON n.n_regionkey = r.r_regionkey;
