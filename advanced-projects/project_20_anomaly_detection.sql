-- Standart sapma kullanarak aykırı değerleri tespit edin
WITH daily_sales AS (
    SELECT 
        DATE(o.order_date) AS order_day,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)
    GROUP BY order_day
),
sales_stats AS (
    SELECT 
        AVG(daily_revenue) AS avg_revenue,
        STDDEV(daily_revenue) AS stddev_revenue,
        AVG(order_count) AS avg_orders,
        STDDEV(order_count) AS stddev_orders
    FROM daily_sales
)
SELECT 
    ds.order_day,
    ds.order_count,
    ds.daily_revenue,
    ss.avg_orders,
    ss.stddev_orders,
    ss.avg_revenue,
    ss.stddev_revenue,
    -- Z-Score hesaplama (standart normalleştirilmiş değerler)
    ROUND((ds.order_count - ss.avg_orders) / NULLIF(ss.stddev_orders, 0), 2) AS order_count_z_score,
    ROUND((ds.daily_revenue - ss.avg_revenue) / NULLIF(ss.stddev_revenue, 0), 2) AS revenue_z_score,
    -- Anomali tespiti (Z-Score > 2 veya Z-Score < -2)
    CASE 
        WHEN ABS((ds.order_count - ss.avg_orders) / NULLIF(ss.stddev_orders, 0)) > 2 THEN 'Anomaly'
        ELSE 'Normal'
    END AS order_count_status,
    CASE 
        WHEN ABS((ds.daily_revenue - ss.avg_revenue) / NULLIF(ss.stddev_revenue, 0)) > 2 THEN 'Anomaly'
        ELSE 'Normal'
    END AS revenue_status
FROM daily_sales ds
CROSS JOIN sales_stats ss
ORDER BY ABS(revenue_z_score) DESC;

-- Mevsimsel beklentilerden sapmaları ölçün
WITH daily_sales AS (
    SELECT 
        DATE(o.order_date) AS order_day,
        DAYOFWEEK(o.order_date) AS day_of_week, -- 1 = Pazar, 2 = Pazartesi, ..., 7 = Cumartesi
        MONTH(o.order_date) AS month,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
    GROUP BY order_day, day_of_week, month
),
day_of_week_avg AS (
    SELECT 
        day_of_week,
        AVG(order_count) AS avg_orders_by_day,
        STDDEV(order_count) AS stddev_orders_by_day,
        AVG(daily_revenue) AS avg_revenue_by_day,
        STDDEV(daily_revenue) AS stddev_revenue_by_day
    FROM daily_sales
    GROUP BY day_of_week
),
monthly_avg AS (
    SELECT 
        month,
        AVG(order_count) AS avg_orders_by_month,
        STDDEV(order_count) AS stddev_orders_by_month,
        AVG(daily_revenue) AS avg_revenue_by_month,
        STDDEV(daily_revenue) AS stddev_revenue_by_month
    FROM daily_sales
    GROUP BY month
)
SELECT 
    ds.order_day,
    ds.day_of_week,
    ds.month,
    ds.order_count,
    ds.daily_revenue,
    dwa.avg_orders_by_day,
    dwa.avg_revenue_by_day,
    ma.avg_orders_by_month,
    ma.avg_revenue_by_month,
    -- Haftanın günü bazında Z-Scores
    ROUND((ds.order_count - dwa.avg_orders_by_day) / NULLIF(dwa.stddev_orders_by_day, 0), 2) AS order_z_score_by_day,
    ROUND((ds.daily_revenue - dwa.avg_revenue_by_day) / NULLIF(dwa.stddev_revenue_by_day, 0), 2) AS revenue_z_score_by_day,
    -- Ay bazında Z-Scores
    ROUND((ds.order_count - ma.avg_orders_by_month) / NULLIF(ma.stddev_orders_by_month, 0), 2) AS order_z_score_by_month,
    ROUND((ds.daily_revenue - ma.avg_revenue_by_month) / NULLIF(ma.stddev_revenue_by_month, 0), 2) AS revenue_z_score_by_month,
    -- Anomali tespiti (haftanın günü ve ay faktörlerine göre)
    CASE 
        WHEN ABS((ds.order_count - dwa.avg_orders_by_day) / NULLIF(dwa.stddev_orders_by_day, 0)) > 2 
          OR ABS((ds.order_count - ma.avg_orders_by_month) / NULLIF(ma.stddev_orders_by_month, 0)) > 2 THEN 'Anomaly'
        ELSE 'Normal'
    END AS order_seasonality_status,
    CASE 
        WHEN ABS((ds.daily_revenue - dwa.avg_revenue_by_day) / NULLIF(dwa.stddev_revenue_by_day, 0)) > 2 
          OR ABS((ds.daily_revenue - ma.avg_revenue_by_month) / NULLIF(ma.stddev_revenue_by_month, 0)) > 2 THEN 'Anomaly'
        ELSE 'Normal'
    END AS revenue_seasonality_status
