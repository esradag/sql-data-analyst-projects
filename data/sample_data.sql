-- E-Ticaret Veritabanı Örnek Veri Oluşturma
-- Önce veritabanını oluşturuyoruz
CREATE DATABASE IF NOT EXISTS ecommerce_analysis;
USE ecommerce_analysis;

-- Veritabanı tablolarımızı oluşturuyoruz (eğer daha önce oluşturmadıysanız)
-- [Burada daha önce verilen veritabanı şemasını kullanabilirsiniz]

-- Örnek verileri oluşturalım:

-- 1. Kategoriler tablosuna örnek veriler ekleyelim
INSERT INTO categories (category_name, description) VALUES 
('Elektronik', 'Telefon, bilgisayar, tablet ve diğer elektronik cihazlar'),
('Giyim', 'Erkek, kadın ve çocuk giyim ürünleri'),
('Ev & Yaşam', 'Mobilya, dekorasyon, mutfak eşyaları'),
('Kitap', 'Roman, hikaye, bilim ve çeşitli kitaplar'),
('Spor', 'Spor giyim, ekipman ve aksesuarlar'),
('Kozmetik', 'Makyaj, cilt bakım, parfüm ürünleri'),
('Oyuncak', 'Çocuk ve bebek oyuncakları'),
('Ayakkabı', 'Erkek, kadın ve çocuk ayakkabıları'),
('Takı & Aksesuar', 'Bileklik, kolye, küpe ve diğer aksesuarlar'),
('Bahçe', 'Bahçe mobilyaları, süs bitkileri ve bahçe ekipmanları');

-- 2. Ürünler tablosuna örnek veriler ekleyelim
INSERT INTO products (product_name, category_id, description, price, cost, stock_quantity) VALUES 
-- Elektronik Ürünler
('Akıllı Telefon X', 1, 'Son teknoloji akıllı telefon, 128GB depolama, 8GB RAM', 6999.99, 5200.00, 150),
('Laptop Pro', 1, '15.6 inç, 512GB SSD, 16GB RAM, i7 işlemci', 12999.99, 9800.00, 75),
('Kablosuz Kulaklık', 1, 'Gürültü engelleyici özellikli premium kablosuz kulaklık', 1299.99, 750.00, 200),
('Akıllı Saat', 1, 'Kalp atış hızı izleme, adım sayma, bildirim alma özellikleri', 1599.99, 900.00, 120),
('Tablet Pro', 1, '10.5 inç, 64GB depolama, WiFi + 4G', 4399.99, 3200.00, 85),

-- Giyim Ürünleri
('Erkek Slim Fit Gömlek', 2, '%100 pamuk, slim fit erkek gömleği', 249.99, 110.00, 300),
('Kadın Triko Kazak', 2, 'Yumuşak dokulu, boğazlı kadın kazak', 199.99, 90.00, 250),
('Unisex Sweatshirt', 2, 'Rahat, yumuşak dokulu sweatshirt', 179.99, 80.00, 400),
('Erkek Kot Pantolon', 2, 'Regular fit, mavi erkek kot pantolon', 299.99, 150.00, 280),
('Kadın Elbise', 2, 'Çiçek desenli, yazlık kadın elbise', 349.99, 180.00, 220),

-- Ev & Yaşam Ürünleri
('Yemek Takımı', 3, '24 parça porselen yemek takımı', 899.99, 500.00, 50),
('Koltuk Takımı', 3, '3+3+1 koltuk takımı, yumuşak dokulu kumaş', 12999.99, 8000.00, 15),
('Yatak Örtüsü', 3, 'Çift kişilik, pamuklu yatak örtüsü', 399.99, 180.00, 100),
('LED Avize', 3, 'Modern tasarım, uzaktan kumandalı LED avize', 799.99, 450.00, 40),
('Tencere Seti', 3, '7 parça granit tencere seti', 1199.99, 700.00, 60),

