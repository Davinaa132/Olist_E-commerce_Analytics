\COPY customers FROM 'D:/TUGAS DAP/olist-analytics/data/olist_customers_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\COPY sellers FROM 'D:/TUGAS DAP/olist-analytics/data/olist_sellers_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\COPY products FROM 'D:/TUGAS DAP/olist-analytics/data/olist_products_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

\COPY category_translation FROM 'D:/TUGAS DAP/olist-analytics/data/product_category_name_translation.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\COPY orders FROM 'D:/TUGAS DAP/olist-analytics/data/olist_orders_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

\COPY order_items FROM 'D:/TUGAS DAP/olist-analytics/data/olist_order_items_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\COPY order_payments FROM 'D:/TUGAS DAP/olist-analytics/data/olist_order_payments_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

\COPY order_reviews FROM 'D:/TUGAS DAP/olist-analytics/data/olist_order_reviews_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '', ENCODING 'UTF8');

\COPY geolocation FROM 'D:/TUGAS DAP/olist-analytics/data/olist_geolocation_dataset.csv'
  WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');