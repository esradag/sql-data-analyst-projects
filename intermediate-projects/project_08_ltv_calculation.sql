-- Ortalama sipariş değerini hesaplayın
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.unit_price * oi.quantity) AS total_revenue,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY c.customer_id, customer_name
HAVING order_count > 1
ORDER BY avg_order_value DESC;

-- Sipariş sıklığını belirleyin
WITH customer_orders AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS order_number
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
)
SELECT 
    co.customer_id,
    co.customer_name,
    COUNT(*) + 1 AS order_count,
    MIN(DATEDIFF(co2.order_date, co.order_date)) AS min_days_between_orders,
    MAX(DATEDIFF(co2.order_date, co.order_date)) AS max_days_between_orders,
    AVG(DATEDIFF(co2.order_date, co.order_date)) AS avg_days_between_orders,
    ROUND(365 / AVG(DATEDIFF(co2.order_date, co.order_date)), 2) AS purchase_frequency_per_year
FROM customer_orders co
JOIN customer_orders co2 ON co.customer_id = co2.customer_id 
                         AND co.order_number = co2.order_number - 1
GROUP BY co.customer_id, co.customer_name
HAVING order_count > 2
ORDER BY purchase_frequency_per_year DESC;

-- Müşteri elde tutma oranını hesaplayın
WITH customer_yearly_orders AS (
    SELECT 
        c.customer_id,
        YEAR(o.order_date) AS order_year,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, order_year
),
yearly_retention AS (
    SELECT 
        cyo1.order_year AS base_year,
        cyo1.order_year + 1 AS retention_year,
        COUNT(DISTINCT cyo1.customer_id) AS base_year_customers,
        COUNT(DISTINCT CASE WHEN cyo2.customer_id IS NOT NULL THEN cyo1.customer_id END) AS retained_customers
    FROM customer_yearly_orders cyo1
    LEFT JOIN customer_yearly_orders cyo2 ON cyo1.customer_id = cyo2.customer_id 
                                         AND cyo1.order_year + 1 = cyo2.order_year
    GROUP BY base_year, retention_year
)
SELECT 
    base_year,
    retention_year,
    base_year_customers,
    retained_customers,
    ROUND(retained_customers * 100.0 / base_year_customers, 2) AS retention_rate
FROM yearly_retention
ORDER BY base_year DESC;

-- Bu faktörleri kullanarak LTV'yi hesaplayın
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        -- Ortalama sipariş değeri
        ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
        -- Satın alma sıklığı (yıllık)
        COUNT(DISTINCT o.order_id) / 
            NULLIF(DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / 365, 0) AS purchase_frequency,
        -- Müşteri ömrü (yıl)
        DATEDIFF(CURRENT_DATE, MIN(o.order_date)) / 365 AS customer_lifespan
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, customer_name
    HAVING COUNT(DISTINCT o.order_id) > 1
)
SELECT 
    customer_id,
    customer_name,
    avg_order_value,
    purchase_frequency,
    customer_lifespan,
    -- LTV = Ortalama Sipariş Değeri × Satın Alma Sıklığı × Müşteri Ömrü
    ROUND(avg_order_value * purchase_frequency * customer_lifespan, 2) AS customer_lifetime_value
FROM customer_metrics
ORDER BY customer_lifetime_value DESC;