-- Kitap Ürünleri
('Modern Klasikler', 4, 'En sevilen modern klasik romanlar derlemesi', 59.99, 25.00, 500),
('Bilim Ansiklopedisi', 4, 'Çocuklar için resimli bilim ansiklopedisi', 129.99, 60.00, 150),
('Kişisel Gelişim Seti', 4, '5 kitaplık kişisel gelişim seti', 249.99, 120.00, 180),
('Dünya Klasikleri', 4, 'Ciltli dünya klasikleri seti', 499.99, 240.00, 100),
('Tarih Kitabı', 4, 'Resimli dünya tarihi', 79.99, 35.00, 250),

-- Spor Ürünleri
('Koşu Ayakkabısı', 5, 'Hafif, konforlu koşu ayakkabısı', 599.99, 300.00, 200),
('Yoga Matı', 5, 'Kaymaz, 6mm kalınlığında yoga matı', 149.99, 70.00, 150),
('Fitness Seti', 5, 'Dambıl, pilates bandı ve atlama ipi seti', 349.99, 180.00, 80),
('Spor Çantası', 5, 'Dayanıklı, çok bölmeli spor çantası', 199.99, 90.00, 120),
('Bisiklet', 5, '26 jant, 21 vites dağ bisikleti', 2999.99, 1800.00, 30);

-- Diğer kategoriler için benzer şekilde ürünler ekleyebilirsiniz.

-- 3. Müşteriler tablosuna örnek veriler ekleyelim
INSERT INTO customers (first_name, last_name, email, phone, address, city, country, postal_code) VALUES 
('Ahmet', 'Yılmaz', 'ahmet.yilmaz@email.com', '5321234567', 'Atatürk Cad. No:123', 'İstanbul', 'Türkiye', '34100'),
('Mehmet', 'Kaya', 'mehmet.kaya@email.com', '5331234567', 'Cumhuriyet Mah. 1234 Sok. No:5', 'Ankara', 'Türkiye', '06100'),
('Ayşe', 'Demir', 'ayse.demir@email.com', '5351234567', 'Bağdat Cad. No:42', 'İzmir', 'Türkiye', '35100'),
('Fatma', 'Çelik', 'fatma.celik@email.com', '5361234567', 'Gazi Bulvarı No:78', 'Bursa', 'Türkiye', '16100'),
('Ali', 'Öztürk', 'ali.ozturk@email.com', '5371234567', 'İnönü Cad. 567 Sok. No:12', 'Antalya', 'Türkiye', '07100'),
('Zeynep', 'Şahin', 'zeynep.sahin@email.com', '5381234567', 'Karşıyaka Mah. 123 Sok. No:45', 'İstanbul', 'Türkiye', '34200'),
('Mustafa', 'Aydın', 'mustafa.aydin@email.com', '5391234567', 'Bademli Sok. No:7', 'Ankara', 'Türkiye', '06200'),
('Emine', 'Yıldız', 'emine.yildiz@email.com', '5301234567', 'Eski Bağdat Yolu No:56', 'İzmir', 'Türkiye', '35200'),
('Hüseyin', 'Arslan', 'huseyin.arslan@email.com', '5311234567', 'Merkez Mah. 456 Sok. No:89', 'Adana', 'Türkiye', '01100'),
('Hatice', 'Kurt', 'hatice.kurt@email.com', '5341234567', 'Yeni Mah. 789 Sok. No:23', 'Samsun', 'Türkiye', '55100'),
('Murat', 'Özkan', 'murat.ozkan@email.com', '5411234567', 'Anadolu Cad. No:65', 'Eskişehir', 'Türkiye', '26100'),
('Elif', 'Koç', 'elif.koc@email.com', '5421234567', 'Barış Mah. 234 Sok. No:78', 'Kayseri', 'Türkiye', '38100'),
('İbrahim', 'Doğan', 'ibrahim.dogan@email.com', '5431234567', 'Atatürk Bulvarı No:90', 'Konya', 'Türkiye', '42100'),
('Sibel', 'Çetin', 'sibel.cetin@email.com', '5441234567', 'Yavuz Selim Cad. No:12', 'Trabzon', 'Türkiye', '61100'),
('Hakan', 'Yıldırım', 'hakan.yildirim@email.com', '5451234567', 'Menderes Cad. 567 Sok. No:34', 'Diyarbakır', 'Türkiye', '21100');

