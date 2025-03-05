-- En çok satan ürünleri belirleyin
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.unit_price * oi.quantity) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 20;

-- Kar marjı en yüksek ürünleri tespit edin
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.unit_price * oi.quantity) AS total_revenue,
    SUM(p.cost * oi.quantity) AS total_cost,
    SUM(oi.unit_price * oi.quantity - p.cost * oi.quantity) AS total_profit,
    ROUND((SUM(oi.unit_price * oi.quantity - p.cost * oi.quantity) / SUM(oi.unit_price * oi.quantity)) * 100, 2) AS profit_margin
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name
HAVING total_quantity_sold > 10
ORDER BY profit_margin DESC
LIMIT 20;

-- Düşük performanslı ürünleri tanımlayın
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    SUM(oi.quantity) AS total_quantity_sold,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.unit_price * oi.quantity) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status NOT IN ('cancelled')
GROUP BY p.product_id, p.product_name, p.category_id
HAVING total_quantity_sold < 5 OR total_quantity_sold IS NULL
ORDER BY total_quantity_sold ASC, total_revenue ASC;

-- Satış ve stok devir hızını hesaplayın
WITH monthly_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.quantity) AS quantity_sold
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY p.product_id, p.product_name, year, month
),
avg_inventory AS (
    SELECT 
        p.product_id,
        p.product_name,
        AVG(p.stock_quantity) AS avg_stock
    FROM products p
    GROUP BY p.product_id, p.product_name
)
SELECT 
    ms.product_id,
    ms.product_name,
    SUM(ms.quantity_sold) AS annual_sales,
    ai.avg_stock,
    ROUND(SUM(ms.quantity_sold) / ai.avg_stock, 2) AS inventory_turnover
FROM monthly_sales ms
JOIN avg_inventory ai ON ms.product_id = ai.product_id
WHERE ms.year = YEAR(CURRENT_DATE) - 1
GROUP BY ms.product_id, ms.product_name, ai.avg_stock
HAVING ai.avg_stock > 0
ORDER BY inventory_turnover DESC;