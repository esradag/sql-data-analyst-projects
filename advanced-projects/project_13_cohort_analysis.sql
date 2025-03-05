-- Aylık müşteri kohortları oluşturun
WITH customer_first_purchase AS (
    SELECT 
        c.customer_id,
        MIN(DATE_FORMAT(o.order_date, '%Y-%m-01')) AS cohort_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id
),
customer_activity AS (
    SELECT 
        cfp.customer_id,
        cfp.cohort_date,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        TIMESTAMPDIFF(MONTH, cfp.cohort_date, DATE_FORMAT(o.order_date, '%Y-%m-01')) AS month_number
    FROM customer_first_purchase cfp
    JOIN orders o ON cfp.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY cfp.customer_id, cfp.cohort_date, order_month, month_number
),
cohort_size AS (
    SELECT 
        cohort_date,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM customer_first_purchase
    GROUP BY cohort_date
),
retention_table AS (
    SELECT 
        ca.cohort_date,
        ca.month_number,
        COUNT(DISTINCT ca.customer_id) AS num_customers
    FROM customer_activity ca
    GROUP BY ca.cohort_date, ca.month_number
)
SELECT 
    rt.cohort_date,
    cs.num_customers AS cohort_size,
    rt.month_number,
    rt.num_customers AS remaining_customers,
    ROUND(rt.num_customers * 100.0 / cs.num_customers, 2) AS retention_rate
FROM retention_table rt
JOIN cohort_size cs ON rt.cohort_date = cs.cohort_date
ORDER BY rt.cohort_date, rt.month_number;

-- Zaman içinde kohort performansını karşılaştırın
WITH customer_first_purchase AS (
    SELECT 
        c.customer_id,
        MIN(DATE_FORMAT(o.order_date, '%Y-%m-01')) AS cohort_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id
),
customer_activity AS (
    SELECT 
        cfp.customer_id,
        cfp.cohort_date,
        SUM(oi.unit_price * oi.quantity) AS customer_revenue
    FROM customer_first_purchase cfp
    JOIN orders o ON cfp.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY cfp.customer_id, cfp.cohort_date
)
SELECT 
    cohort_date,
    COUNT(DISTINCT customer_id) AS cohort_size,
    ROUND(AVG(customer_revenue), 2) AS avg_revenue_per_customer,
    ROUND(SUM(customer_revenue), 2) AS total_cohort_revenue,
    ROUND(SUM(customer_revenue) / COUNT(DISTINCT customer_id), 2) AS avg_ltv
FROM customer_activity
GROUP BY cohort_date
ORDER BY cohort_date;

-- Kohorta göre LTV değişimini analiz edin
WITH customer_first_purchase AS (
    SELECT 
        c.customer_id,
        MIN(DATE_FORMAT(o.order_date, '%Y-%m-01')) AS cohort_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id
),
monthly_revenue AS (
    SELECT 
        cfp.customer_id,
        cfp.cohort_date,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        TIMESTAMPDIFF(MONTH, cfp.cohort_date, DATE_FORMAT(o.order_date, '%Y-%m-01')) AS month_number,
        SUM(oi.unit_price * oi.quantity) AS monthly_revenue
    FROM customer_first_purchase cfp
    JOIN orders o ON cfp.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY cfp.customer_id, cfp.cohort_date, order_month, month_number
),
cumulative_revenue AS (
    SELECT 
        cohort_date,
        month_number,
        SUM(monthly_revenue) AS total_revenue,
        COUNT(DISTINCT customer_id) AS active_customers,
        SUM(SUM(monthly_revenue)) OVER (PARTITION BY cohort_date ORDER BY month_number) AS cumulative_revenue
    FROM monthly_revenue
    GROUP BY cohort_date, month_number
),
cohort_size AS (
    SELECT 
        cohort_date,
        COUNT(DISTINCT customer_id) AS num_customers
    FROM customer_first_purchase
    GROUP BY cohort_date
)
SELECT 
    cr.cohort_date,
    cs.num_customers AS cohort_size,
    cr.month_number,
    cr.active_customers,
    cr.total_revenue,
    cr.cumulative_revenue,
    ROUND(cr.cumulative_revenue / cs.num_customers, 2) AS avg_cumulative_ltv
FROM cumulative_revenue cr
JOIN cohort_size cs ON cr.cohort_date = cs.cohort_date
ORDER BY cr.cohort_date, cr.month_number;