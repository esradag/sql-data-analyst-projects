-- Sık birlikte satın alınan ürün çiftlerini bulun
WITH order_products AS (
    SELECT 
        o.order_id,
        p.product_id,
        p.product_name
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status NOT IN ('cancelled')
)
SELECT 
    op1.product_id AS product1_id,
    op1.product_name AS product1_name,
    op2.product_id AS product2_id,
    op2.product_name AS product2_name,
    COUNT(DISTINCT op1.order_id) AS co_occurrence_count
FROM order_products op1
JOIN order_products op2 ON op1.order_id = op2.order_id AND op1.product_id < op2.product_id
GROUP BY product1_id, product1_name, product2_id, product2_name
HAVING co_occurrence_count > 5
ORDER BY co_occurrence_count DESC;

-- Sepet büyüklüğü ile ürün kategorileri arasındaki ilişkiyi araştırın
WITH order_categories AS (
    SELECT 
        o.order_id,
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.product_id) AS basket_size
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY o.order_id, c.category_id, c.category_name
)
SELECT 
    category_id,
    category_name,
    COUNT(DISTINCT order_id) AS order_count,
    AVG(basket_size) AS avg_basket_size
FROM order_categories
GROUP BY category_id, category_name
ORDER BY avg_basket_size DESC;

-- Çapraz satış fırsatlarını tespit edin
WITH product_combinations AS (
    SELECT 
        p1.product_id AS source_product_id,
        p1.product_name AS source_product_name,
        p2.product_id AS target_product_id,
        p2.product_name AS target_product_name,
        COUNT(DISTINCT o1.order_id) AS co_occurrence_count
    FROM products p1
    JOIN order_items oi1 ON p1.product_id = oi1.product_id
    JOIN orders o1 ON oi1.order_id = o1.order_id
    JOIN order_items oi2 ON o1.order_id = oi2.order_id AND oi1.product_id != oi2.product_id
    JOIN products p2 ON oi2.product_id = p2.product_id
    WHERE o1.status NOT IN ('cancelled')
    GROUP BY source_product_id, source_product_name, target_product_id, target_product_name
),
product_purchases AS (
    SELECT 
        p.product_id,
        COUNT(DISTINCT o.order_id) AS purchase_count
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY p.product_id
)
SELECT 
    pc.source_product_id,
    pc.source_product_name,
    pc.target_product_id,
    pc.target_product_name,
    pc.co_occurrence_count,
    pp_source.purchase_count AS source_purchase_count,
    pp_target.purchase_count AS target_purchase_count,
    ROUND(pc.co_occurrence_count * 100.0 / pp_source.purchase_count, 2) AS co_occurrence_percentage,
    ROUND(pc.co_occurrence_count * 100.0 / pp_target.purchase_count, 2) AS reverse_percentage
FROM product_combinations pc
JOIN product_purchases pp_source ON pc.source_product_id = pp_source.product_id
JOIN product_purchases pp_target ON pc.target_product_id = pp_target.product_id
WHERE pc.co_occurrence_count > 5
  AND (pc.co_occurrence_count * 100.0 / pp_source.purchase_count) > 30
ORDER BY co_occurrence_percentage DESC;

-- Ürün tavsiye algoritması için veri hazırlayın
WITH customer_products AS (
    SELECT 
        o.customer_id,
        oi.product_id,
        COUNT(*) AS purchase_count
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled')
    GROUP BY o.customer_id, oi.product_id
),
customer_purchase_matrix AS (
    SELECT 
        cp1.customer_id,
        cp1.product_id AS product1_id,
        cp2.product_id AS product2_id,
        cp1.purchase_count AS product1_count,
        cp2.purchase_count AS product2_count
    FROM customer_products cp1
    JOIN customer_products cp2 ON cp1.customer_id = cp2.customer_id AND cp1.product_id != cp2.product_id
),
product_similarity AS (
    SELECT 
        product1_id,
        product2_id,
        COUNT(DISTINCT customer_id) AS common_customers,
        SUM(product1_count * product2_count) AS weight
    FROM customer_purchase_matrix
    GROUP BY product1_id, product2_id
)
SELECT 
    p1.product_id AS source_product_id,
    p1.product_name AS source_product_name,
    p2.product_id AS recommended_product_id,
    p2.product_name AS recommended_product_name,
    ps.common_customers,
    ps.weight,
    ROUND(ps.weight / (SELECT SUM(weight) FROM product_similarity WHERE product1_id = ps.product1_id), 3) AS similarity_score
FROM product_similarity ps
JOIN products p1 ON ps.product1_id = p1.product_id
JOIN products p2 ON ps.product2_id = p2.product_id
WHERE ps.common_customers > 2
ORDER BY ps.product1_id, similarity_score DESC;