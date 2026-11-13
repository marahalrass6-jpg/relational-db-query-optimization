SET search_path = operations, public;
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id BIGINT) RETURNS NUMERIC(14,2)
LANGUAGE SQL STABLE AS $$ SELECT COALESCE(SUM(quantity*unit_price-discount_amount),0)::NUMERIC(14,2) FROM order_items WHERE order_id=$1 $$;

CREATE OR REPLACE FUNCTION change_order_status(p_order_id BIGINT,p_new_status order_status,p_reason TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE orders SET status=p_new_status WHERE order_id=p_order_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Order % does not exist',p_order_id; END IF;
  UPDATE order_status_history SET reason=COALESCE(p_reason,reason)
   WHERE history_id=(SELECT history_id FROM order_status_history WHERE order_id=p_order_id ORDER BY changed_at DESC,history_id DESC LIMIT 1);
END $$;

CREATE OR REPLACE PROCEDURE reserve_inventory(p_location_id BIGINT,p_product_id BIGINT,p_quantity INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_available INTEGER;
BEGIN
  IF p_quantity <= 0 THEN RAISE EXCEPTION 'Quantity must be positive'; END IF;
  SELECT quantity_on_hand-quantity_reserved INTO v_available FROM inventory WHERE location_id=p_location_id AND product_id=p_product_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Inventory record not found'; END IF;
  IF v_available < p_quantity THEN RAISE EXCEPTION 'Insufficient inventory: available %, requested %',v_available,p_quantity; END IF;
  UPDATE inventory SET quantity_reserved=quantity_reserved+p_quantity,updated_at=now() WHERE location_id=p_location_id AND product_id=p_product_id;
END $$;
