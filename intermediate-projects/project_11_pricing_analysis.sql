-- Fiyat değişikliklerinin satış hacmine etkisini ölçün
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada fiyat değişim geçmişini tutan bir tablo gerekir.
WITH price_changes AS (
    -- Örnek fiyat değişim verileri
    SELECT 1 AS product_id, 100.00 AS old_price, 80.00 AS new_price, '2023-01-15' AS change_date UNION ALL
    SELECT 2 AS product_id, 50.00 AS old_price, 55.00 AS new_price, '2023-02-10' AS change_date UNION ALL
    SELECT 3 AS product_id, 200.00 AS old_price, 180.00 AS new_price, '2023-03-05' AS change_date
)
SELECT 
    pc.product_id,
    p.product_name,
    pc.old_price,
    pc.new_price,
    ROUND((pc.new_price - pc.old_price) * 100.0 / pc.old_price, 2) AS price_change_percent,
    
    -- Fiyat değişimi öncesi satış verileri (30 gün)
    (SELECT SUM(oi.quantity) 
     FROM order_items oi 
     JOIN orders o ON oi.order_id = o.order_id 
     WHERE oi.product_id = pc.product_id 
       AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
       AND o.status NOT IN ('cancelled')) AS sales_before,
       
    -- Fiyat değişimi sonrası satış verileri (30 gün)
    (SELECT SUM(oi.quantity) 
     FROM order_items oi 
     JOIN orders o ON oi.order_id = o.order_id 
     WHERE oi.product_id = pc.product_id 
       AND o.order_date BETWEEN pc.change_date AND DATE_ADD(pc.change_date, INTERVAL 30 DAY)
       AND o.status NOT IN ('cancelled')) AS sales_after,
       
    -- Satış değişim yüzdesi
    ROUND(((SELECT SUM(oi.quantity) 
            FROM order_items oi 
            JOIN orders o ON oi.order_id = o.order_id 
            WHERE oi.product_id = pc.product_id 
              AND o.order_date BETWEEN pc.change_date AND DATE_ADD(pc.change_date, INTERVAL 30 DAY)
              AND o.status NOT IN ('cancelled')) - 
           (SELECT SUM(oi.quantity) 
            FROM order_items oi 
            JOIN orders o ON oi.order_id = o.order_id 
            WHERE oi.product_id = pc.product_id 
              AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
              AND o.status NOT IN ('cancelled'))) * 100.0 / 
          NULLIF((SELECT SUM(oi.quantity) 
                 FROM order_items oi 
                 JOIN orders o ON oi.order_id = o.order_id 
                 WHERE oi.product_id = pc.product_id 
                   AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
                   AND o.status NOT IN ('cancelled')), 0), 2) AS sales_change_percent
FROM price_changes pc
JOIN products p ON pc.product_id = p.product_id
ORDER BY sales_change_percent DESC;

-- Fiyat elastikiyetini hesaplayın
-- Fiyat Elastikiyeti = (Talep Değişimi %) / (Fiyat Değişimi %)
WITH price_changes AS (
    -- Örnek fiyat değişim verileri
    SELECT 1 AS product_id, 100.00 AS old_price, 80.00 AS new_price, '2023-01-15' AS change_date UNION ALL
    SELECT 2 AS product_id, 50.00 AS old_price, 55.00 AS new_price, '2023-02-10' AS change_date UNION ALL
    SELECT 3 AS product_id, 200.00 AS old_price, 180.00 AS new_price, '2023-03-05' AS change_date
),
sales_data AS (
    SELECT 
        pc.product_id,
        p.product_name,
        pc.old_price,
        pc.new_price,
        ROUND((pc.new_price - pc.old_price) * 100.0 / pc.old_price, 2) AS price_change_percent,
        
        -- Fiyat değişimi öncesi satış verileri (30 gün)
        (SELECT SUM(oi.quantity) 
         FROM order_items oi 
         JOIN orders o ON oi.order_id = o.order_id 
         WHERE oi.product_id = pc.product_id 
           AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
           AND o.status NOT IN ('cancelled')) AS sales_before,
           
        -- Fiyat değişimi sonrası satış verileri (30 gün)
        (SELECT SUM(oi.quantity) 
         FROM order_items oi 
         JOIN orders o ON oi.order_id = o.order_id 
         WHERE oi.product_id = pc.product_id 
           AND o.order_date BETWEEN pc.change_date AND DATE_ADD(pc.change_date, INTERVAL 30 DAY)
           AND o.status NOT IN ('cancelled')) AS sales_after,
           
        -- Satış değişim yüzdesi
        ROUND(((SELECT SUM(oi.quantity) 
                FROM order_items oi 
                JOIN orders o ON oi.order_id = o.order_id 
                WHERE oi.product_id = pc.product_id 
                  AND o.order_date BETWEEN pc.change_date AND DATE_ADD(pc.change_date, INTERVAL 30 DAY)
                  AND o.status NOT IN ('cancelled')) - 
               (SELECT SUM(oi.quantity) 
                FROM order_items oi 
                JOIN orders o ON oi.order_id = o.order_id 
                WHERE oi.product_id = pc.product_id 
                  AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
                  AND o.status NOT IN ('cancelled'))) * 100.0 / 
              NULLIF((SELECT SUM(oi.quantity) 
                     FROM order_items oi 
                     JOIN orders o ON oi.order_id = o.order_id 
                     WHERE oi.product_id = pc.product_id 
                       AND o.order_date BETWEEN DATE_SUB(pc.change_date, INTERVAL 30 DAY) AND pc.change_date
                       AND o.status NOT IN ('cancelled')), 0), 2) AS sales_change_percent
    FROM price_changes pc
    JOIN products p ON pc.product_id = p.product_id
)
SELECT 
    product_id,
    product_name,
    old_price,
    new_price,
    price_change_percent,
    sales_before,
    sales_after,
    sales_change_percent,
    -- Fiyat elastikiyeti hesaplama
    ROUND(ABS(sales_change_percent / NULLIF(price_change_percent, 0)), 2) AS price_elasticity,
    -- Elastikiyete göre sınıflandırma
    CASE 
        WHEN ABS(sales_change_percent / NULLIF(price_change_percent, 0)) > 1 THEN 'Elastik'
        WHEN ABS(sales_change_percent / NULLIF(price_change_percent, 0)) < 1 THEN 'İnelastik'
        ELSE 'Birim Elastik'
    END AS elasticity_type
