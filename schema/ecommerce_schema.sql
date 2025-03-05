-- Örnek veritabanı oluşturma
CREATE DATABASE ecommerce_analysis;
USE ecommerce_analysis;

-- Kategoriler Tablosu
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ürünler Tablosu
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(200) NOT NULL,
    category_id INT,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Müşteriler Tablosu
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Siparişler Tablosu
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    shipping_address TEXT,
    shipping_city VARCHAR(100),
    shipping_country VARCHAR(100),
    shipping_postal_code VARCHAR(20),
    shipping_cost DECIMAL(10, 2) DEFAULT 0,
    order_source VARCHAR(50), -- web, mobile, store vs.
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Sipariş Kalemleri Tablosu
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Ödemeler Tablosu
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'cash') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- İadeler Tablosu
CREATE TABLE returns (
    return_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason ENUM('defective', 'wrong_item', 'not_as_described', 'no_longer_needed', 'other') NOT NULL,
    notes TEXT,
    status ENUM('pending', 'approved', 'rejected', 'completed') DEFAULT 'pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- İade Kalemleri Tablosu
CREATE TABLE return_items (
    return_item_id INT PRIMARY KEY AUTO_INCREMENT,
    return_id INT NOT NULL,
    order_item_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (return_id) REFERENCES returns(return_id),
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);

-- Kampanyalar Tablosu
CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY AUTO_INCREMENT,
    campaign_name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    discount_type ENUM('percentage', 'fixed_amount') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    budget DECIMAL(10, 2),
    status ENUM('planned', 'active', 'finished', 'cancelled') DEFAULT 'planned'
);

-- Kampanya Ürünleri Tablosu
CREATE TABLE campaign_products (
    campaign_id INT NOT NULL,
    product_id INT NOT NULL,
    PRIMARY KEY (campaign_id, product_id),
    FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Envanter Tablosu
CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    warehouse_id INT,
    quantity INT NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Tıklama Akışı Verileri
CREATE TABLE click_stream_data (
    click_id INT PRIMARY KEY AUTO_INCREMENT,
    visitor_id VARCHAR(100) NOT NULL,
    customer_id INT,
    page_url VARCHAR(500) NOT NULL,
    event_type ENUM('page_view', 'product_view', 'add_to_cart', 'checkout', 'purchase') NOT NULL,
    product_id INT,
    referral_source VARCHAR(200),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100),
    device_type VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);