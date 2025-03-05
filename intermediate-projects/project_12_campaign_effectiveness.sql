-- Kampanya öncesi ve sonrası satış karşılaştırması
SELECT 
    c.campaign_id,
    c.campaign_name,
    DATE(c.start_date) AS campaign_start,
    DATE(c.end_date) AS campaign_end,
    DATEDIFF(c.end_date, c.start_date) AS campaign_duration_days,
    
    -- Kampanya öncesi satışlar (kampanya süresi kadar gün)
    (SELECT SUM(oi.unit_price * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN DATE_SUB(c.start_date, INTERVAL DATEDIFF(c.end_date, c.start_date) DAY) AND DATE_SUB(c.start_date, INTERVAL 1 DAY)
       AND o.status NOT IN ('cancelled')) AS pre_campaign_revenue,
    
    -- Kampanya sırasındaki satışlar
    (SELECT SUM(oi.unit_price * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN c.start_date AND c.end_date
       AND o.status NOT IN ('cancelled')) AS during_campaign_revenue,
       
    -- Kampanya sonrası satışlar (kampanya süresi kadar gün)
    (SELECT SUM(oi.unit_price * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN DATE_ADD(c.end_date, INTERVAL 1 DAY) AND DATE_ADD(c.end_date, INTERVAL DATEDIFF(c.end_date, c.start_date) DAY)
       AND o.status NOT IN ('cancelled')) AS post_campaign_revenue,
       
    -- Kampanya etkisi (yüzde değişim)
    ROUND(((SELECT SUM(oi.unit_price * oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN campaign_products cp ON oi.product_id = cp.product_id
            WHERE cp.campaign_id = c.campaign_id
              AND o.order_date BETWEEN c.start_date AND c.end_date
              AND o.status NOT IN ('cancelled')) - 
           (SELECT SUM(oi.unit_price * oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN campaign_products cp ON oi.product_id = cp.product_id
            WHERE cp.campaign_id = c.campaign_id
              AND o.order_date BETWEEN DATE_SUB(c.start_date, INTERVAL DATEDIFF(c.end_date, c.start_date) DAY) AND DATE_SUB(c.start_date, INTERVAL 1 DAY)
              AND o.status NOT IN ('cancelled'))) * 100.0 / 
          NULLIF((SELECT SUM(oi.unit_price * oi.quantity)
                 FROM order_items oi
                 JOIN orders o ON oi.order_id = o.order_id
                 JOIN campaign_products cp ON oi.product_id = cp.product_id
                 WHERE cp.campaign_id = c.campaign_id
                   AND o.order_date BETWEEN DATE_SUB(c.start_date, INTERVAL DATEDIFF(c.end_date, c.start_date) DAY) AND DATE_SUB(c.start_date, INTERVAL 1 DAY)
                   AND o.status NOT IN ('cancelled')), 0), 2) AS campaign_impact_percent
FROM campaigns c
WHERE c.status = 'finished'
ORDER BY campaign_impact_percent DESC;

-- ROI (Yatırım Getirisi) hesaplama
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.budget AS campaign_cost,
    
    -- Kampanya sırasındaki satışlar
    (SELECT SUM(oi.unit_price * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN c.start_date AND c.end_date
       AND o.status NOT IN ('cancelled')) AS campaign_revenue,
       
    -- Ürün maliyetleri
    (SELECT SUM(p.cost * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     JOIN products p ON oi.product_id = p.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN c.start_date AND c.end_date
       AND o.status NOT IN ('cancelled')) AS product_costs,
       
    -- Kampanya karı
    (SELECT SUM(oi.unit_price * oi.quantity) - SUM(p.cost * oi.quantity)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN campaign_products cp ON oi.product_id = cp.product_id
     JOIN products p ON oi.product_id = p.product_id
     WHERE cp.campaign_id = c.campaign_id
       AND o.order_date BETWEEN c.start_date AND c.end_date
       AND o.status NOT IN ('cancelled')) AS campaign_profit,
       
    -- ROI hesaplama
    ROUND(((SELECT SUM(oi.unit_price * oi.quantity) - SUM(p.cost * oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            JOIN campaign_products cp ON oi.product_id = cp.product_id
            JOIN products p ON oi.product_id = p.product_id
            WHERE cp.campaign_id = c.campaign_id
              AND o.order_date BETWEEN c.start_date AND c.end_date
              AND o.status NOT IN ('cancelled')) - c.budget) * 100.0 / c.budget, 2) AS roi_percent
FROM campaigns c
WHERE c.status = 'finished' AND c.budget > 0
ORDER BY roi_percent DESC;

-- Kampanya türüne göre müşteri tepkilerini analiz etme
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada kampanya türü bilgisi gerekir.
WITH campaign_types AS (
    -- Örnek kampanya türleri
    SELECT 1 AS campaign_id, 'discount' AS campaign_type UNION ALL
    SELECT 2 AS campaign_id, 'bundle' AS campaign_type UNION ALL
    SELECT 3 AS campaign_id, 'flash_sale' AS campaign_type
)
SELECT 
    ct.campaign_type,
    COUNT(DISTINCT c.campaign_id) AS campaign_count,
    COUNT(DISTINCT o.customer_id) AS customer_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(oi.unit_price * oi.quantity), 2) AS avg_order_value,
    SUM(oi.unit_price * oi.quantity) AS total_revenue,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT c.campaign_id), 2) AS avg_revenue_per_campaign,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.customer_id), 2) AS avg_revenue_per_customer
FROM campaign_types ct
JOIN campaigns c ON ct.campaign_id = c.campaign_id
JOIN campaign_products cp ON c.campaign_id = cp.campaign_id
JOIN order_items oi ON cp.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date BETWEEN c.start_date AND c.end_date
  AND o.status NOT IN ('cancelled')
GROUP BY ct.campaign_type
ORDER BY avg_revenue_per_campaign DESC;

-- En etkili kampanya türlerini belirleme
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada kampanya türü bilgisi gerekir.
WITH campaign_types AS (
    -- Örnek kampanya türleri
    SELECT 1 AS campaign_id, 'discount' AS campaign_type UNION ALL
    SELECT 2 AS campaign_id, 'bundle' AS campaign_type UNION ALL
    SELECT 3 AS campaign_id, 'flash_sale' AS campaign_type
),
campaign_metrics AS (
    SELECT 
        ct.campaign_type,
        c.campaign_id,
        c.budget,
        
        -- Kampanya öncesi satışlar (7 gün)
        (SELECT SUM(oi.unit_price * oi.quantity)
         FROM order_items oi
         JOIN orders o ON oi.order_id = o.order_id
         JOIN campaign_products cp ON oi.product_id = cp.product_id
         WHERE cp.campaign_id = c.campaign_id
           AND o.order_date BETWEEN DATE_SUB(c.start_date, INTERVAL 7 DAY) AND DATE_SUB(c.start_date, INTERVAL 1 DAY)
           AND o.status NOT IN ('cancelled')) AS pre_campaign_revenue,
        
        -- Kampanya sırasındaki satışlar
        (SELECT SUM(oi.unit_price * oi.quantity)
         FROM order_items oi
         JOIN orders o ON oi.order_id = o.order_id
         JOIN campaign_products cp ON oi.product_id = cp.product_id
         WHERE cp.campaign_id = c.campaign_id
           AND o.order_date BETWEEN c.start_date AND c.end_date
           AND o.status NOT IN ('cancelled')) AS during_campaign_revenue
    FROM campaign_types ct
    JOIN campaigns c ON ct.campaign_id = c.campaign_id
    WHERE c.status = 'finished'
)
SELECT 
    campaign_type,
    COUNT(*) AS campaign_count,
    SUM(budget) AS total_budget,
    SUM(pre_campaign_revenue) AS total_pre_revenue,
    SUM(during_campaign_revenue) AS total_during_revenue,
    ROUND((SUM(during_campaign_revenue) - SUM(pre_campaign_revenue)) * 100.0 / 
          NULLIF(SUM(pre_campaign_revenue), 0), 2) AS avg_revenue_increase_percent,
    ROUND((SUM(during_campaign_revenue) - SUM(pre_campaign_revenue) - SUM(budget)) * 100.0 / 
          SUM(budget), 2) AS avg_roi_percent
FROM campaign_metrics
GROUP BY campaign_type
ORDER BY avg_roi_percent DESC;