-- Stok tükenmesi yaşanan ürünleri tespit edin
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    SUM(oi.quantity) AS ordered_quantity,
    COUNT(DISTINCT o.order_id) AS order_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE p.stock_quantity <= 10
  AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
  AND o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY (ordered_quantity / p.stock_quantity) DESC;

-- Aşırı stoklu ürünleri belirleyin
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    SUM(CASE WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN oi.quantity ELSE 0 END) AS last_90_days_sales,
    ROUND(SUM(CASE WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN oi.quantity ELSE 0 END) / 3, 0) AS monthly_sales_rate,
    p.stock_quantity / NULLIF(ROUND(SUM(CASE WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN oi.quantity ELSE 0 END) / 3, 0), 0) AS months_of_inventory
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name, p.stock_quantity
HAVING monthly_sales_rate > 0 AND months_of_inventory > 6
ORDER BY months_of_inventory DESC;

-- Optimal sipariş miktarı için analiz yapın
-- Economic Order Quantity (EOQ) formülü kullanılarak hesaplanacak
-- EOQ = SQRT((2 * D * S) / H)
-- D = Yıllık talep, S = Sipariş maliyeti, H = Birim başına yıllık stok tutma maliyeti
WITH product_demand AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.price,
        p.cost,
        p.stock_quantity,
        SUM(CASE WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY) THEN oi.quantity ELSE 0 END) AS annual_demand
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status NOT IN ('cancelled')
    GROUP BY p.product_id, p.product_name, p.price, p.cost, p.stock_quantity
)
SELECT 
    pd.product_id,
    pd.product_name,
    pd.annual_demand,
    pd.stock_quantity AS current_stock,
    -- Varsayım: Sipariş maliyeti tüm ürünler için 20 birim
    20 AS ordering_cost,
    -- Varsayım: Yıllık stok tutma maliyeti ürün maliyetinin %25'i
    ROUND(pd.cost * 0.25, 2) AS holding_cost,
    -- EOQ hesaplama
    ROUND(SQRT((2 * pd.annual_demand * 20) / (pd.cost * 0.25)), 0) AS economic_order_quantity
FROM product_demand pd
WHERE pd.annual_demand > 0
ORDER BY pd.annual_demand DESC;

-- Mevsimsel talep değişikliklerine göre stok planlaması
SELECT 
    p.product_id,
    p.product_name,
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.quantity) AS monthly_quantity_sold,
    AVG(SUM(oi.quantity)) OVER (PARTITION BY p.product_id, MONTH(o.order_date)) AS avg_monthly_sales,
    p.stock_quantity AS current_stock,
    -- Bir sonraki ay için tahmini stok ihtiyacı (geçmiş 2 yılın ortalamasının %20 üzerinde)
    ROUND(AVG(SUM(oi.quantity)) OVER (PARTITION BY p.product_id, MONTH(o.order_date)) * 1.2, 0) AS estimated_next_month_need
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled')
  AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 2 YEAR)
GROUP BY p.product_id, p.product_name, year, month, p.stock_quantity
ORDER BY p.product_id, year, month;