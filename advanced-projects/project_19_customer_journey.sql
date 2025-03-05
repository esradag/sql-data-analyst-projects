-- Dönüşüme kadar geçen ortalama süreyi hesaplayın
WITH customer_journey AS (
    SELECT 
        csd.visitor_id,
        csd.customer_id,
        csd.event_type,
        MIN(csd.timestamp) AS first_event_time
    FROM click_stream_data csd
    WHERE csd.event_type IN ('page_view', 'product_view', 'add_to_cart', 'checkout', 'purchase')
    GROUP BY csd.visitor_id, csd.customer_id, csd.event_type
),
journey_stages AS (
    SELECT 
        visitor_id,
        MIN(CASE WHEN event_type = 'page_view' THEN first_event_time END) AS first_page_view,
        MIN(CASE WHEN event_type = 'product_view' THEN first_event_time END) AS first_product_view,
        MIN(CASE WHEN event_type = 'add_to_cart' THEN first_event_time END) AS first_add_to_cart,
        MIN(CASE WHEN event_type = 'checkout' THEN first_event_time END) AS first_checkout,
        MIN(CASE WHEN event_type = 'purchase' THEN first_event_time END) AS first_purchase
    FROM customer_journey
    GROUP BY visitor_id
),
conversion_times AS (
    SELECT 
        visitor_id,
        TIMESTAMPDIFF(MINUTE, first_page_view, first_product_view) AS time_to_product_view,
        TIMESTAMPDIFF(MINUTE, first_product_view, first_add_to_cart) AS time_to_add_to_cart,
        TIMESTAMPDIFF(MINUTE, first_add_to_cart, first_checkout) AS time_to_checkout,
        TIMESTAMPDIFF(MINUTE, first_checkout, first_purchase) AS time_to_purchase,
        TIMESTAMPDIFF(MINUTE, first_page_view, first_purchase) AS total_conversion_time
    FROM journey_stages
    WHERE first_page_view IS NOT NULL 
      AND first_product_view IS NOT NULL 
      AND first_add_to_cart IS NOT NULL 
      AND first_checkout IS NOT NULL 
      AND first_purchase IS NOT NULL
)
SELECT 
    COUNT(*) AS completed_journeys,
    ROUND(AVG(time_to_product_view), 2) AS avg_time_to_product_view_min,
    ROUND(AVG(time_to_add_to_cart), 2) AS avg_time_to_add_to_cart_min,
    ROUND(AVG(time_to_checkout), 2) AS avg_time_to_checkout_min,
    ROUND(AVG(time_to_purchase), 2) AS avg_time_to_purchase_min,
    ROUND(AVG(total_conversion_time), 2) AS avg_total_conversion_time_min,
    ROUND(AVG(total_conversion_time) / 60, 2) AS avg_total_conversion_time_hours
FROM conversion_times
WHERE total_conversion_time > 0;

-- Müşteri yolculuğundaki kritik temas noktalarını belirleyin
WITH customer_journey AS (
    SELECT 
        csd.visitor_id,
        csd.event_type,
        COUNT(*) AS event_count,
        MIN(csd.timestamp) AS first_event_time,
        MAX(csd.timestamp) AS last_event_time
    FROM click_stream_data csd
    GROUP BY csd.visitor_id, csd.event_type
),
conversion_funnel AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN visitor_id END) AS visitors,
        COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN visitor_id END) AS product_viewers,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN visitor_id END) AS cart_adders,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout' THEN visitor_id END) AS checkout_starters,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN visitor_id END) AS purchasers
    FROM customer_journey
),
conversion_rates AS (
    SELECT 
        visitors,
        product_viewers,
        cart_adders,
        checkout_starters,
        purchasers,
        ROUND(product_viewers * 100.0 / NULLIF(visitors, 0), 2) AS visit_to_product_rate,
        ROUND(cart_adders * 100.0 / NULLIF(product_viewers, 0), 2) AS product_to_cart_rate,
        ROUND(checkout_starters * 100.0 / NULLIF(cart_adders, 0), 2) AS cart_to_checkout_rate,
        ROUND(purchasers * 100.0 / NULLIF(checkout_starters, 0), 2) AS checkout_to_purchase_rate,
        ROUND(purchasers * 100.0 / NULLIF(visitors, 0), 2) AS overall_conversion_rate
    FROM conversion_funnel
)
SELECT 
    visitors,
    product_viewers,
    cart_adders,
    checkout_starters,
    purchasers,
    visit_to_product_rate,
    product_to_cart_rate,
    cart_to_checkout_rate,
    checkout_to_purchase_rate,
    overall_conversion_rate,
    -- Darboğaz tespiti
    CASE 
        WHEN visit_to_product_rate < product_to_cart_rate AND visit_to_product_rate < cart_to_checkout_rate AND visit_to_product_rate < checkout_to_purchase_rate THEN 'Visit to Product View'
        WHEN product_to_cart_rate < visit_to_product_rate AND product_to_cart_rate < cart_to_checkout_rate AND product_to_cart_rate < checkout_to_purchase_rate THEN 'Product View to Add to Cart'
        WHEN cart_to_checkout_rate < visit_to_product_rate AND cart_to_checkout_rate < product_to_cart_rate AND cart_to_checkout_rate < checkout_to_purchase_rate THEN 'Add to Cart to Checkout'
        WHEN checkout_to_purchase_rate < visit_to_product_rate AND checkout_to_purchase_rate < product_to_cart_rate AND checkout_to_purchase_rate < cart_to_checkout_rate THEN 'Checkout to Purchase'
        ELSE 'No Clear Bottleneck'
    END AS bottleneck
