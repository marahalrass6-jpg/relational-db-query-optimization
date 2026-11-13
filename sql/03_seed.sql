SET search_path = operations, public;
INSERT INTO departments (department_code, department_name) VALUES
 ('OPS','Operations'),('SALES','Sales'),('FIN','Finance') ON CONFLICT DO NOTHING;
INSERT INTO employees (employee_number, first_name, last_name, email, department_id, hired_at)
SELECT 'EMP-001','Maya','Haddad','maya.haddad@example.com',department_id,'2021-03-15' FROM departments WHERE department_code='OPS'
ON CONFLICT DO NOTHING;
INSERT INTO employees (employee_number, first_name, last_name, email, department_id, hired_at)
SELECT 'EMP-002','Omar','Nasser','omar.nasser@example.com',department_id,'2022-07-01' FROM departments WHERE department_code='SALES'
ON CONFLICT DO NOTHING;
INSERT INTO locations (location_code, location_name, city, country_code) VALUES
 ('AMM-01','Amman Central Warehouse','Amman','JO'),('AQB-01','Aqaba Distribution Center','Aqaba','JO') ON CONFLICT DO NOTHING;
INSERT INTO customers (customer_number, first_name, last_name, email, phone) VALUES
 ('CUS-1001','Lina','Saleh','lina.saleh@example.com','+962790000001'),
 ('CUS-1002','Khaled','Yousef','khaled.yousef@example.com','+962790000002'),
 ('CUS-1003','Sara','Mansour','sara.mansour@example.com','+962790000003') ON CONFLICT DO NOTHING;
INSERT INTO categories (category_code, category_name) VALUES ('HW','Hardware'),('SW','Software'),('SRV','Services') ON CONFLICT DO NOTHING;
INSERT INTO products (sku, product_name, category_id, unit_price, reorder_level)
SELECT 'LAP-001','Business Laptop',category_id,899.00,8 FROM categories WHERE category_code='HW' ON CONFLICT DO NOTHING;
INSERT INTO products (sku, product_name, category_id, unit_price, reorder_level)
SELECT 'MON-001','27-inch Monitor',category_id,249.00,12 FROM categories WHERE category_code='HW' ON CONFLICT DO NOTHING;
INSERT INTO products (sku, product_name, category_id, unit_price, reorder_level)
SELECT 'LIC-001','Analytics License',category_id,149.00,20 FROM categories WHERE category_code='SW' ON CONFLICT DO NOTHING;
INSERT INTO inventory (location_id, product_id, quantity_on_hand, quantity_reserved)
SELECT l.location_id,p.product_id,40,5 FROM locations l CROSS JOIN products p WHERE l.location_code='AMM-01' ON CONFLICT (location_id,product_id) DO NOTHING;
INSERT INTO inventory (location_id, product_id, quantity_on_hand, quantity_reserved)
SELECT l.location_id,p.product_id,15,2 FROM locations l CROSS JOIN products p WHERE l.location_code='AQB-01' ON CONFLICT (location_id,product_id) DO NOTHING;
INSERT INTO orders (order_number, customer_id, assigned_employee_id, fulfillment_location_id, status, ordered_at, requested_delivery_date)
SELECT 'ORD-10001',c.customer_id,e.employee_id,l.location_id,'delivered','2026-01-10 10:00+03','2026-01-14' FROM customers c, employees e, locations l WHERE c.customer_number='CUS-1001' AND e.employee_number='EMP-002' AND l.location_code='AMM-01' ON CONFLICT DO NOTHING;
INSERT INTO orders (order_number, customer_id, assigned_employee_id, fulfillment_location_id, status, ordered_at, requested_delivery_date)
SELECT 'ORD-10002',c.customer_id,e.employee_id,l.location_id,'processing','2026-02-02 13:30+03','2026-02-06' FROM customers c, employees e, locations l WHERE c.customer_number='CUS-1002' AND e.employee_number='EMP-002' AND l.location_code='AQB-01' ON CONFLICT DO NOTHING;
INSERT INTO order_items (order_id,line_number,product_id,quantity,unit_price,discount_amount)
SELECT o.order_id,1,p.product_id,2,p.unit_price,20 FROM orders o,products p WHERE o.order_number='ORD-10001' AND p.sku='LAP-001' ON CONFLICT DO NOTHING;
INSERT INTO order_items (order_id,line_number,product_id,quantity,unit_price,discount_amount)
SELECT o.order_id,2,p.product_id,2,p.unit_price,0 FROM orders o,products p WHERE o.order_number='ORD-10001' AND p.sku='MON-001' ON CONFLICT DO NOTHING;
INSERT INTO order_items (order_id,line_number,product_id,quantity,unit_price,discount_amount)
SELECT o.order_id,1,p.product_id,3,p.unit_price,0 FROM orders o,products p WHERE o.order_number='ORD-10002' AND p.sku='LIC-001' ON CONFLICT DO NOTHING;
INSERT INTO payments (order_id,amount,payment_method,status,paid_at,transaction_reference)
SELECT o.order_id,2276.00,'card','paid','2026-01-10 10:05+03','TXN-10001' FROM orders o WHERE o.order_number='ORD-10001' ON CONFLICT DO NOTHING;
INSERT INTO shipments (order_id,tracking_number,carrier,status,shipped_at,delivered_at)
SELECT o.order_id,'TRK-10001','FastShip','delivered','2026-01-11 09:00+03','2026-01-13 16:00+03' FROM orders o WHERE o.order_number='ORD-10001' ON CONFLICT DO NOTHING;