-- 4. Siparişler tablosuna örnek veriler ekleyelim
-- Bu verilerin tarihleri, son 1 yıl içindeki rastgele tarihleri temsil eder
INSERT INTO orders (customer_id, order_date, status, shipping_address, shipping_city, shipping_country, shipping_postal_code, shipping_cost, order_source) VALUES 
(1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'delivered', 'Atatürk Cad. No:123', 'İstanbul', 'Türkiye', '34100', 0.00, 'web'),
(2, DATE_SUB(NOW(), INTERVAL 5 DAY), 'shipped', 'Cumhuriyet Mah. 1234 Sok. No:5', 'Ankara', 'Türkiye', '06100', 10.00, 'mobile'),
(3, DATE_SUB(NOW(), INTERVAL 10 DAY), 'delivered', 'Bağdat Cad. No:42', 'İzmir', 'Türkiye', '35100', 0.00, 'web'),
(4, DATE_SUB(NOW(), INTERVAL 15 DAY), 'delivered', 'Gazi Bulvarı No:78', 'Bursa', 'Türkiye', '16100', 0.00, 'web'),
(5, DATE_SUB(NOW(), INTERVAL 20 DAY), 'delivered', 'İnönü Cad. 567 Sok. No:12', 'Antalya', 'Türkiye', '07100', 15.00, 'store'),
(6, DATE_SUB(NOW(), INTERVAL 25 DAY), 'delivered', 'Karşıyaka Mah. 123 Sok. No:45', 'İstanbul', 'Türkiye', '34200', 0.00, 'mobile'),
(7, DATE_SUB(NOW(), INTERVAL 30 DAY), 'delivered', 'Bademli Sok. No:7', 'Ankara', 'Türkiye', '06200', 10.00, 'web'),
(8, DATE_SUB(NOW(), INTERVAL 35 DAY), 'delivered', 'Eski Bağdat Yolu No:56', 'İzmir', 'Türkiye', '35200', 0.00, 'mobile'),
(9, DATE_SUB(NOW(), INTERVAL 40 DAY), 'delivered', 'Merkez Mah. 456 Sok. No:89', 'Adana', 'Türkiye', '01100', 12.50, 'web'),
(10, DATE_SUB(NOW(), INTERVAL 45 DAY), 'delivered', 'Yeni Mah. 789 Sok. No:23', 'Samsun', 'Türkiye', '55100', 18.00, 'store'),
(11, DATE_SUB(NOW(), INTERVAL 50 DAY), 'delivered', 'Anadolu Cad. No:65', 'Eskişehir', 'Türkiye', '26100', 0.00, 'web'),
(12, DATE_SUB(NOW(), INTERVAL 55 DAY), 'delivered', 'Barış Mah. 234 Sok. No:78', 'Kayseri', 'Türkiye', '38100', 14.50, 'mobile'),
(13, DATE_SUB(NOW(), INTERVAL 60 DAY), 'delivered', 'Atatürk Bulvarı No:90', 'Konya', 'Türkiye', '42100', 0.00, 'web'),
(14, DATE_SUB(NOW(), INTERVAL 65 DAY), 'delivered', 'Yavuz Selim Cad. No:12', 'Trabzon', 'Türkiye', '61100', 20.00, 'web'),
(15, DATE_SUB(NOW(), INTERVAL 70 DAY), 'delivered', 'Menderes Cad. 567 Sok. No:34', 'Diyarbakır', 'Türkiye', '21100', 22.50, 'store'),
(1, DATE_SUB(NOW(), INTERVAL 75 DAY), 'delivered', 'Atatürk Cad. No:123', 'İstanbul', 'Türkiye', '34100', 0.00, 'web'),
(2, DATE_SUB(NOW(), INTERVAL 80 DAY), 'delivered', 'Cumhuriyet Mah. 1234 Sok. No:5', 'Ankara', 'Türkiye', '06100', 10.00, 'mobile'),
(3, DATE_SUB(NOW(), INTERVAL 85 DAY), 'delivered', 'Bağdat Cad. No:42', 'İzmir', 'Türkiye', '35100', 0.00, 'web'),
(4, DATE_SUB(NOW(), INTERVAL 90 DAY), 'delivered', 'Gazi Bulvarı No:78', 'Bursa', 'Türkiye', '16100', 0.00, 'web'),
(5, DATE_SUB(NOW(), INTERVAL 95 DAY), 'delivered', 'İnönü Cad. 567 Sok. No:12', 'Antalya', 'Türkiye', '07100', 15.00, 'mobile');