FROM sales_data
ORDER BY price_elasticity DESC;

-- Optimal fiyat noktalarını belirleyin
WITH price_elasticity AS (
    -- Varsayılan elastiklik verileri
    SELECT 
        p.product_id,
        p.product_name,
        p.price AS current_price,
        p.cost,
        -- Örnek elastiklik değeri
        1.5 AS elasticity_value
    FROM products p
    WHERE p.price > p.cost
)
SELECT 
    pe.product_id,
    pe.product_name,
    pe.current_price,
    pe.cost,
    pe.elasticity_value,
    -- Kâr maksimizasyon formülü (elastik talep için)
    -- Optimal Fiyat = (Elastiklik * Maliyet) / (Elastiklik - 1)
    ROUND(pe.elasticity_value * pe.cost / (pe.elasticity_value - 1), 2) AS optimal_price,
    -- Mevcut fiyat ile optimal fiyat arasındaki fark
    ROUND(((pe.elasticity_value * pe.cost / (pe.elasticity_value - 1)) - pe.current_price) * 100.0 / pe.current_price, 2) AS suggested_price_change_percent
FROM price_elasticity pe
WHERE pe.elasticity_value > 1 -- Sadece elastik ürünler için
ORDER BY suggested_price_change_percent DESC;

-- Rakip fiyatları ile karşılaştırmalı analiz yapın
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada rakip fiyatlarını tutan bir tablo gerekir.
WITH competitor_prices AS (
    -- Örnek rakip fiyat verileri
    SELECT 1 AS product_id, 'Competitor A' AS competitor_name, 95.00 AS competitor_price UNION ALL
    SELECT 1 AS product_id, 'Competitor B' AS competitor_name, 105.00 AS competitor_price UNION ALL
    SELECT 2 AS product_id, 'Competitor A' AS competitor_name, 48.00 AS competitor_price UNION ALL
    SELECT 2 AS product_id, 'Competitor B' AS competitor_name, 52.00 AS competitor_price UNION ALL
    SELECT 3 AS product_id, 'Competitor A' AS competitor_name, 190.00 AS competitor_price UNION ALL
    SELECT 3 AS product_id, 'Competitor B' AS competitor_name, 185.00 AS competitor_price
)
SELECT 
    p.product_id,
    p.product_name,
    p.price AS our_price,
    cp.competitor_name,
    cp.competitor_price,
    ROUND((p.price - cp.competitor_price) * 100.0 / cp.competitor_price, 2) AS price_difference_percent,
    CASE 
        WHEN p.price > cp.competitor_price THEN 'Higher'
        WHEN p.price < cp.competitor_price THEN 'Lower'
        ELSE 'Same'
    END AS price_position,
    p.cost,
    ROUND((p.price - p.cost) * 100.0 / p.price, 2) AS our_margin_percent,
    ROUND((cp.competitor_price - p.cost) * 100.0 / cp.competitor_price, 2) AS competitor_margin_percent
FROM products p
JOIN competitor_prices cp ON p.product_id = cp.product_id
ORDER BY p.product_id, cp.competitor_name;