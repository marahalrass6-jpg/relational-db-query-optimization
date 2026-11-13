# Testing checklist

Run the following after initialization:

```sql
SET search_path = operations, public;
SELECT COUNT(*) FROM customers;
SELECT order_number, order_total FROM v_order_totals ORDER BY order_number;
SELECT * FROM v_customer_summary ORDER BY lifetime_value DESC;
SELECT * FROM v_inventory_alerts;
SELECT calculate_order_total((SELECT order_id FROM orders WHERE order_number='ORD-10001'));

-- Constraint test: should fail and roll back.
-- INSERT INTO order_items(order_id,line_number,product_id,quantity,unit_price)
-- VALUES (1,99,1,-1,10);

-- Referential integrity test: should fail.
-- DELETE FROM products WHERE product_id=1;
```

Expected seed assertions:

- At least 3 customers, 2 orders, and 3 products exist.
- `ORD-10001` has a total of `2276.00`.
- The status audit table contains entries for seeded orders.
- The pending queue query uses the partial index once the table is sufficiently large; always confirm with `EXPLAIN (ANALYZE, BUFFERS)` on production-like data.
