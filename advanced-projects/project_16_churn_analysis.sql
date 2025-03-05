-- Churn oranını hesaplayın
-- Aktif müşteriler: Son 90 gün içinde alışveriş yapanlar
-- Churn eden müşteriler: 90-180 gün önce alışveriş yapıp, son 90 gün içinde alışveriş yapmayanlar
WITH active_customers AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY c.customer_id
),
churned_customers AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY) AND DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
      AND c.customer_id NOT IN (SELECT customer_id FROM active_customers)
    GROUP BY c.customer_id
),
total_customers AS (
    SELECT 
        COUNT(DISTINCT c.customer_id) AS total_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)
)
SELECT 
    (SELECT COUNT(*) FROM active_customers) AS active_customers,
    (SELECT COUNT(*) FROM churned_customers) AS churned_customers,
    (SELECT total_count FROM total_customers) AS total_customers,
    ROUND((SELECT COUNT(*) FROM churned_customers) * 100.0 / 
          (SELECT total_count FROM total_customers), 2) AS churn_rate
FROM dual;

-- Müşteri kaybı öncesi davranış kalıplarını belirleyin
WITH churned_customers AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY) AND DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
      AND c.customer_id NOT IN (
          SELECT DISTINCT c2.customer_id
          FROM customers c2
          JOIN orders o2 ON c2.customer_id = o2.customer_id
          WHERE o2.status NOT IN ('cancelled')
            AND o2.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
      )
    GROUP BY c.customer_id
),
churned_behavior AS (
    SELECT 
        cc.customer_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.unit_price * oi.quantity) AS total_spent,
        SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.order_id) AS avg_order_value,
        MAX(DATEDIFF(cc.last_order_date, MIN(o.order_date)) / 30) AS customer_lifetime_months,
        COUNT(DISTINCT CASE WHEN r.return_id IS NOT NULL THEN r.return_id END) AS return_count,
        COUNT(DISTINCT CASE WHEN r.return_id IS NOT NULL THEN r.return_id END) * 100.0 / 
            COUNT(DISTINCT o.order_id) AS return_rate,
        AVG(DATEDIFF(o.order_date, LAG(o.order_date) OVER (PARTITION BY cc.customer_id ORDER BY o.order_date))) AS avg_days_between_orders
    FROM churned_customers cc
    JOIN orders o ON cc.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN returns r ON o.order_id = r.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY cc.customer_id
)
SELECT 
    AVG(total_orders) AS avg_orders_before_churn,
    AVG(total_spent) AS avg_total_spent,
    AVG(avg_order_value) AS avg_order_value,
    AVG(customer_lifetime_months) AS avg_lifetime_months,
    AVG(return_rate) AS avg_return_rate,
    AVG(avg_days_between_orders) AS avg_purchase_frequency_days
FROM churned_behavior;

-- Demografik faktörlere göre churn oranlarını karşılaştırın
WITH active_customers AS (
    SELECT 
        c.customer_id,
        c.country,
        c.city,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY c.customer_id, c.country, c.city
),
churned_customers AS (
    SELECT 
        c.customer_id,
        c.country,
        c.city,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date BETWEEN DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY) AND DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
      AND c.customer_id NOT IN (SELECT customer_id FROM active_customers)
    GROUP BY c.customer_id, c.country, c.city
),
total_customers AS (
    SELECT 
        c.country,
        c.city,
        COUNT(DISTINCT c.customer_id) AS total_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 180 DAY)
    GROUP BY c.country, c.city
)
SELECT 
    tc.country,
    tc.city,
    tc.total_count AS total_customers,
    COUNT(DISTINCT ac.customer_id) AS active_customers,
    COUNT(DISTINCT cc.customer_id) AS churned_customers,
    ROUND(COUNT(DISTINCT cc.customer_id) * 100.0 / tc.total_count, 2) AS churn_rate
FROM total_customers tc
LEFT JOIN active_customers ac ON tc.country = ac.country AND tc.city = ac.city
LEFT JOIN churned_customers cc ON tc.country = cc.country AND tc.city = cc.city
GROUP BY tc.country, tc.city, tc.total_count
HAVING tc.total_count > 10
ORDER BY churn_rate DESC;

-- En risk altındaki müşterileri tespit edin
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS total_spent,
        AVG(DATEDIFF(o.order_date, LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date))) AS avg_days_between_orders,
        COUNT(DISTINCT CASE WHEN r.return_id IS NOT NULL THEN r.return_id END) AS return_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN returns r ON o.order_id = r.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, customer_name
    HAVING order_count > 1
      AND days_since_last_order BETWEEN 60 AND 90
)
SELECT 
    customer_id,
    customer_name,
    last_order_date,
    days_since_last_order,
    order_count,
    total_spent,
    avg_days_between_orders,
    -- Eğer müşterinin ortalama sipariş frekansı aşıldıysa risk yüksek
    CASE WHEN days_since_last_order > avg_days_between_orders * 1.5 THEN 'High Risk'
         WHEN days_since_last_order > avg_days_between_orders * 1.2 THEN 'Medium Risk'
         ELSE 'Low Risk'
    END AS churn_risk
FROM customer_activity
ORDER BY days_since_last_order DESC, avg_days_between_orders ASC;