-- Daha fazla sipariş için, bu örnekleri çoğaltabilir ve tarihleri değiştirebilirsiniz.

-- 5. Sipariş Kalemleri tablosuna örnek veriler ekleyelim
-- 1 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(1, 1, 1, 6999.99, 0.00),
(1, 3, 1, 1299.99, 0.00);

-- 2 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(2, 5, 1, 4399.99, 0.00),
(2, 4, 1, 1599.99, 0.00);

-- 3 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(3, 6, 2, 249.99, 10.00),
(3, 7, 1, 199.99, 0.00);

-- 4 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(4, 8, 1, 179.99, 0.00),
(4, 9, 2, 299.99, 15.00);

-- 5 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(5, 10, 1, 349.99, 0.00);

-- 6 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(6, 11, 1, 899.99, 50.00),
(6, 13, 2, 399.99, 0.00);

-- 7 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(7, 14, 1, 799.99, 0.00);

-- 8 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(8, 16, 3, 59.99, 5.00),
(8, 18, 1, 249.99, 0.00);

-- 9 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(9, 19, 1, 499.99, 0.00),
(9, 20, 2, 79.99, 0.00);

-- 10 numaralı sipariş için
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(10, 21, 1, 599.99, 0.00),
(10, 22, 1, 149.99, 0.00);

-- Diğer siparişler için de benzer şekilde devam edebilirsiniz.
-- 11-20 arası siparişler için örnek veriler:
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES 
(11, 1, 1, 6999.99, 500.00),
(12, 2, 1, 12999.99, 1000.00),
(13, 6, 3, 249.99, 20.00),
(14, 11, 1, 899.99, 0.00),
(15, 21, 2, 599.99, 50.00),
(16, 3, 1, 1299.99, 0.00),
(17, 7, 2, 199.99, 10.00),
(18, 12, 1, 12999.99, 1500.00),
(19, 16, 5, 59.99, 5.00),
(20, 23, 1, 349.99, 0.00);

