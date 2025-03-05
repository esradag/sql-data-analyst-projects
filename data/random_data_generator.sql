-- Bu script daha fazla rastgele veri oluşturmak için kullanılabilir
-- Her çalıştırdığınızda yeni veriler eklenecektir

-- Kullanacağımız fonksiyonları tanımlayalım
DELIMITER //
CREATE FUNCTION IF NOT EXISTS random_number(min INT, max INT)
RETURNS INT
NO SQL
BEGIN
    RETURN FLOOR(RAND() * (max - min + 1)) + min;
END //

CREATE FUNCTION IF NOT EXISTS random_date(start_date DATE, end_date DATE)
RETURNS DATE
NO SQL
BEGIN
    RETURN DATE_ADD(start_date, INTERVAL FLOOR(RAND() * DATEDIFF(end_date, start_date)) DAY);
END //
DELIMITER ;

-- Daha fazla siparişler oluşturalım (son 1 yıl içinde)
DROP TEMPORARY TABLE IF EXISTS temp_order_data;
CREATE TEMPORARY TABLE temp_order_data (
    customer_id INT,
    order_date DATETIME,
    status VARCHAR(20),
    shipping_cost DECIMAL(10, 2),
    order_source VARCHAR(20)
);

-- Son bir yıl içinde her müşteri için rastgele siparişler oluşturalım
INSERT INTO temp_order_data (customer_id, order_date, status, shipping_cost, order_source)
SELECT 
    customer_id,
    DATE_SUB(NOW(), INTERVAL random_number(1, 365) DAY),
    ELT(random_number(1, 5), 'pending', 'processing', 'shipped', 'delivered', 'cancelled'),
    ELT(random_number(1, 4), 0.00, 10.00, 15.00, 20.00),
    ELT(random_number(1, 3), 'web', 'mobile', 'store')
FROM customers
ORDER BY RAND()
LIMIT 100; -- Burada istediğiniz kadar sipariş oluşturabilirsiniz

-- Geçici tablodan gerçek siparişler tablosuna verileri ekleyelim
INSERT INTO orders (customer_id, order_date, status, shipping_address, shipping_city, shipping_country, shipping_postal_code, shipping_cost, order_source)
SELECT 
    t.customer_id,
    t.order_date,
    t.status,
    c.address,
    c.city,
    c.country,
    c.postal_code,
    t.shipping_cost,
    t.order_source
FROM temp_order_data t
JOIN customers c ON t.customer_id = c.customer_id;

-- Mevcut sipariş sayısını alalım
SET @order_start_id = (SELECT MAX(order_id) FROM orders WHERE order_id <= (SELECT MAX(order_id) FROM order_items));
SET @order_end_id = (SELECT MAX(order_id) FROM orders);

-- Her sipariş için sipariş kalemleri oluşturalım
DROP TEMPORARY TABLE IF EXISTS temp_order_items;
CREATE TEMPORARY TABLE temp_order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    discount DECIMAL(10, 2)
);

-- Her sipariş için 1-4 arası ürün ekleyelim
INSERT INTO temp_order_items (order_id, product_id, quantity, unit_price, discount)
SELECT 
    o.order_id,
    p.product_id,
    random_number(1, 3), -- 1-3 arası miktar
    p.price,
    CASE WHEN random_number(1, 10) > 7 THEN p.price * random_number(5, 20) / 100 ELSE 0 END -- %30 olasılıkla indirim
FROM orders o
CROSS JOIN (
    SELECT product_id, price FROM products ORDER BY RAND() LIMIT 1
) p
WHERE o.order_id > @order_start_id AND o.order_id <= @order_end_id;

-- Bazı siparişlere ek ürünler ekleyelim
INSERT INTO temp_order_items (order_id, product_id, quantity, unit_price, discount)
SELECT 
    o.order_id,
    p.product_id,
    random_number(1, 3), -- 1-3 arası miktar
    p.price,
    CASE WHEN random_number(1, 10) > 7 THEN p.price * random_number(5, 20) / 100 ELSE 0 END -- %30 olasılıkla indirim
FROM orders o
CROSS JOIN (
    SELECT product_id, price FROM products ORDER BY RAND() LIMIT 1
) p
WHERE o.order_id > @order_start_id AND o.order_id <= @order_end_id
AND random_number(1, 10) > 5; -- %50 olasılıkla ikinci ürün

-- Bazı siparişlere üçüncü ürün ekleyelim
INSERT INTO temp_order_items (order_id, product_id, quantity, unit_price, discount)
SELECT 
    o.order_id,
    p.product_id,
    random_number(1, 3), -- 1-3 arası miktar
    p.price,
    CASE WHEN random_number(1, 10) > 7 THEN p.price * random_number(5, 20) / 100 ELSE 0 END -- %30 olasılıkla indirim
FROM orders o
CROSS JOIN (
    SELECT product_id, price FROM products ORDER BY RAND() LIMIT 1
) p
WHERE o.order_id > @order_start_id AND o.order_id <= @order_end_id
AND random_number(1, 10) > 7; -- %30 olasılıkla üçüncü ürün

-- Sipariş kalemlerini asıl tabloya ekleyelim
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
SELECT order_id, product_id, quantity, unit_price, discount FROM temp_order_items;

