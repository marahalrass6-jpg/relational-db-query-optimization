SET search_path = operations, public;
-- Run after loading larger production-like data. Capture baseline before creating indexes:
-- DROP INDEX IF EXISTS idx_orders_pending_queue;
-- EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
-- SELECT order_id,order_number,ordered_at FROM orders
-- WHERE status IN ('pending','confirmed','processing') ORDER BY ordered_at LIMIT 100;

-- Optimized plan inspection:
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_id,order_number,ordered_at FROM orders
WHERE status IN ('pending','confirmed','processing') ORDER BY ordered_at LIMIT 100;

-- Statistics maintenance after bulk loads:
ANALYZE orders;
ANALYZE order_items;
ANALYZE inventory;

-- Diagnostic query for indexes and usage:
SELECT schemaname,relname,indexrelname,idx_scan,idx_tup_read,idx_tup_fetch
FROM pg_stat_user_indexes WHERE schemaname='operations' ORDER BY idx_scan DESC;