-- 6. Ödemeler tablosuna örnek veriler ekleyelim
INSERT INTO payments (order_id, payment_date, payment_method, amount, status) VALUES 
(1, DATE_SUB(NOW(), INTERVAL 2 DAY), 'credit_card', 8299.98, 'completed'),
(2, DATE_SUB(NOW(), INTERVAL 5 DAY), 'credit_card', 5999.98, 'completed'),
(3, DATE_SUB(NOW(), INTERVAL 10 DAY), 'paypal', 689.98, 'completed'),
(4, DATE_SUB(NOW(), INTERVAL 15 DAY), 'debit_card', 764.97, 'completed'),
(5, DATE_SUB(NOW(), INTERVAL 20 DAY), 'credit_card', 349.99, 'completed'),
(6, DATE_SUB(NOW(), INTERVAL 25 DAY), 'bank_transfer', 1649.97, 'completed'),
(7, DATE_SUB(NOW(), INTERVAL 30 DAY), 'credit_card', 799.99, 'completed'),
(8, DATE_SUB(NOW(), INTERVAL 35 DAY), 'paypal', 424.96, 'completed'),
(9, DATE_SUB(NOW(), INTERVAL 40 DAY), 'credit_card', 659.97, 'completed'),
(10, DATE_SUB(NOW(), INTERVAL 45 DAY), 'cash', 749.98, 'completed'),
(11, DATE_SUB(NOW(), INTERVAL 50 DAY), 'credit_card', 6499.99, 'completed'),
(12, DATE_SUB(NOW(), INTERVAL 55 DAY), 'debit_card', 11999.99, 'completed'),
(13, DATE_SUB(NOW(), INTERVAL 60 DAY), 'credit_card', 729.97, 'completed'),
(14, DATE_SUB(NOW(), INTERVAL 65 DAY), 'bank_transfer', 899.99, 'completed'),
(15, DATE_SUB(NOW(), INTERVAL 70 DAY), 'credit_card', 1149.98, 'completed'),
(16, DATE_SUB(NOW(), INTERVAL 75 DAY), 'paypal', 1299.99, 'completed'),
(17, DATE_SUB(NOW(), INTERVAL 80 DAY), 'credit_card', 389.98, 'completed'),
(18, DATE_SUB(NOW(), INTERVAL 85 DAY), 'debit_card', 11499.99, 'completed'),
(19, DATE_SUB(NOW(), INTERVAL 90 DAY), 'credit_card', 294.95, 'completed'),
(20, DATE_SUB(NOW(), INTERVAL 95 DAY), 'cash', 349.99, 'completed');

-- 7. İadeler tablosuna örnek veriler ekleyelim
INSERT INTO returns (order_id, return_date, reason, notes, status) VALUES 
(3, DATE_SUB(NOW(), INTERVAL 8 DAY), 'defective', 'Ürün kutusundan hasarlı çıktı.', 'completed'),
(8, DATE_SUB(NOW(), INTERVAL 32 DAY), 'wrong_item', 'Yanlış renk gönderilmiş.', 'completed'),
(12, DATE_SUB(NOW(), INTERVAL 53 DAY), 'not_as_described', 'Ürün açıklamada belirtilenden farklı.', 'completed'),
(15, DATE_SUB(NOW(), INTERVAL 68 DAY), 'defective', 'Ürün çalışmıyor.', 'completed');

-- 8. İade Kalemleri tablosuna örnek veriler ekleyelim
INSERT INTO return_items (return_id, order_item_id, quantity) VALUES 
(1, 6, 1), -- 3 numaralı siparişten 6 numaralı sipariş kalemi iade edildi
(2, 15, 1), -- 8 numaralı siparişten 15 numaralı sipariş kalemi iade edildi
(3, 24, 1), -- 12 numaralı siparişten 24 numaralı sipariş kalemi iade edildi
(4, 29, 1); -- 15 numaralı siparişten 29 numaralı sipariş kalemi iade edildi

-- 9. Kampanyalar tablosuna örnek veriler ekleyelim
INSERT INTO campaigns (campaign_name, description, start_date, end_date, discount_type, discount_value, budget, status) VALUES 
('Yaz İndirimleri', 'Yaz mevsimi indirimleri', '2023-06-01', '2023-08-31', 'percentage', 15.00, 50000.00, 'finished'),
('Kara Cuma', 'Büyük Cuma indirimleri', '2023-11-24', '2023-11-26', 'percentage', 25.00, 100000.00, 'finished'),
('Yeni Yıl Kampanyası', 'Yeni yıl özel indirimleri', '2023-12-15', '2024-01-15', 'percentage', 20.00, 75000.00, 'active'),
('Bahar Fırsatları', 'Bahar alışverişlerinde özel fırsatlar', '2024-03-01', '2024-04-30', 'percentage', 10.00, 30000.00, 'planned'),
('Elektronik Festivali', 'Elektronik ürünlerde büyük indirimler', '2023-10-01', '2023-10-15', 'fixed_amount', 500.00, 40000.00, 'finished');