FROM conversion_rates;

-- Dönüşüm hunisindeki darboğazları tespit edin
WITH journey_funnel AS (
    SELECT 
        DATE(csd.timestamp) AS journey_date,
        csd.referral_source,
        csd.device_type,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'page_view' THEN csd.visitor_id END) AS visitors,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'product_view' THEN csd.visitor_id END) AS product_viewers,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'add_to_cart' THEN csd.visitor_id END) AS cart_adders,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'checkout' THEN csd.visitor_id END) AS checkout_starters,
        COUNT(DISTINCT CASE WHEN csd.event_type = 'purchase' THEN csd.visitor_id END) AS purchasers
    FROM click_stream_data csd
    WHERE csd.timestamp >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY journey_date, referral_source, device_type
),
conversion_rates AS (
    SELECT 
        journey_date,
        referral_source,
        device_type,
        visitors,
        product_viewers,
        cart_adders,
        checkout_starters,
        purchasers,
        ROUND(product_viewers * 100.0 / NULLIF(visitors, 0), 2) AS visit_to_product_rate,
        ROUND(cart_adders * 100.0 / NULLIF(product_viewers, 0), 2) AS product_to_cart_rate,
        ROUND(checkout_starters * 100.0 / NULLIF(cart_adders, 0), 2) AS cart_to_checkout_rate,
        ROUND(purchasers * 100.0 / NULLIF(checkout_starters, 0), 2) AS checkout_to_purchase_rate,
        ROUND(purchasers * 100.0 / NULLIF(visitors, 0), 2) AS overall_conversion_rate
    FROM journey_funnel
)
SELECT 
    referral_source,
    device_type,
    ROUND(AVG(visitors), 0) AS avg_daily_visitors,
    ROUND(AVG(visit_to_product_rate), 2) AS avg_visit_to_product_rate,
    ROUND(AVG(product_to_cart_rate), 2) AS avg_product_to_cart_rate,
    ROUND(AVG(cart_to_checkout_rate), 2) AS avg_cart_to_checkout_rate,
    ROUND(AVG(checkout_to_purchase_rate), 2) AS avg_checkout_to_purchase_rate,
    ROUND(AVG(overall_conversion_rate), 2) AS avg_overall_conversion_rate,
    -- En düşük dönüşüm oranına sahip adımı bulmak
    CASE 
        WHEN AVG(visit_to_product_rate) <= AVG(product_to_cart_rate) AND 
             AVG(visit_to_product_rate) <= AVG(cart_to_checkout_rate) AND 
             AVG(visit_to_product_rate) <= AVG(checkout_to_purchase_rate) THEN 'Visit to Product View'
        WHEN AVG(product_to_cart_rate) <= AVG(visit_to_product_rate) AND 
             AVG(product_to_cart_rate) <= AVG(cart_to_checkout_rate) AND 
             AVG(product_to_cart_rate) <= AVG(checkout_to_purchase_rate) THEN 'Product View to Add to Cart'
        WHEN AVG(cart_to_checkout_rate) <= AVG(visit_to_product_rate) AND 
             AVG(cart_to_checkout_rate) <= AVG(product_to_cart_rate) AND 
             AVG(cart_to_checkout_rate) <= AVG(checkout_to_purchase_rate) THEN 'Add to Cart to Checkout'
        ELSE 'Checkout to Purchase'
    END AS bottleneck
