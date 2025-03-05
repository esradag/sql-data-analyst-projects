-- Toplam harcamaya göre müşterileri sıralayın
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       SUM(oi.unit_price * oi.quantity) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, customer_name
ORDER BY total_spent DESC;

-- Son 30 gün içinde alışveriş yapan aktif müşterileri bulun
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       MAX(o.order_date) AS last_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY c.customer_id, customer_name
ORDER BY last_order_date DESC;

-- Ortalama sipariş değerine göre müşterileri gruplayın
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       COUNT(o.order_id) AS order_count,
       SUM(oi.unit_price * oi.quantity) AS total_spent,
       SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT o.order_id) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, customer_name
ORDER BY avg_order_value DESC;

-- İlk alışveriş ve son alışveriş arasındaki süreyi hesaplayın
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       MIN(o.order_date) AS first_order_date,
       MAX(o.order_date) AS last_order_date,
       DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS days_between_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name
HAVING COUNT(o.order_id) > 1
ORDER BY days_between_orders DESC;