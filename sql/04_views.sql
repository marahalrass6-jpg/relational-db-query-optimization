SET search_path = operations, public;
CREATE OR REPLACE VIEW v_order_totals AS
SELECT o.order_id,o.order_number,o.customer_id,o.status,o.ordered_at,
       COALESCE(SUM(oi.quantity * oi.unit_price - oi.discount_amount),0)::NUMERIC(12,2) AS order_total,
       COUNT(oi.line_number)::INT AS line_count
FROM orders o LEFT JOIN order_items oi ON oi.order_id=o.order_id
GROUP BY o.order_id,o.order_number,o.customer_id,o.status,o.ordered_at;

CREATE OR REPLACE VIEW v_customer_summary AS
SELECT c.customer_id,c.customer_number,c.first_name || ' ' || c.last_name AS customer_name,c.email,
       COUNT(v.order_id)::INT AS order_count,COALESCE(SUM(v.order_total),0)::NUMERIC(14,2) AS lifetime_value,
       MAX(v.ordered_at) AS last_order_at
FROM customers c LEFT JOIN v_order_totals v ON v.customer_id=c.customer_id
GROUP BY c.customer_id,c.customer_number,c.first_name,c.last_name,c.email;

CREATE OR REPLACE VIEW v_inventory_alerts AS
SELECT l.location_code,p.sku,p.product_name,i.quantity_on_hand,i.quantity_reserved,
       i.quantity_on_hand-i.quantity_reserved AS available_quantity,p.reorder_level
FROM inventory i JOIN locations l ON l.location_id=i.location_id JOIN products p ON p.product_id=i.product_id
WHERE i.quantity_on_hand-i.quantity_reserved <= p.reorder_level;

CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT date_trunc('month',o.ordered_at)::date AS sales_month,COUNT(DISTINCT o.order_id)::INT AS order_count,
       SUM(oi.quantity)::INT AS units_sold,SUM(oi.quantity*oi.unit_price-oi.discount_amount)::NUMERIC(14,2) AS revenue
FROM orders o JOIN order_items oi ON oi.order_id=o.order_id
WHERE o.status <> 'cancelled'
GROUP BY date_trunc('month',o.ordered_at)::date;
