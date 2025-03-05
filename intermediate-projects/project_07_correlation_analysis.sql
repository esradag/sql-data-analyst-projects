-- Fiyat ve satış hacmi arasındaki ilişkiyi analiz edin
SELECT 
    p.product_id,
    p.product_name,
    p.price,
    COUNT(oi.order_item_id) AS total_orders,
    SUM(oi.quantity) AS total_quantity
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name, p.price
ORDER BY p.price, total_quantity DESC;

-- Kampanya dönemleri ile satış artışı arasındaki korelasyonu bulun
SELECT 
    c.campaign_id,
    c.campaign_name,
    DATE(c.start_date) AS campaign_start,
    DATE(c.end_date) AS campaign_end,
    COUNT(DISTINCT o.order_id) AS total_orders_during_campaign,
    SUM(oi.quantity) AS total_items_sold,
    SUM(oi.unit_price * oi.quantity) AS total_revenue
FROM campaigns c
JOIN campaign_products cp ON c.campaign_id = cp.campaign_id
JOIN order_items oi ON cp.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date BETWEEN c.start_date AND c.end_date
  AND o.status NOT IN ('cancelled')
GROUP BY c.campaign_id, c.campaign_name, campaign_start, campaign_end
ORDER BY total_revenue DESC;

-- Demografik faktörler ile satın alma davranışı arasındaki ilişkileri araştırın
SELECT 
    c.city,
    c.country,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer,
    SUM(oi.unit_price * oi.quantity) AS total_revenue,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY c.city, c.country
HAVING customer_count > 5
ORDER BY revenue_per_customer DESC;

-- Ürün görüntülenme sayısı ile satış oranı arasındaki ilişkiyi inceleyin
SELECT 
    csd.product_id,
    p.product_name,
    COUNT(CASE WHEN csd.event_type = 'product_view' THEN csd.click_id END) AS view_count,
    COUNT(CASE WHEN csd.event_type = 'add_to_cart' THEN csd.click_id END) AS add_to_cart_count,
    COUNT(CASE WHEN csd.event_type = 'purchase' THEN csd.click_id END) AS purchase_count,
    ROUND(COUNT(CASE WHEN csd.event_type = 'add_to_cart' THEN csd.click_id END) * 100.0 / 
          NULLIF(COUNT(CASE WHEN csd.event_type = 'product_view' THEN csd.click_id END), 0), 2) AS view_to_cart_rate,
    ROUND(COUNT(CASE WHEN csd.event_type = 'purchase' THEN csd.click_id END) * 100.0 / 
          NULLIF(COUNT(CASE WHEN csd.event_type = 'add_to_cart' THEN csd.click_id END), 0), 2) AS cart_to_purchase_rate,
    ROUND(COUNT(CASE WHEN csd.event_type = 'purchase' THEN csd.click_id END) * 100.0 / 
          NULLIF(COUNT(CASE WHEN csd.event_type = 'product_view' THEN csd.click_id END), 0), 2) AS view_to_purchase_rate
FROM click_stream_data csd
JOIN products p ON csd.product_id = p.product_id
WHERE csd.product_id IS NOT NULL
GROUP BY csd.product_id, p.product_name
HAVING view_count > 100
ORDER BY view_to_purchase_rate DESC;