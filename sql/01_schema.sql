CREATE SCHEMA IF NOT EXISTS operations;
SET search_path = operations, public;

CREATE TYPE order_status AS ENUM ('pending','confirmed','processing','shipped','delivered','cancelled');
CREATE TYPE payment_status AS ENUM ('pending','authorized','paid','failed','refunded');
CREATE TYPE shipment_status AS ENUM ('pending','packed','in_transit','delivered','returned');

CREATE TABLE departments (
    department_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_code VARCHAR(20) NOT NULL UNIQUE,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE employees (
    employee_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department_id BIGINT NOT NULL REFERENCES departments(department_id),
    manager_id BIGINT REFERENCES employees(employee_id),
    active BOOLEAN NOT NULL DEFAULT true,
    hired_at DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT employee_email_lower_ck CHECK (email = lower(email))
);

CREATE TABLE locations (
    location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_code VARCHAR(30) NOT NULL UNIQUE,
    location_name VARCHAR(120) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(40),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    active BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT customer_email_lower_ck CHECK (email = lower(email))
);

CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_code VARCHAR(30) NOT NULL UNIQUE,
    category_name VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(40) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category_id BIGINT NOT NULL REFERENCES categories(category_id),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    reorder_level INTEGER NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE inventory (
    location_id BIGINT NOT NULL REFERENCES locations(location_id),
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0 AND quantity_reserved <= quantity_on_hand),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (location_id, product_id)
);

CREATE TABLE orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number VARCHAR(40) NOT NULL UNIQUE,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
    assigned_employee_id BIGINT REFERENCES employees(employee_id),
    fulfillment_location_id BIGINT REFERENCES locations(location_id),
    status order_status NOT NULL DEFAULT 'pending',
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    requested_delivery_date DATE,
    notes TEXT,
    CONSTRAINT delivery_date_ck CHECK (requested_delivery_date IS NULL OR requested_delivery_date >= ordered_at::date)
);

CREATE TABLE order_items (
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL CHECK (line_number > 0),
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    PRIMARY KEY (order_id, line_number),
    CONSTRAINT item_discount_ck CHECK (discount_amount <= quantity * unit_price)
);

CREATE TABLE payments (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(30) NOT NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    transaction_reference VARCHAR(100) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(order_id),
    tracking_number VARCHAR(100) UNIQUE,
    carrier VARCHAR(80),
    status shipment_status NOT NULL DEFAULT 'pending',
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    CONSTRAINT shipment_dates_ck CHECK (delivered_at IS NULL OR shipped_at IS NOT NULL AND delivered_at >= shipped_at)
);

CREATE TABLE order_status_history (
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    old_status order_status,
    new_status order_status NOT NULL,
    changed_by BIGINT REFERENCES employees(employee_id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT
);

CREATE OR REPLACE FUNCTION audit_order_status_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history(order_id, old_status, new_status, changed_by, reason)
        VALUES (NEW.order_id, CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE OLD.status END, NEW.status, NULL, 'Automatic status audit');
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER orders_status_audit_trg
AFTER INSERT OR UPDATE OF status ON orders
FOR EACH ROW EXECUTE FUNCTION audit_order_status_change();
