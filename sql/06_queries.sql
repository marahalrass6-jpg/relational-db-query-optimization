SET search_path = operations, public;
-- 1) Recent customer orders with totals.
SELECT c.customer_number,c.first_name || ' ' || c.last_name AS customer,v.order_number,v.status,v.order_total,v.ordered_at
FROM v_order_totals v JOIN customers c ON c.customer_id=v.customer_id
WHERE v.ordered_at >= now()-INTERVAL '90 days' ORDER BY v.ordered_at DESC;

-- 2) Pending fulfillment queue; designed for idx_orders_pending_queue.
SELECT o.order_id,o.order_number,o.ordered_at,l.location_code,c.customer_number
FROM orders o JOIN locations l ON l.location_id=o.fulfillment_location_id JOIN customers c ON c.customer_id=o.customer_id
WHERE o.status IN ('pending','confirmed','processing') ORDER BY o.ordered_at LIMIT 100;

-- 3) Top products by revenue.
SELECT p.sku,p.product_name,SUM(oi.quantity) units_sold,SUM(oi.quantity*oi.unit_price-oi.discount_amount)::NUMERIC(14,2) revenue
FROM order_items oi JOIN products p ON p.product_id=oi.product_id JOIN orders o ON o.order_id=oi.order_id
WHERE o.status <> 'cancelled' GROUP BY p.product_id,p.sku,p.product_name ORDER BY revenue DESC LIMIT 10;

-- 4) Function/procedure examples.
SELECT calculate_order_total((SELECT order_id FROM orders WHERE order_number='ORD-10001'));
-- CALL reserve_inventory(1,1,2);
-- SELECT change_order_status(2,'shipped','Warehouse handoff completed');