FROM conversion_rates
WHERE visitors >= 10
GROUP BY referral_source, device_type
ORDER BY avg_overall_conversion_rate DESC;

-- Farklı müşteri segmentleri için yolculuk haritaları oluşturun
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        -- Müşteri değerine göre segmentasyon
        CASE 
            WHEN SUM(oi.unit_price * oi.quantity) > 1000 THEN 'High Value'
            WHEN SUM(oi.unit_price * oi.quantity) > 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_segment,
        -- Sipariş sıklığına göre segmentasyon
        CASE 
            WHEN COUNT(DISTINCT o.order_id) > 5 THEN 'Frequent'
            WHEN COUNT(DISTINCT o.order_id) > 2 THEN 'Regular'
            ELSE 'Occasional'
        END AS frequency_segment,
        -- Son sipariş tarihine göre segmentasyon
        CASE 
            WHEN MAX(o.order_date) >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) THEN 'Active'
            WHEN MAX(o.order_date) >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN 'Recent'
            ELSE 'Inactive'
        END AS recency_segment
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY c.customer_id, c.first_name, c.last_name
),
segment_journey AS (
    SELECT 
        cs.value_segment,
        cs.frequency_segment,
        cs.recency_segment,
        csd.event_type,
        COUNT(DISTINCT csd.visitor_id) AS unique_visitors,
        COUNT(*) AS event_count,
        AVG(CASE WHEN csd.event_type = 'product_view' THEN products_viewed ELSE NULL END) AS avg_products_viewed,
        AVG(CASE WHEN csd.event_type = 'add_to_cart' THEN items_added ELSE NULL END) AS avg_items_added,
        AVG(CASE WHEN csd.event_type = 'purchase' THEN purchase_value ELSE NULL END) AS avg_purchase_value
    FROM customer_segments cs
    JOIN click_stream_data csd ON cs.customer_id = csd.customer_id
    LEFT JOIN (
        SELECT visitor_id, COUNT(*) AS products_viewed
        FROM click_stream_data
        WHERE event_type = 'product_view'
        GROUP BY visitor_id
    ) pv ON csd.visitor_id = pv.visitor_id AND csd.event_type = 'product_view'
    LEFT JOIN (
        SELECT visitor_id, COUNT(*) AS items_added
        FROM click_stream_data
        WHERE event_type = 'add_to_cart'
        GROUP BY visitor_id
    ) ac ON csd.visitor_id = ac.visitor_id AND csd.event_type = 'add_to_cart'
    LEFT JOIN (
        SELECT csd.visitor_id, SUM(oi.unit_price * oi.quantity) AS purchase_value
        FROM click_stream_data csd
        JOIN orders o ON csd.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE csd.event_type = 'purchase'
        GROUP BY csd.visitor_id
    ) pv2 ON csd.visitor_id = pv2.visitor_id AND csd.event_type = 'purchase'
    GROUP BY cs.value_segment, cs.frequency_segment, cs.recency_segment, csd.event_type
)
SELECT 
    value_segment,
    frequency_segment,
    recency_segment,
    event_type,
    unique_visitors,
    event_count,
    ROUND(event_count / unique_visitors, 2) AS events_per_visitor,
    ROUND(avg_products_viewed, 2) AS avg_products_viewed,
    ROUND(avg_items_added, 2) AS avg_items_added,
    ROUND(avg_purchase_value, 2) AS avg_purchase_value
FROM segment_journey
ORDER BY value_segment, frequency_segment, recency_segment, 
    CASE 
        WHEN event_type = 'page_view' THEN 1
        WHEN event_type = 'product_view' THEN 2
        WHEN event_type = 'add_to_cart' THEN 3
        WHEN event_type = 'checkout' THEN 4
        WHEN event_type = 'purchase' THEN 5
        ELSE 6
    END;