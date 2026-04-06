-- -----------------------------------------------
-- QUERY 1: Monthly Revenue Trend
-- Melihat tren pendapatan per bulan
-- -----------------------------------------------
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id)                       AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- -----------------------------------------------
-- QUERY 2: Top 10 Product Categories by Revenue
-- -----------------------------------------------
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT oi.order_id)                                                     AS orders_count,
    ROUND(SUM(oi.price)::NUMERIC, 2)                                                AS total_revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2)                                                AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- -----------------------------------------------
-- QUERY 3: Customer Segmentation (RFM Analysis)
-- Recency, Frequency, Monetary
-- -----------------------------------------------
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)                     AS last_order_date,
        COUNT(DISTINCT o.order_id)                          AS frequency,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT *,
        DATE_PART('day', NOW() - last_order_date) AS recency_days,
        NTILE(4) OVER (ORDER BY DATE_PART('day', NOW() - last_order_date) DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)  AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)   AS m_score
    FROM rfm_base
)
SELECT
    r_score, f_score, m_score,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score = 1                   THEN 'Recent Customers'
        WHEN r_score = 2 AND f_score >= 2                   THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary)::NUMERIC, 2) AS avg_monetary
FROM rfm_scores
GROUP BY r_score, f_score, m_score,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score = 1                   THEN 'Recent Customers'
        WHEN r_score = 2 AND f_score >= 2                   THEN 'At Risk'
        ELSE 'Lost Customers'
    END
ORDER BY customer_count DESC;

-- -----------------------------------------------
-- QUERY 4: Delivery Performance Analysis
-- Perbandingan estimasi vs aktual pengiriman
-- -----------------------------------------------
SELECT
    o.order_status,
    c.customer_state,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400
    )::NUMERIC, 1) AS avg_delivery_days,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date)) / 86400
    )::NUMERIC, 1) AS avg_early_days, -- positif = lebih cepat dari estimasi
    COUNT(CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
    END) AS on_time_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY o.order_status, c.customer_state
ORDER BY total_orders DESC;

-- -----------------------------------------------
-- QUERY 5: Payment Method Distribution & Revenue
-- -----------------------------------------------
SELECT
    payment_type,
    COUNT(DISTINCT order_id)           AS total_transactions,
    ROUND(SUM(payment_value)::NUMERIC, 2) AS total_revenue,
    ROUND(AVG(payment_value)::NUMERIC, 2) AS avg_payment,
    ROUND(AVG(payment_installments)::NUMERIC, 1) AS avg_installments,
    ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS pct_share
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- -----------------------------------------------
-- QUERY 6: Seller Performance Leaderboard
-- -----------------------------------------------
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                       AS total_orders,
    COUNT(DISTINCT oi.product_id)                     AS unique_products,
    ROUND(SUM(oi.price)::NUMERIC, 2)                  AS total_revenue,
    ROUND(AVG(r.review_score)::NUMERIC, 2)            AS avg_rating,
    ROUND(AVG(oi.freight_value)::NUMERIC, 2)          AS avg_freight
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT oi.order_id) >= 10
ORDER BY total_revenue DESC
LIMIT 20;