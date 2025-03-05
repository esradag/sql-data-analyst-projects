-- Aylık ve çeyreklik satış toplamlarını hesaplayın
-- Aylık satış
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.unit_price * oi.quantity) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year, month
ORDER BY year DESC, month DESC;

-- Çeyreklik satış
SELECT 
    YEAR(o.order_date) AS year,
    QUARTER(o.order_date) AS quarter,
    SUM(oi.unit_price * oi.quantity) AS quarterly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year, quarter
ORDER BY year DESC, quarter DESC;

-- Yıllık büyüme oranlarını belirleyin
WITH yearly_revenue AS (
    SELECT 
        YEAR(o.order_date) AS year,
        SUM(oi.unit_price * oi.quantity) AS annual_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year
)
SELECT 
    yr.year,
    yr.annual_revenue,
    LAG(yr.annual_revenue) OVER (ORDER BY yr.year) AS prev_year_revenue,
    ROUND((yr.annual_revenue - LAG(yr.annual_revenue) OVER (ORDER BY yr.year)) * 100.0 / 
          LAG(yr.annual_revenue) OVER (ORDER BY yr.year), 2) AS yoy_growth
FROM yearly_revenue yr
ORDER BY yr.year;

-- Mevsimsel satış kalıplarını tespit edin
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.unit_price * oi.quantity) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year, month
ORDER BY month, year;

-- Bir önceki yılın aynı dönemine göre performans karşılaştırması yapın
WITH monthly_revenue AS (
    SELECT 
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.unit_price * oi.quantity) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY year, month
)
SELECT 
    mr.year,
    mr.month,
    mr.monthly_revenue,
    LAG(mr.monthly_revenue) OVER (PARTITION BY mr.month ORDER BY mr.year) AS prev_year_revenue,
    ROUND((mr.monthly_revenue - LAG(mr.monthly_revenue) OVER (PARTITION BY mr.month ORDER BY mr.year)) * 100.0 / 
          LAG(mr.monthly_revenue) OVER (PARTITION BY mr.month ORDER BY mr.year), 2) AS yoy_growth
FROM monthly_revenue mr
ORDER BY mr.year DESC, mr.month;