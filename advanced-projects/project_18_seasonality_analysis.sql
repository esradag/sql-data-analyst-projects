
-- ######################################################
-- ############### PROJE 18: MEVSİMSELLİK VE TREND ANALİZİ ###############
-- ######################################################

-- Yıllık, çeyreklik ve aylık trendleri hesaplayın
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_date,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        QUARTER(o.order_date) AS quarter,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY month_date, year, month, quarter
    ORDER BY month_date
),
moving_avg AS (
    SELECT 
        month_date,
        year,
        month,
        quarter,
        order_count,
        total_revenue,
        -- 3 aylık hareketli ortalama
        AVG(total_revenue) OVER (ORDER BY month_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS revenue_3_month_ma,
        -- 12 aylık hareketli ortalama
        AVG(total_revenue) OVER (ORDER BY month_date ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS revenue_12_month_ma
    FROM monthly_sales
)
SELECT 
    month_date,
    year,
    month,
    quarter,
    order_count,
    total_revenue,
    revenue_3_month_ma,
    revenue_12_month_ma,
    -- Yıllık büyüme oranı
    ROUND((total_revenue - LAG(total_revenue, 12) OVER (ORDER BY month_date)) * 100.0 / 
          NULLIF(LAG(total_revenue, 12) OVER (ORDER BY month_date), 0), 2) AS yoy_growth
FROM moving_avg
ORDER BY month_date;

-- Mevsimsel faktörleri izole edin
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_date,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.unit_price * oi.quantity) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY month_date, year, month
    ORDER BY month_date
),
yearly_averages AS (
    SELECT 
        year,
        AVG(total_revenue) AS avg_yearly_revenue
    FROM monthly_sales
    GROUP BY year
),
seasonal_indices AS (
    SELECT 
        ms.month,
        AVG(ms.total_revenue / ya.avg_yearly_revenue) AS seasonal_index
    FROM monthly_sales ms
    JOIN yearly_averages ya ON ms.year = ya.year
    GROUP BY ms.month
)
SELECT 
    month,
    ROUND(seasonal_index, 2) AS seasonal_index,
    ROUND((seasonal_index - 1) * 100, 2) AS seasonal_impact_pct
FROM seasonal_indices
ORDER BY month;

-- Trend ve mevsimsellik etkisini çıkararak temel performansı ölçün
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_date,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.unit_price * oi.quantity) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY month_date, year, month
    ORDER BY month_date
),
yearly_averages AS (
    SELECT 
        year,
        AVG(total_revenue) AS avg_yearly_revenue
    FROM monthly_sales
    GROUP BY year
),
seasonal_indices AS (
    SELECT 
        ms.month,
        AVG(ms.total_revenue / ya.avg_yearly_revenue) AS seasonal_index
    FROM monthly_sales ms
    JOIN yearly_averages ya ON ms.year = ya.year
    GROUP BY ms.month
),
deseasonalized_sales AS (
    SELECT 
        ms.month_date,
        ms.year,
        ms.month,
        ms.total_revenue,
        si.seasonal_index,
        ms.total_revenue / si.seasonal_index AS deseasonalized_revenue
    FROM monthly_sales ms
    JOIN seasonal_indices si ON ms.month = si.month
)
SELECT 
    month_date,
    year,
    month,
    total_revenue,
    seasonal_index,
    ROUND(deseasonalized_revenue, 2) AS deseasonalized_revenue,
    -- Deseasonalized trendleri ölçme
    ROUND(AVG(deseasonalized_revenue) OVER (ORDER BY month_date ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING), 2) AS trend_component
FROM deseasonalized_sales
ORDER BY month_date;

-- Gelecek dönemler için tahminleme yapın
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_date,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.unit_price * oi.quantity) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
      AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 36 MONTH)
    GROUP BY month_date, year, month
    ORDER BY month_date
),
yearly_averages AS (
    SELECT 
        year,
        AVG(total_revenue) AS avg_yearly_revenue
    FROM monthly_sales
    GROUP BY year
),
growth_rates AS (
    SELECT 
        ya.year,
        ya.avg_yearly_revenue,
        LAG(ya.avg_yearly_revenue) OVER (ORDER BY ya.year) AS prev_year_revenue,
        (ya.avg_yearly_revenue - LAG(ya.avg_yearly_revenue) OVER (ORDER BY ya.year)) / 
        LAG(ya.avg_yearly_revenue) OVER (ORDER BY ya.year) AS yoy_growth_rate
    FROM yearly_averages ya
),
avg_growth_rate AS (
    SELECT AVG(yoy_growth_rate) AS avg_growth
    FROM growth_rates
    WHERE yoy_growth_rate IS NOT NULL
),
seasonal_indices AS (
    SELECT 
        ms.month,
        AVG(ms.total_revenue / ya.avg_yearly_revenue) AS seasonal_index
    FROM monthly_sales ms
    JOIN yearly_averages ya ON ms.year = ya.year
    GROUP BY ms.month
),
latest_year_avg AS (
    SELECT 
        MAX(year) AS latest_year,
        (SELECT avg_yearly_revenue FROM yearly_averages WHERE year = MAX(ms.year)) AS latest_avg_revenue
    FROM monthly_sales ms
),
future_months AS (
    SELECT 
        ADDDATE(
            (SELECT STR_TO_DATE(CONCAT(latest_year, '-12-01'), '%Y-%m-%d') FROM latest_year_avg),
            INTERVAL n MONTH
        ) AS future_month_date,
        YEAR(
            ADDDATE(
                (SELECT STR_TO_DATE(CONCAT(latest_year, '-12-01'), '%Y-%m-%d') FROM latest_year_avg),
                INTERVAL n MONTH
            )
        ) AS future_year,
        MONTH(
            ADDDATE(
                (SELECT STR_TO_DATE(CONCAT(latest_year, '-12-01'), '%Y-%m-%d') FROM latest_year_avg),
                INTERVAL n MONTH
            )
        ) AS future_month
    FROM (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
        SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION
        SELECT 11 UNION SELECT 12
    ) numbers
)
SELECT 
    fm.future_month_date,
    fm.future_year,
    fm.future_month,
    si.seasonal_index,
    lya.latest_avg_revenue,
    agr.avg_growth,
    -- Tahmini gelir = Son yıl ortalaması * (1 + Ortalama büyüme oranı) * Mevsimsel endeks
    ROUND(
        lya.latest_avg_revenue * 
        (1 + (CASE WHEN fm.future_year > lya.latest_year THEN agr.avg_growth ELSE 0 END)) * 
        si.seasonal_index,
        2
    ) AS predicted_revenue
FROM future_months fm
JOIN seasonal_indices si ON fm.future_month = si.month
CROSS JOIN latest_year_avg lya
CROSS JOIN avg_growth_rate agr
ORDER BY fm.future_month_date;
