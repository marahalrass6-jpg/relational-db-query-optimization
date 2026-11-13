SET search_path = operations, public;
-- Foreign-key and join-path indexes.
CREATE INDEX idx_employees_department ON employees(department_id) WHERE active;
CREATE INDEX idx_products_category_active ON products(category_id, product_id) WHERE active;
CREATE INDEX idx_inventory_product ON inventory(product_id, location_id);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, ordered_at DESC);
CREATE INDEX idx_orders_status_date ON orders(status, ordered_at DESC);
CREATE INDEX idx_orders_location_status ON orders(fulfillment_location_id, status);
CREATE INDEX idx_order_items_product ON order_items(product_id, order_id);
CREATE INDEX idx_payments_order_status ON payments(order_id, status);
CREATE INDEX idx_history_order_date ON order_status_history(order_id, changed_at DESC);
-- Covering index for the common pending-work queue.
CREATE INDEX idx_orders_pending_queue ON orders(ordered_at, order_id, customer_id, fulfillment_location_id)
WHERE status IN ('pending','confirmed','processing');
