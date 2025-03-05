-- RFM metriklerini hesaplayın
WITH rfm_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        -- Recency: Son alışveriş tarihinden bugüne kadar geçen gün sayısı
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS recency,
        -- Frequency: Toplam sipariş sayısı
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Monetary: Toplam harcama
        SUM(oi.unit_price * oi.quantity) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    recency,
    frequency,
    monetary
FROM rfm_metrics
ORDER BY recency;

-- RFM skorlarını hesaplayıp müşterileri segmentlere ayırın
WITH rfm_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        -- Recency: Son alışveriş tarihinden bugüne kadar geçen gün sayısı
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS recency,
        -- Frequency: Toplam sipariş sayısı
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Monetary: Toplam harcama
        SUM(oi.unit_price * oi.quantity) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, customer_name
),
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        recency,
        frequency,
        monetary,
        -- Recency skoru (küçük değerler daha iyi)
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        -- Frequency skoru (büyük değerler daha iyi)
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        -- Monetary skoru (büyük değerler daha iyi)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_metrics
)
SELECT 
    customer_id,
    customer_name,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE 
        WHEN (r_score >= 4 AND f_score >= 4 AND m_score >= 4) THEN 'Champions'
        WHEN (r_score >= 3 AND f_score >= 3 AND m_score >= 3) THEN 'Loyal Customers'
        WHEN (r_score >= 3 AND f_score >= 1 AND m_score >= 2) THEN 'Potential Loyalists'
        WHEN (r_score = 5 AND f_score < 2 AND m_score < 2) THEN 'New Customers'
        WHEN (r_score >= 4 AND f_score <= 2 AND m_score <= 2) THEN 'Promising'
        WHEN (r_score >= 3 AND f_score <= 2 AND m_score <= 2) THEN 'Need Attention'
        WHEN (r_score <= 2 AND f_score >= 2 AND m_score >= 2) THEN 'At Risk'
        WHEN (r_score <= 2 AND f_score >= 3 AND m_score >= 3) THEN 'Can\'t Lose Them'
        WHEN (r_score <= 1 AND f_score <= 2 AND m_score <= 2) THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM rfm_scores
ORDER BY segment, monetary DESC;

-- Segment özeti ve segment başına müşteri değeri
WITH rfm_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.unit_price * oi.quantity) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, customer_name
),
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_metrics
),
rfm_segments AS (
    SELECT 
        customer_id,
        customer_name,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        CASE 
            WHEN (r_score >= 4 AND f_score >= 4 AND m_score >= 4) THEN 'Champions'
            WHEN (r_score >= 3 AND f_score >= 3 AND m_score >= 3) THEN 'Loyal Customers'
            WHEN (r_score >= 3 AND f_score >= 1 AND m_score >= 2) THEN 'Potential Loyalists'
            WHEN (r_score = 5 AND f_score < 2 AND m_score < 2) THEN 'New Customers'
            WHEN (r_score >= 4 AND f_score <= 2 AND m_score <= 2) THEN 'Promising'
            WHEN (r_score >= 3 AND f_score <= 2 AND m_score <= 2) THEN 'Need Attention'
            WHEN (r_score <= 2 AND f_score >= 2 AND m_score >= 2) THEN 'At Risk'
            WHEN (r_score <= 2 AND f_score >= 3 AND m_score >= 3) THEN 'Can\'t Lose Them'
            WHEN (r_score <= 1 AND f_score <= 2 AND m_score <= 2) THEN 'Lost'
            ELSE 'Others'
        END AS segment
    FROM rfm_scores
)
SELECT 
    segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency), 0) AS avg_recency_days,
    ROUND(AVG(frequency), 0) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_monetary,
    ROUND(SUM(monetary) / COUNT(*), 2) AS customer_value
FROM rfm_segments
GROUP BY segment
ORDER BY customer_value DESC;