-- 10. Kampanya Ürünleri tablosuna örnek veriler ekleyelim
-- Yaz İndirimleri kampanyasına dahil ürünler
INSERT INTO campaign_products (campaign_id, product_id) VALUES 
(1, 5), -- Tablet Pro
(1, 6), -- Erkek Slim Fit Gömlek
(1, 7), -- Kadın Triko Kazak
(1, 8), -- Unisex Sweatshirt
(1, 9), -- Erkek Kot Pantolon
(1, 10); -- Kadın Elbise

-- Kara Cuma kampanyasına dahil ürünler
INSERT INTO campaign_products (campaign_id, product_id) VALUES 
(2, 1), -- Akıllı Telefon X
(2, 2), -- Laptop Pro
(2, 3), -- Kablosuz Kulaklık
(2, 4), -- Akıllı Saat
(2, 5); -- Tablet Pro

-- Yeni Yıl Kampanyası'na dahil ürünler
INSERT INTO campaign_products (campaign_id, product_id) VALUES 
(3, 11), -- Yemek Takımı
(3, 12), -- Koltuk Takımı
(3, 13), -- Yatak Örtüsü
(3, 14), -- LED Avize
(3, 15); -- Tencere Seti

-- Bahar Fırsatları'na dahil ürünler
INSERT INTO campaign_products (campaign_id, product_id) VALUES 
(4, 16), -- Modern Klasikler
(4, 17), -- Bilim Ansiklopedisi
(4, 18), -- Kişisel Gelişim Seti
(4, 19), -- Dünya Klasikleri
(4, 20); -- Tarih Kitabı

-- Elektronik Festivali'ne dahil ürünler
INSERT INTO campaign_products (campaign_id, product_id) VALUES 
(5, 1), -- Akıllı Telefon X
(5, 2), -- Laptop Pro
(5, 3), -- Kablosuz Kulaklık
(5, 4), -- Akıllı Saat
(5, 5); -- Tablet Pro

-- 11. Envanter tablosuna örnek veriler ekleyelim
INSERT INTO inventory (product_id, warehouse_id, quantity) VALUES 
(1, 1, 100),
(1, 2, 50),
(2, 1, 50),
(2, 2, 25),
(3, 1, 150),
(3, 2, 50),
(4, 1, 80),
(4, 2, 40),
(5, 1, 60),
(5, 2, 25),
(6, 1, 200),
(6, 2, 100),
(7, 1, 150),
(7, 2, 100),
(8, 1, 300),
(8, 2, 100),
(9, 1, 200),
(9, 2, 80),
(10, 1, 150),
(10, 2, 70);

-- 12. Tıklama Akışı Verileri tablosuna örnek veriler ekleyelim
-- Bu verilerin tarihleri, son 1 hafta içindeki rastgele tarih ve saatleri temsil eder
INSERT INTO click_stream_data (visitor_id, customer_id, page_url, event_type, product_id, referral_source, timestamp, session_id, device_type) VALUES 
('vis_001', 1, 'https://example.com/', 'page_view', NULL, 'google', NOW() - INTERVAL 1 HOUR, 'sess_001', 'desktop'),
('vis_001', 1, 'https://example.com/products', 'page_view', NULL, 'google', NOW() - INTERVAL 59 MINUTE, 'sess_001', 'desktop'),
('vis_001', 1, 'https://example.com/products/1', 'product_view', 1, 'google', NOW() - INTERVAL 58 MINUTE, 'sess_001', 'desktop'),
('vis_001', 1, 'https://example.com/cart', 'add_to_cart', 1, 'google', NOW() - INTERVAL 55 MINUTE, 'sess_001', 'desktop'),
('vis_001', 1, 'https://example.com/checkout', 'checkout', NULL, 'google', NOW() - INTERVAL 50 MINUTE, 'sess_001', 'desktop'),
('vis_001', 1, 'https://example.com/order_confirmation', 'purchase', NULL, 'google', NOW() - INTERVAL 45 MINUTE, 'sess_001', 'desktop'),

