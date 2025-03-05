-- A/B testlerinin sonuçlarını değerlendirme
-- Not: Bu sorgu örnek bir senaryo için oluşturulmuştur. Gerçek uygulamada A/B test sonuçlarını tutan ayrı bir tablo gerekir.
WITH ab_test_data AS (
    -- Örnek A/B test verileri
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'A' AS variant, 'control' AS variant_desc UNION ALL
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'B' AS variant, 'new_design' AS variant_desc UNION ALL
    SELECT 2 AS test_id, 'Checkout Process' AS test_name, 'A' AS variant, 'multi_step' AS variant_desc UNION ALL
    SELECT 2 AS test_id, 'Checkout Process' AS test_name, 'B' AS variant, 'single_page' AS variant_desc
),
user_assignments AS (
    -- Varsayımsal kullanıcı atamaları
    SELECT 
        csd.visitor_id,
        CASE WHEN MOD(CAST(SUBSTRING(csd.visitor_id, 1, 8) AS UNSIGNED), 2) = 0 THEN 'A' ELSE 'B' END AS variant,
        COUNT(DISTINCT csd.session_id) AS session_count,
        SUM(CASE WHEN csd.event_type = 'page_view' THEN 1 ELSE 0 END) AS page_views,
        SUM(CASE WHEN csd.event_type = 'product_view' THEN 1 ELSE 0 END) AS product_views,
        SUM(CASE WHEN csd.event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_carts,
        SUM(CASE WHEN csd.event_type = 'checkout' THEN 1 ELSE 0 END) AS checkouts,
        SUM(CASE WHEN csd.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
    FROM click_stream_data csd
    WHERE csd.timestamp BETWEEN '2023-01-01' AND '2023-01-31'
    GROUP BY csd.visitor_id, variant
),
conversion_data AS (
    SELECT 
        abt.test_id,
        abt.test_name,
        ua.variant,
        abt.variant_desc,
        COUNT(DISTINCT ua.visitor_id) AS unique_visitors,
        SUM(ua.page_views) AS total_page_views,
        AVG(ua.page_views) AS avg_page_views_per_visitor,
        SUM(ua.product_views) AS total_product_views,
        SUM(ua.add_to_carts) AS total_add_to_carts,
        SUM(ua.checkouts) AS total_checkouts,
        SUM(ua.purchases) AS total_purchases,
        ROUND(SUM(ua.product_views) * 100.0 / COUNT(DISTINCT ua.visitor_id), 2) AS product_view_rate,
        ROUND(SUM(ua.add_to_carts) * 100.0 / NULLIF(SUM(ua.product_views), 0), 2) AS add_to_cart_rate,
        ROUND(SUM(ua.checkouts) * 100.0 / NULLIF(SUM(ua.add_to_carts), 0), 2) AS checkout_rate,
        ROUND(SUM(ua.purchases) * 100.0 / NULLIF(SUM(ua.checkouts), 0), 2) AS purchase_rate,
        ROUND(SUM(ua.purchases) * 100.0 / COUNT(DISTINCT ua.visitor_id), 2) AS overall_conversion_rate
    FROM ab_test_data abt
    JOIN user_assignments ua ON abt.variant = ua.variant
    GROUP BY abt.test_id, abt.test_name, ua.variant, abt.variant_desc
)
SELECT 
    test_id,
    test_name,
    variant,
    variant_desc,
    unique_visitors,
    total_page_views,
    avg_page_views_per_visitor,
    total_product_views,
    total_add_to_carts,
    total_checkouts,
    total_purchases,
    product_view_rate,
    add_to_cart_rate,
    checkout_rate,
    purchase_rate,
    overall_conversion_rate
FROM conversion_data
ORDER BY test_id, variant;

-- İstatistiksel anlamlılık testleri uygulayın
-- Z-testi kullanarak istatistiksel anlamlılık analizi
WITH ab_test_results AS (
    -- Örnek test sonuçları
    SELECT 
        1 AS test_id,
        'Homepage Redesign' AS test_name,
        'A' AS variant,
        10000 AS visitors,
        300 AS conversions
    UNION ALL
    SELECT 
        1 AS test_id,
        'Homepage Redesign' AS test_name,
        'B' AS variant,
        10000 AS visitors,
        350 AS conversions
),
variant_stats AS (
    SELECT 
        test_id,
        test_name,
        variant,
        visitors,
        conversions,
        conversions / visitors AS conversion_rate,
        SQRT((conversions / visitors) * (1 - (conversions / visitors)) / visitors) AS standard_error
    FROM ab_test_results
),
variant_pairs AS (
    SELECT 
        a.test_id,
        a.test_name,
        a.variant AS variant_a,
        b.variant AS variant_b,
        a.visitors AS visitors_a,
        b.visitors AS visitors_b,
        a.conversions AS conversions_a,
        b.conversions AS conversions_b,
        a.conversion_rate AS conversion_rate_a,
        b.conversion_rate AS conversion_rate_b,
        b.conversion_rate - a.conversion_rate AS absolute_difference,
        (b.conversion_rate - a.conversion_rate) / a.conversion_rate * 100 AS relative_difference
    FROM variant_stats a
    JOIN variant_stats b ON a.test_id = b.test_id AND a.variant < b.variant
)
SELECT 
    test_id,
    test_name,
    variant_a,
    variant_b,
    ROUND(conversion_rate_a * 100, 2) AS conversion_rate_a_pct,
    ROUND(conversion_rate_b * 100, 2) AS conversion_rate_b_pct,
    ROUND(absolute_difference * 100, 2) AS absolute_difference_pct,
    ROUND(relative_difference, 2) AS relative_difference_pct,
    -- Z-score = (conversion_rate_b - conversion_rate_a) / SQRT(standard_error_a^2 + standard_error_b^2)
    ROUND(
        (conversion_rate_b - conversion_rate_a) / 
        SQRT(
            (conversion_rate_a * (1 - conversion_rate_a) / visitors_a) + 
            (conversion_rate_b * (1 - conversion_rate_b) / visitors_b)
        ),
        2
    ) AS z_score,
    -- p-value yorumlaması (yaklaşık değerler, tam p-değeri için ayrı hesaplama gerekir)
    CASE 
        WHEN ABS(
            (conversion_rate_b - conversion_rate_a) / 
            SQRT(
                (conversion_rate_a * (1 - conversion_rate_a) / visitors_a) + 
                (conversion_rate_b * (1 - conversion_rate_b) / visitors_b)
            )
        ) > 1.96 THEN 'Significant (p < 0.05)'
        WHEN ABS(
            (conversion_rate_b - conversion_rate_a) / 
            SQRT(
                (conversion_rate_a * (1 - conversion_rate_a) / visitors_a) + 
                (conversion_rate_b * (1 - conversion_rate_b) / visitors_b)
            )
        ) > 1.64 THEN 'Marginally Significant (p < 0.10)'
        ELSE 'Not Significant (p >= 0.10)'
    END AS significance,
    -- Minimum gerekli örneklem büyüklüğü
    CEILING(
        16 * (conversion_rate_a * (1 - conversion_rate_a) + conversion_rate_b * (1 - conversion_rate_b)) / 
        POWER(absolute_difference, 2)
    ) AS required_sample_size
FROM variant_pairs;

-- Segment bazında test sonuçlarını analiz edin
WITH ab_test_data AS (
    -- Örnek A/B test verileri
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'A' AS variant, 'control' AS variant_desc UNION ALL
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'B' AS variant, 'new_design' AS variant_desc
),
user_segments AS (
    -- Kullanıcı segmentleri oluşturma
    SELECT 
        csd.visitor_id,
        CASE WHEN MOD(CAST(SUBSTRING(csd.visitor_id, 1, 8) AS UNSIGNED), 2) = 0 THEN 'A' ELSE 'B' END AS variant,
        CASE 
            WHEN csd.device_type = 'mobile' THEN 'Mobile'
            WHEN csd.device_type = 'tablet' THEN 'Tablet'
            ELSE 'Desktop'
        END AS device_segment,
        CASE 
            WHEN c.country IN ('USA', 'Canada') THEN 'North America'
            WHEN c.country IN ('UK', 'France', 'Germany', 'Spain', 'Italy') THEN 'Europe'
            ELSE 'Other'
        END AS region_segment,
        COUNT(DISTINCT csd.session_id) AS session_count,
        SUM(CASE WHEN csd.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
    FROM click_stream_data csd
    LEFT JOIN customers c ON csd.customer_id = c.customer_id
    WHERE csd.timestamp BETWEEN '2023-01-01' AND '2023-01-31'
    GROUP BY csd.visitor_id, variant, device_segment, region_segment
),
segment_conversion AS (
    SELECT 
        abt.test_id,
        abt.test_name,
        us.variant,
        abt.variant_desc,
        us.device_segment,
        us.region_segment,
        COUNT(DISTINCT us.visitor_id) AS unique_visitors,
        SUM(us.purchases) AS purchases,
        ROUND(SUM(us.purchases) * 100.0 / COUNT(DISTINCT us.visitor_id), 2) AS conversion_rate
    FROM ab_test_data abt
    JOIN user_segments us ON abt.variant = us.variant
    GROUP BY abt.test_id, abt.test_name, us.variant, abt.variant_desc, us.device_segment, us.region_segment
    HAVING unique_visitors >= 100
)
SELECT 
    test_id,
    test_name,
    variant,
    variant_desc,
    device_segment,
    region_segment,
    unique_visitors,
    purchases,
    conversion_rate,
    -- Her segmentteki varyantlar arası farkı hesaplama
    MAX(conversion_rate) OVER (PARTITION BY test_id, device_segment, region_segment) - 
    MIN(conversion_rate) OVER (PARTITION BY test_id, device_segment, region_segment) AS conversion_difference
FROM segment_conversion
ORDER BY test_id, device_segment, region_segment, variant;

-- Uzun vadeli etkileri ölçün
WITH ab_test_data AS (
    -- Örnek A/B test verileri
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'A' AS variant, 'control' AS variant_desc, '2023-01-01' AS start_date, '2023-01-31' AS end_date UNION ALL
    SELECT 1 AS test_id, 'Homepage Redesign' AS test_name, 'B' AS variant, 'new_design' AS variant_desc, '2023-01-01' AS start_date, '2023-01-31' AS end_date
),
user_assignments AS (
    -- Varsayımsal kullanıcı atamaları
    SELECT 
        csd.visitor_id,
        CASE WHEN MOD(CAST(SUBSTRING(csd.visitor_id, 1, 8) AS UNSIGNED), 2) = 0 THEN 'A' ELSE 'B' END AS variant,
        DATE(csd.timestamp) AS activity_date
    FROM click_stream_data csd
    WHERE csd.timestamp BETWEEN '2023-01-01' AND '2023-03-31'
    GROUP BY csd.visitor_id, variant, activity_date
),
user_activity AS (
    SELECT 
        ua.visitor_id,
        ua.variant,
        ua.activity_date,
        CASE 
            WHEN ua.activity_date BETWEEN abt.start_date AND abt.end_date THEN 'During Test'
            WHEN ua.activity_date > abt.end_date THEN 'Post Test'
        END AS time_period,
        DATEDIFF(ua.activity_date, abt.end_date) AS days_after_test,
        -- Birleştirme yapmak için test_id ekle
        abt.test_id
    FROM user_assignments ua
    JOIN ab_test_data abt ON ua.variant = abt.variant
    WHERE ua.activity_date >= abt.start_date
),
retention_data AS (
    SELECT 
        abt.test_id,
        abt.test_name,
        ua.variant,
        abt.variant_desc,
        ua.time_period,
        FLOOR(ua.days_after_test / 7) + 1 AS week_after_test,
        COUNT(DISTINCT ua.visitor_id) AS unique_visitors,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN ua.visitor_id END) AS purchasing_visitors,
        ROUND(COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN ua.visitor_id END) * 100.0 / 
              NULLIF(COUNT(DISTINCT ua.visitor_id), 0), 2) AS purchase_rate
    FROM user_activity ua
    JOIN ab_test_data abt ON ua.test_id = abt.test_id AND ua.variant = abt.variant
    LEFT JOIN click_stream_data csd ON ua.visitor_id = csd.visitor_id AND DATE(csd.timestamp) = ua.activity_date
    WHERE ua.time_period = 'Post Test'
    GROUP BY abt.test_id, abt.test_name, ua.variant, abt.variant_desc, ua.time_period, week_after_test
    HAVING week_after_test <= 8
)
SELECT 
    test_id,
    test_name,
    variant,
    variant_desc,
    week_after_test,
    unique_visitors,
    purchasing_visitors,
    purchase_rate,
    -- A/B varyantları arasındaki farkı hesaplama
    MAX(purchase_rate) OVER (PARTITION BY test_id, week_after_test) - 
    MIN(purchase_rate) OVER (PARTITION BY test_id, week_after_test) AS rate_difference
FROM retention_data
ORDER BY test_id, week_after_test, variant;
