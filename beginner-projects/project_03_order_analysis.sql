-- Günlük, haftalık ve aylık toplam sipariş sayısını hesaplayın
-- Günlük sipariş sayısı
SELECT DATE(order_date) AS order_day, COUNT(order_id) AS daily_orders
FROM orders
GROUP BY order_day
ORDER BY order_day DESC;

-- Haftalık sipariş sayısı
SELECT YEAR(order_date) AS year, WEEK(order_date) AS week_number, 
       COUNT(order_id) AS weekly_orders
FROM orders
GROUP BY year, week_number
ORDER BY year DESC, week_number DESC;

-- Aylık sipariş sayısı
SELECT YEAR(order_date) AS year, MONTH(order_date) AS month_number, 
       COUNT(order_id) AS monthly_orders
FROM orders
GROUP BY year, month_number
ORDER BY year DESC, month_number DESC;

-- Ortalama sepet büyüklüğünü bulun
SELECT AVG(order_items_count) AS avg_basket_size
FROM (
    SELECT o.order_id, COUNT(oi.order_item_id) AS order_items_count
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id
) AS order_items_counts;

-- Siparişlerin durumuna göre dağılımını görüntüleyin
SELECT status, COUNT(order_id) AS order_count, 
       ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Teslimat sürelerini analiz edin
SELECT o.order_id, o.order_date, 
       DATEDIFF(MIN(CASE WHEN o.status = 'delivered' THEN o.order_date ELSE NULL END),
                o.order_date) AS delivery_days
FROM orders o
WHERE o.status = 'delivered'
GROUP BY o.order_id, o.order_date
ORDER BY delivery_days DESC;