('vis_002', 2, 'https://example.com/', 'page_view', NULL, 'direct', NOW() - INTERVAL 2 HOUR, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/products', 'page_view', NULL, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 55 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/products/5', 'product_view', 5, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 50 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/products/4', 'product_view', 4, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 45 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/cart', 'add_to_cart', 5, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 40 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/cart', 'add_to_cart', 4, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 39 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/checkout', 'checkout', NULL, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 35 MINUTE, 'sess_002', 'mobile'),
('vis_002', 2, 'https://example.com/order_confirmation', 'purchase', NULL, 'direct', NOW() - INTERVAL 1 HOUR - INTERVAL 30 MINUTE, 'sess_002', 'mobile'),

('vis_003', 3, 'https://example.com/', 'page_view', NULL, 'facebook', NOW() - INTERVAL 3 HOUR, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/products', 'page_view', NULL, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 5 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/products/6', 'product_view', 6, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 10 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/products/7', 'product_view', 7, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 15 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/cart', 'add_to_cart', 6, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 20 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/cart', 'add_to_cart', 7, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 21 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/checkout', 'checkout', NULL, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 25 MINUTE, 'sess_003', 'tablet'),
('vis_003', 3, 'https://example.com/order_confirmation', 'purchase', NULL, 'facebook', NOW() - INTERVAL 3 HOUR + INTERVAL 30 MINUTE, 'sess_003', 'tablet'),

('vis_004', 4, 'https://example.com/', 'page_view', NULL, 'instagram', NOW() - INTERVAL 4 HOUR, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/products', 'page_view', NULL, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 5 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/products/8', 'product_view', 8, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 10 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/products/9', 'product_view', 9, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 15 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/cart', 'add_to_cart', 8, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 20 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/cart', 'add_to_cart', 9, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 21 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/checkout', 'checkout', NULL, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 25 MINUTE, 'sess_004', 'mobile'),
('vis_004', 4, 'https://example.com/order_confirmation', 'purchase', NULL, 'instagram', NOW() - INTERVAL 4 HOUR + INTERVAL 30 MINUTE, 'sess_004', 'mobile'),

('vis_005', 5, 'https://example.com/', 'page_view', NULL, 'google', NOW() - INTERVAL 5 HOUR, 'sess_005', 'desktop'),
('vis_005', 5, 'https://example.com/products', 'page_view', NULL, 'google', NOW() - INTERVAL 5 HOUR + INTERVAL 5 MINUTE, 'sess_005', 'desktop'),
('vis_005', 5, 'https://example.com/products/10', 'product_view', 10, 'google', NOW() - INTERVAL 5 HOUR + INTERVAL 10 MINUTE, 'sess_005', 'desktop'),
('vis_005', 5, 'https://example.com/cart', 'add_to_cart', 10, 'google', NOW() - INTERVAL 5 HOUR + INTERVAL 15 MINUTE, 'sess_005', 'desktop'),
('vis_005', 5, 'https://example.com/checkout', 'checkout', NULL, 'google', NOW() - INTERVAL 5 HOUR + INTERVAL 20 MINUTE, 'sess_005', 'desktop'),
('vis_005', 5, 'https://example.com/order_confirmation', 'purchase', NULL, 'google', NOW() - INTERVAL 5 HOUR + INTERVAL 25 MINUTE, 'sess_005', 'desktop'),

