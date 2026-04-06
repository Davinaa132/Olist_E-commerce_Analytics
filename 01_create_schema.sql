CREATE TABLE IF NOT EXISTS customers (
    customer_id          VARCHAR(50) PRIMARY KEY,
    customer_unique_id   VARCHAR(50),
    customer_zip_code    VARCHAR(10),
    customer_city        VARCHAR(100),
    customer_state       CHAR(2)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR(50) PRIMARY KEY,
    customer_id                   VARCHAR(50) REFERENCES customers(customer_id),
    order_status                  VARCHAR(20),
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR(50) REFERENCES orders(order_id),
    order_item_id       INTEGER,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR(50) REFERENCES orders(order_id),
    payment_sequential   INTEGER,
    payment_type         VARCHAR(30),
    payment_installments INTEGER,
    payment_value        NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               VARCHAR(50) PRIMARY KEY,
    order_id                VARCHAR(50) REFERENCES orders(order_id),
    review_score            SMALLINT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_length        INTEGER,
    product_description_length INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           NUMERIC(10,2),
    product_length_cm          NUMERIC(8,2),
    product_height_cm          NUMERIC(8,2),
    product_width_cm           NUMERIC(8,2)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id        VARCHAR(50) PRIMARY KEY,
    seller_zip_code  VARCHAR(10),
    seller_city      VARCHAR(100),
    seller_state     CHAR(2)
);

CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat              NUMERIC(10,6),
    geolocation_lng              NUMERIC(10,6),
    geolocation_city             VARCHAR(100),
    geolocation_state            CHAR(2)
);