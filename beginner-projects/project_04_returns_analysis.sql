-- En çok iade edilen 5 ürünü bulun
SELECT p.product_id, p.product_name, COUNT(ri.return_item_id) AS return_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN return_items ri ON oi.order_item_id = ri.order_item_id
JOIN returns r ON ri.return_id = r.return_id
WHERE r.status IN ('approved', 'completed')
GROUP BY p.product_id, p.product_name
ORDER BY return_count DESC
LIMIT 5;

-- İade nedenlerine göre iadeleri gruplandırın
SELECT reason, COUNT(return_id) AS return_count,
       ROUND(COUNT(return_id) * 100.0 / (SELECT COUNT(*) FROM returns), 2) AS percentage
FROM returns
GROUP BY reason
ORDER BY return_count DESC;

-- İade oranlarını hesaplayın (toplam satışlara göre)
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.return_id) AS total_returns,
    ROUND(COUNT(DISTINCT r.return_id) * 100.0 / COUNT(DISTINCT o.order_id), 2) AS return_rate
FROM orders o
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY year, month
ORDER BY year DESC, month DESC;

-- İadelerin zaman içindeki eğilimini görüntüleyin
SELECT 
    DATE_FORMAT(r.return_date, '%Y-%m') AS year_month,
    COUNT(r.return_id) AS return_count
FROM returns r
GROUP BY year_month
ORDER BY year_month;