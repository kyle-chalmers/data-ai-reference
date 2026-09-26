-- Source table for the AI Search index.
-- Why a copy: samples is shared read-only, and a Delta Sync index on a standard endpoint needs a
-- source table with Change Data Feed on and a unique primary key.
-- Why ROW_NUMBER: samples.bakehouse.media_gold_reviews_chunked repeats some chunk_id values
-- (196 rows, 138 unique), and the index primary key must be unique.
-- The franchise name and city come from a join, so search results can say which franchise a
-- review belongs to (the review text itself names a neighborhood and city, not the franchise).

CREATE OR REPLACE TABLE workspace.default.bakehouse_reviews
TBLPROPERTIES (delta.enableChangeDataFeed = true)
COMMENT 'Customer review chunks from samples.bakehouse (deduplicated on chunk_id) with franchise names; source for the AI Search demo index'
AS
SELECT chunk_id, franchiseID, franchise_name, city, review_date, chunked_text
FROM (
  SELECT r.chunk_id,
         r.franchiseID,
         f.name AS franchise_name,
         f.city,
         r.review_date,
         r.chunked_text,
         ROW_NUMBER() OVER (PARTITION BY r.chunk_id ORDER BY r.review_date DESC) AS rn
  FROM samples.bakehouse.media_gold_reviews_chunked r
  LEFT JOIN samples.bakehouse.sales_franchises f ON r.franchiseID = f.franchiseID
)
WHERE rn = 1;

-- Check: row count should equal distinct chunk_id count (138 and 138).
-- SELECT COUNT(*), COUNT(DISTINCT chunk_id) FROM workspace.default.bakehouse_reviews;