FROM daily_sales ds
JOIN day_of_week_avg dwa ON ds.day_of_week = dwa.day_of_week
JOIN monthly_avg ma ON ds.month = ma.month
WHERE ds.order_day >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
ORDER BY 
    GREATEST(
        ABS((ds.order_count - dwa.avg_orders_by_day) / NULLIF(dwa.stddev_orders_by_day, 0)),
        ABS((ds.daily_revenue - dwa.avg_revenue_by_day) / NULLIF(dwa.stddev_revenue_by_day, 0)),
        ABS((ds.order_count - ma.avg_orders_by_month) / NULLIF(ma.stddev_orders_by_month, 0)),
        ABS((ds.daily_revenue - ma.avg_revenue_by_month) / NULLIF(ma.stddev_revenue_by_month, 0))
    ) DESC;

-- Dolandırıcılık olabilecek işlemleri belirleyin
WITH payment_stats AS (
    SELECT 
        p.payment_method,
        AVG(p.amount) AS avg_amount,
        STDDEV(p.amount) AS stddev_amount,
        COUNT(*) AS payment_count
    FROM payments p
    JOIN orders o ON p.order_id = o.order_id
    WHERE p.status = 'completed'
      AND o.status NOT IN ('cancelled')
      AND p.payment_date >= DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)
    GROUP BY p.payment_method
),
customer_payment_stats AS (
    SELECT 
        c.customer_id,
        p.payment_method,
        AVG(p.amount) AS avg_customer_amount,
        MAX(p.amount) AS max_customer_amount,
        COUNT(*) AS customer_payment_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    WHERE p.status = 'completed'
      AND o.status NOT IN ('cancelled')
      AND p.payment_date >= DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)
    GROUP BY c.customer_id, p.payment_method
),
suspicious_payments AS (
    SELECT 
        p.payment_id,
        p.order_id,
        o.customer_id,
        p.payment_method,
        p.amount,
        p.payment_date,
        ps.avg_amount,
        ps.stddev_amount,
        cps.avg_customer_amount,
        cps.max_customer_amount,
        -- Z-Score hesaplama
        (p.amount - ps.avg_amount) / NULLIF(ps.stddev_amount, 0) AS amount_z_score,
        -- Müşterinin ortalama ödeme miktarına göre oran
        p.amount / NULLIF(cps.avg_customer_amount, 0) AS customer_amount_ratio,
        -- Dolandırıcılık şüphesi skorlama
        CASE 
            WHEN (p.amount - ps.avg_amount) / NULLIF(ps.stddev_amount, 0) > 3 THEN 3
            WHEN (p.amount - ps.avg_amount) / NULLIF(ps.stddev_amount, 0) > 2 THEN 2
            ELSE 0
        END +
        CASE 
            WHEN p.amount / NULLIF(cps.avg_customer_amount, 0) > 3 THEN 3
            WHEN p.amount / NULLIF(cps.avg_customer_amount, 0) > 2 THEN 2
            ELSE 0
        END +
        CASE 
            WHEN p.amount > cps.max_customer_amount * 1.5 THEN 2
            WHEN p.amount > cps.max_customer_amount * 1.2 THEN 1
            ELSE 0
        END AS fraud_score
    FROM payments p
    JOIN orders o ON p.order_id = o.order_id
    JOIN payment_stats ps ON p.payment_method = ps.payment_method
    JOIN customer_payment_stats cps ON o.customer_id = cps.customer_id AND p.payment_method = cps.payment_method
    WHERE p.status = 'completed'
      AND o.status NOT IN ('cancelled')
      AND p.payment_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
      AND cps.customer_payment_count > 1
)
SELECT 
    payment_id,
    order_id,
    customer_id,
    payment_method,
    amount,
    payment_date,
    avg_amount AS method_avg_amount,
    stddev_amount AS method_stddev_amount,
    avg_customer_amount,
    max_customer_amount,
    ROUND(amount_z_score, 2) AS amount_z_score,
    ROUND(customer_amount_ratio, 2) AS customer_amount_ratio,
    fraud_score,
    CASE 
        WHEN fraud_score >= 5 THEN 'High Risk'
        WHEN fraud_score >= 3 THEN 'Medium Risk'
        WHEN fraud_score >= 1 THEN 'Low Risk'
        ELSE 'Normal'
    END AS risk_category
