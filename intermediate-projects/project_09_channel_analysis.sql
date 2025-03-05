-- Kanal bazında satış hacmi ve gelir ölçümü
SELECT 
    o.order_source AS channel,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS total_items_sold,
    SUM(oi.unit_price * oi.quantity) AS total_revenue,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.order_id), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY channel
ORDER BY total_revenue DESC;

-- Kanal bazında müşteri edinim maliyetini hesaplama
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada kampanya maliyetleri ayrı bir tabloda tutulabilir.
WITH channel_costs AS (
    -- Örnek kanal maliyet verileri
    SELECT 'web' AS channel, 5000 AS marketing_cost UNION ALL
    SELECT 'mobile', 7500 UNION ALL
    SELECT 'store', 3000
)
SELECT 
    o.order_source AS channel,
    cc.marketing_cost,
    COUNT(DISTINCT c.customer_id) AS new_customers,
    ROUND(cc.marketing_cost / COUNT(DISTINCT c.customer_id), 2) AS customer_acquisition_cost
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN channel_costs cc ON o.order_source = cc.channel
WHERE o.status NOT IN ('cancelled')
  AND o.order_id = (
      SELECT MIN(o2.order_id) 
      FROM orders o2 
      WHERE o2.customer_id = o.customer_id
  )
GROUP BY channel, cc.marketing_cost
ORDER BY customer_acquisition_cost;

-- Kanallar arası dönüşüm oranlarını karşılaştırma
SELECT 
    csd.referral_source AS channel,
    COUNT(DISTINCT csd.visitor_id) AS total_visitors,
    COUNT(DISTINCT CASE WHEN csd.event_type = 'product_view' THEN csd.visitor_id END) AS product_viewers,
    COUNT(DISTINCT CASE WHEN csd.event_type = 'add_to_cart' THEN csd.visitor_id END) AS cart_adders,
    COUNT(DISTINCT CASE WHEN csd.event_type = 'checkout' THEN csd.visitor_id END) AS checkout_starters,
    COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN csd.visitor_id END) AS purchasers,
    ROUND(COUNT(DISTINCT CASE WHEN csd.event_type = 'product_view' THEN csd.visitor_id END) * 100.0 / 
          COUNT(DISTINCT csd.visitor_id), 2) AS visit_to_product_rate,
    ROUND(COUNT(DISTINCT CASE WHEN csd.event_type = 'add_to_cart' THEN csd.visitor_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CASE WHEN csd.event_type = 'product_view' THEN csd.visitor_id END), 0), 2) AS product_to_cart_rate,
    ROUND(COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN csd.visitor_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CASE WHEN csd.event_type = 'add_to_cart' THEN csd.visitor_id END), 0), 2) AS cart_to_purchase_rate,
    ROUND(COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN csd.visitor_id END) * 100.0 / 
          COUNT(DISTINCT csd.visitor_id), 2) AS overall_conversion_rate
FROM click_stream_data csd
WHERE csd.referral_source IS NOT NULL
GROUP BY channel
HAVING total_visitors > 100
ORDER BY overall_conversion_rate DESC;

-- Kanallar arasında müşteri değeri farklılıklarını analiz etme
SELECT 
    o.order_source AS channel,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
    ROUND(AVG(oi.unit_price * oi.quantity), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY channel
ORDER BY revenue_per_customer DESC;