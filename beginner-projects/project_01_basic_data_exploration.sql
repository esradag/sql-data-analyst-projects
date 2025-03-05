-- En pahalı 10 ürünü listeleyin
SELECT product_id, product_name, price
FROM products
ORDER BY price DESC
LIMIT 10;

-- Kategoriye göre ürün sayısını bulun
SELECT c.category_id, c.category_name, COUNT(p.product_id) AS product_count
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;

-- Stokta olmayan ürünleri belirleyin
SELECT product_id, product_name, price
FROM products
WHERE stock_quantity = 0;

-- Fiyatı belirli bir aralıkta olan ürünleri filtreleyip sıralayın
SELECT product_id, product_name, price
FROM products
WHERE price BETWEEN 50 AND 200
ORDER BY price;