FROM suspicious_payments
WHERE fraud_score > 0
ORDER BY fraud_score DESC;

-- Sistemdeki hataları gösteren veri kalıplarını tespit edin
WITH order_anomalies AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_date,
        COUNT(oi.order_item_id) AS item_count,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.unit_price * oi.quantity) AS order_total,
        MAX(oi.unit_price) AS max_item_price,
        MIN(oi.unit_price) AS min_item_price,
        COUNT(DISTINCT oi.product_id) AS unique_products,
        MAX(p.amount) AS payment_amount,
        -- Potansiyel anormallikler
        CASE WHEN COUNT(oi.order_item_id) = 0 THEN 1 ELSE 0 END AS no_items,
        CASE WHEN SUM(oi.quantity) = 0 THEN 1 ELSE 0 END AS zero_quantity,
        CASE WHEN SUM(oi.unit_price * oi.quantity) <= 0 THEN 1 ELSE 0 END AS non_positive_total,
        CASE WHEN MAX(oi.unit_price) = 0 THEN 1 ELSE 0 END AS zero_price,
        CASE WHEN ABS(SUM(oi.unit_price * oi.quantity) - MAX(p.amount)) > 1 THEN 1 ELSE 0 END AS payment_mismatch,
        CASE WHEN COUNT(p.payment_id) = 0 THEN 1 ELSE 0 END AS no_payment,
        CASE WHEN COUNT(p.payment_id) > 1 AND MAX(p.amount) <> SUM(oi.unit_price * oi.quantity) THEN 1 ELSE 0 END AS multiple_payments_mismatch
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN payments p ON o.order_id = p.order_id
    WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY o.order_id, o.customer_id, o.order_date
),
inventory_anomalies AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.price,
        p.cost,
        p.stock_quantity,
        SUM(oi.quantity) AS ordered_quantity,
        -- Potansiyel anormallikler
        CASE WHEN p.price < p.cost THEN 1 ELSE 0 END AS price_below_cost,
        CASE WHEN p.price = 0 THEN 1 ELSE 0 END AS zero_price,
        CASE WHEN p.stock_quantity < 0 THEN 1 ELSE 0 END AS negative_stock,
        CASE WHEN SUM(oi.quantity) > p.stock_quantity * 3 THEN 1 ELSE 0 END AS excessive_orders
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) OR o.order_date IS NULL
    GROUP BY p.product_id, p.product_name, p.price, p.cost, p.stock_quantity
)
SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with no items' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE no_items = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with zero quantity' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE zero_quantity = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with non-positive total' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE non_positive_total = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with zero price items' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE zero_price = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with payment mismatch' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE payment_mismatch = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with no payment' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE no_payment = 1

UNION ALL

SELECT 'Order Anomalies' AS anomaly_category, 
       'Orders with multiple payments mismatch' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM order_anomalies
WHERE multiple_payments_mismatch = 1

UNION ALL

SELECT 'Inventory Anomalies' AS anomaly_category, 
       'Products with price below cost' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM inventory_anomalies
WHERE price_below_cost = 1

UNION ALL

SELECT 'Inventory Anomalies' AS anomaly_category, 
       'Products with zero price' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM inventory_anomalies
WHERE zero_price = 1

UNION ALL

SELECT 'Inventory Anomalies' AS anomaly_category, 
       'Products with negative stock' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM inventory_anomalies
WHERE negative_stock = 1

UNION ALL

SELECT 'Inventory Anomalies' AS anomaly_category, 
       'Products with excessive orders vs stock' AS anomaly_type, 
       COUNT(*) AS anomaly_count
FROM inventory_anomalies
WHERE excessive_orders = 1

ORDER BY anomaly_category, anomaly_count DESC;