-- Ödemeleri oluşturalım
INSERT INTO payments (order_id, payment_date, payment_method, amount, status)
SELECT 
    o.order_id,
    o.order_date,
    ELT(random_number(1, 5), 'credit_card', 'debit_card', 'paypal', 'bank_transfer', 'cash'),
    (SELECT SUM(oi.unit_price * oi.quantity - oi.discount) FROM order_items oi WHERE oi.order_id = o.order_id),
    CASE 
        WHEN o.status = 'cancelled' THEN 'refunded'
        ELSE 'completed'
    END
FROM orders o
WHERE o.order_id > @order_start_id AND o.order_id <= @order_end_id;

-- Rastgele bazı siparişler için iadeler oluşturalım
INSERT INTO returns (order_id, return_date, reason, notes, status)
SELECT 
    o.order_id,
    DATE_ADD(o.order_date, INTERVAL random_number(3, 14) DAY),
    ELT(random_number(1, 5), 'defective', 'wrong_item', 'not_as_described', 'no_longer_needed', 'other'),
    ELT(random_number(1, 5), 
        'Ürün hasarlı geldi.',
        'Sipariş ettiğim ürünle gelen ürün farklı.',
        'Ürün açıklaması yanıltıcı.',
        'Artık ihtiyacım yok.',
        'Diğer sebepler.'),
    ELT(random_number(1, 4), 'pending', 'approved', 'rejected', 'completed')
FROM orders o
WHERE o.status = 'delivered'
AND o.order_id > @order_start_id AND o.order_id <= @order_end_id
AND random_number(1, 10) > 8; -- %20 olasılıkla iade

-- İade kalemleri oluşturalım
INSERT INTO return_items (return_id, order_item_id, quantity)
SELECT 
    r.return_id,
    oi.order_item_id,
    CASE 
        WHEN random_number(1, 10) > 8 THEN oi.quantity -- %20 olasılıkla tüm miktar iade edilir
        ELSE 1 -- %80 olasılıkla sadece 1 adet iade edilir
    END
FROM returns r
JOIN orders o ON r.order_id = o.order_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE random_number(1, 10) > 3; -- Her sipariş kaleminin %70'i iade edilir

-- Tıklama akışı verileri için ek veriler oluşturmak için aşağıdaki kodu kullanabilirsiniz:
-- Bu örnek, son 7 gün içinde 30 farklı kullanıcının rastgele sitede dolaşmasını simüle eder

DROP TEMPORARY TABLE IF EXISTS temp_visitors;
CREATE TEMPORARY TABLE temp_visitors (
    visitor_id VARCHAR(20),
    customer_id INT,
    device_type VARCHAR(20),
    referral_source VARCHAR(50)
);

-- 30 rastgele ziyaretçi oluşturalım
INSERT INTO temp_visitors (visitor_id, customer_id, device_type, referral_source)
SELECT 
    CONCAT('vis_', LPAD(n.n, 3, '0')),
    CASE WHEN random_number(1, 10) > 4 THEN (SELECT customer_id FROM customers ORDER BY RAND() LIMIT 1) ELSE NULL END,
    ELT(random_number(1, 3), 'desktop', 'mobile', 'tablet'),
    ELT(random_number(1, 6), 'google', 'facebook', 'instagram', 'direct', 'twitter', 'bing')
FROM (SELECT @row := @row + 1 as n FROM customers, (SELECT @row:=100) r LIMIT 30) n;

-- Her ziyaretçi için rastgele olaylar oluşturalım
INSERT INTO click_stream_data (visitor_id, customer_id, page_url, event_type, product_id, referral_source, timestamp, session_id, device_type)
-- Ana sayfa ziyareti
SELECT 
    v.visitor_id,
    v.customer_id,
    'https://example.com/',
    'page_view',
    NULL,
    v.referral_source,
    DATE_SUB(NOW(), INTERVAL random_number(1, 10080) MINUTE), -- Son 7 gün (10080 dakika)
    CONCAT('sess_', v.visitor_id),
    v.device_type
FROM temp_visitors v;

-- Her müşteri için bir başka kod bloğu ile detaylı analiz verileri oluşturabilirsiniz.
-- Bu örnek kod, temel bir veritabanı doldurma işlemini göstermektedir.

-- Oluşturulan verileri özetleyen istatistikler
SELECT 'Siparişler' AS table_name, COUNT(*) AS record_count FROM orders
UNION ALL
SELECT 'Sipariş Kalemleri', COUNT(*) AS record_count FROM order_items
UNION ALL
SELECT 'Ödemeler', COUNT(*) AS record_count FROM payments
UNION ALL
SELECT 'İadeler', COUNT(*) AS record_count FROM returns
UNION ALL
SELECT 'İade Kalemleri', COUNT(*) AS record_count FROM return_items
UNION ALL
SELECT 'Tıklama Verileri', COUNT(*) AS record_count FROM click_stream_data;

-- İhtiyacınıza göre diğer tablolar için de benzer şekilde rastgele veriler oluşturabilirsiniz.
-- Oluşturduğunuz fonksiyonları silmek isterseniz:
-- DROP FUNCTION IF EXISTS random_number;
-- DROP FUNCTION IF EXISTS random_date;