-- Ayrıca tamamlanmamış kullanıcı yolculukları da ekleyelim
('vis_006', NULL, 'https://example.com/', 'page_view', NULL, 'twitter', NOW() - INTERVAL 30 MINUTE, 'sess_006', 'mobile'),
('vis_006', NULL, 'https://example.com/products', 'page_view', NULL, 'twitter', NOW() - INTERVAL 28 MINUTE, 'sess_006', 'mobile'),
('vis_006', NULL, 'https://example.com/products/1', 'product_view', 1, 'twitter', NOW() - INTERVAL 25 MINUTE, 'sess_006', 'mobile'),
('vis_006', NULL, 'https://example.com/products/3', 'product_view', 3, 'twitter', NOW() - INTERVAL 20 MINUTE, 'sess_006', 'mobile'),
-- Bu kullanıcı sepete ürün eklemeden ayrıldı

('vis_007', 6, 'https://example.com/', 'page_view', NULL, 'bing', NOW() - INTERVAL 2 HOUR, 'sess_007', 'desktop'),
('vis_007', 6, 'https://example.com/products', 'page_view', NULL, 'bing', NOW() - INTERVAL 1 HOUR - INTERVAL 55 MINUTE, 'sess_007', 'desktop'),
('vis_007', 6, 'https://example.com/products/11', 'product_view', 11, 'bing', NOW() - INTERVAL 1 HOUR - INTERVAL 50 MINUTE, 'sess_007', 'desktop'),
('vis_007', 6, 'https://example.com/products/13', 'product_view', 13, 'bing', NOW() - INTERVAL 1 HOUR - INTERVAL 45 MINUTE, 'sess_007', 'desktop'),
('vis_007', 6, 'https://example.com/cart', 'add_to_cart', 11, 'bing', NOW() - INTERVAL 1 HOUR - INTERVAL 40 MINUTE, 'sess_007', 'desktop'),
('vis_007', 6, 'https://example.com/cart', 'add_to_cart', 13, 'bing', NOW() - INTERVAL 1 HOUR - INTERVAL 39 MINUTE, 'sess_007', 'desktop'),
-- Bu kullanıcı ödeme adımına geçmeden ayrıldı

('vis_008', 7, 'https://example.com/', 'page_view', NULL, 'direct', NOW() - INTERVAL 6 HOUR, 'sess_008', 'mobile'),
('vis_008', 7, 'https://example.com/products', 'page_view', NULL, 'direct', NOW() - INTERVAL 6 HOUR + INTERVAL 5 MINUTE, 'sess_008', 'mobile'),
('vis_008', 7, 'https://example.com/products/14', 'product_view', 14, 'direct', NOW() - INTERVAL 6 HOUR + INTERVAL 10 MINUTE, 'sess_008', 'mobile'),
('vis_008', 7, 'https://example.com/cart', 'add_to_cart', 14, 'direct', NOW() - INTERVAL 6 HOUR + INTERVAL 15 MINUTE, 'sess_008', 'mobile'),
('vis_008', 7, 'https://example.com/checkout', 'checkout', NULL, 'direct', NOW() - INTERVAL 6 HOUR + INTERVAL 20 MINUTE, 'sess_008', 'mobile');
-- Bu kullanıcı ödeme adımını tamamlamadan ayrıldı

-- Daha fazla tıklama verisi eklenebilir.

-- Örnek veri oluşturma işlemi tamamlandı.
SELECT 'Örnek veriler başarıyla oluşturuldu ve eklendi.' AS message;

-- Not: Bu veriler örnek amaçlıdır ve gerçek verileri temsil etmez.
-- Gerçek bir projede, daha fazla ve daha gerçekçi veriler kullanılmalıdır.
-- Ayrıca, bu veritabanı şeması ve veriler, ihtiyaçlarınıza göre uyarlanabilir.