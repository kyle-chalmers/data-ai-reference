-- Refresh test: change the data, click Refresh on the dashboard, check the tiles moved.
-- This writes to the demo table only. Run the DELETE afterwards to put it back.

-- Step 1: add one obvious order (10 billion, EUROPE, December 1997).
INSERT INTO workspace.claude_dashboards_demo.order_lines VALUES
  (999999999, DATE'1997-12-15', 'O', 10000000000.00, 'BUILDING', 'EUROPE', 'GERMANY', 1, 1, 10000000000.00, 0.00, 'N');

-- Step 2: click Refresh on the dashboard. Total and Europe net revenue for 1997 should each rise
-- by exactly 10 billion, average order value should rise, and the December point should jump.
-- Re-run 03_tie_out.sql query 1 to get the new expected values.

-- Step 3: remove the test order and refresh again.
DELETE FROM workspace.claude_dashboards_demo.order_lines WHERE o_orderkey = 999999999;
