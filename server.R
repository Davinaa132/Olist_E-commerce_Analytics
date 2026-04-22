library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)
library(plotly)
library(scales)
library(lubridate)

server <- function(input, output, session) {

  # ── Koneksi Database ─────────────────────────────
  server <- function(input, output, session) {

  # ── Koneksi Database ─────────────────────────────
  con <- tryCatch({
  dbConnect(
    RPostgres::Postgres(),
    dbname   = "postgres",
    host     = "db.jcutvplvmttgkbbxmexo.supabase.co",
    port     = 5432,
    user     = "postgres",
    password = "BXj$VvYf5Y#9UKt",   # ← isi password Supabase kamu
    sslmode  = "require"
  )
}, error = function(e) {
  showNotification(
    paste("Gagal konek ke database:", e$message),
    type = "error", duration = NULL
  )
  NULL
})

  # ── Helper: filter tahun pada query ──────────────
  year_clause <- reactive({
    if (input$year_filter == "All") ""
    else paste0("AND EXTRACT(YEAR FROM o.order_purchase_timestamp) = ", input$year_filter)
  })

  # ═══════════════════════════════════════
  # OVERVIEW
  # ═══════════════════════════════════════
  overview_data <- reactive({
    dbGetQuery(con, paste0("
      SELECT
        COUNT(DISTINCT o.order_id)                           AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(r.review_score)::NUMERIC, 2)              AS avg_rating,
        COUNT(DISTINCT c.customer_unique_id)                 AS total_customers
      FROM orders o
      JOIN order_items oi ON o.order_id = oi.order_id
      JOIN customers c    ON o.customer_id = c.customer_id
      LEFT JOIN order_reviews r ON o.order_id = r.order_id
      WHERE o.order_status = 'delivered' ", year_clause()
    ))
  })

  output$box_total_orders <- renderValueBox({
    valueBox(
      format(overview_data()$total_orders, big.mark = ","),
      "Total Orders", icon = icon("shopping-cart"), color = "blue"
    )
  })
  output$box_total_revenue <- renderValueBox({
    valueBox(
      paste0("R$ ", format(round(overview_data()$total_revenue / 1e6, 1), nsmall = 1), "M"),
      "Total Revenue", icon = icon("dollar-sign"), color = "green"
    )
  })
  output$box_avg_rating <- renderValueBox({
    valueBox(
      overview_data()$avg_rating,
      "Avg Review Score", icon = icon("star"), color = "yellow"
    )
  })
  output$box_total_customers <- renderValueBox({
    valueBox(
      format(overview_data()$total_customers, big.mark = ","),
      "Unique Customers", icon = icon("users"), color = "purple"
    )
  })

  # Overview trend chart
  output$overview_trend <- renderPlotly({
    df <- dbGetQuery(con, paste0("
      SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
             COUNT(DISTINCT o.order_id) AS orders
      FROM orders o
      WHERE o.order_status = 'delivered' ", year_clause(), "
      GROUP BY 1 ORDER BY 1"))
    df$month <- as.Date(df$month)
    plot_ly(df, x = ~month, y = ~orders, type = "scatter", mode = "lines+markers",
            line = list(color = "#3C8DBC", width = 2),
            marker = list(color = "#3C8DBC", size = 6)) %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Orders"),
             hovermode = "x unified")
  })

  # Order status pie
  output$overview_status <- renderPlotly({
    df <- dbGetQuery(con, "
      SELECT order_status, COUNT(*) AS n FROM orders GROUP BY 1 ORDER BY 2 DESC")
    plot_ly(df, labels = ~order_status, values = ~n, type = "pie",
            hole = 0.4,
            marker = list(colors = c("#3C8DBC","#00A65A","#F39C12","#DD4B39","#605CA8","#D2D6DE"))) %>%
      layout(showlegend = TRUE, legend = list(orientation = "v"))
  })

  # ═══════════════════════════════════════
  # REVENUE TAB
  # ═══════════════════════════════════════
  revenue_data <- reactive({
    dbGetQuery(con, paste0("
      SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)            AS month,
        COUNT(DISTINCT o.order_id)                                 AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)       AS total_revenue,
        ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2)       AS avg_order_value
      FROM orders o
      JOIN order_items oi ON o.order_id = oi.order_id
      WHERE o.order_status = 'delivered' ", year_clause(), "
      GROUP BY 1 ORDER BY 1"))
  })

  output$revenue_trend <- renderPlotly({
    df <- revenue_data()
    df$month <- as.Date(df$month)
    plot_ly(df) %>%
      add_bars(x = ~month, y = ~total_revenue, name = "Revenue",
               marker = list(color = "#00A65A", opacity = 0.8)) %>%
      add_lines(x = ~month, y = ~avg_order_value, name = "Avg Order Value",
                yaxis = "y2", line = list(color = "#F39C12", width = 2)) %>%
      layout(
        yaxis  = list(title = "Total Revenue (R$)"),
        yaxis2 = list(title = "Avg Order Value (R$)", overlaying = "y", side = "right"),
        xaxis  = list(title = ""), hovermode = "x unified",
        legend = list(orientation = "h", y = -0.15)
      )
  })

  output$revenue_table <- renderDT({
    df <- revenue_data()
    df$month         <- format(as.Date(df$month), "%B %Y")
    df$total_revenue <- paste0("R$ ", format(df$total_revenue, big.mark = ","))
    df$avg_order_value <- paste0("R$ ", format(df$avg_order_value, big.mark = ","))
    datatable(df, colnames = c("Month","Orders","Total Revenue","Avg Order Value"),
              options = list(pageLength = 15, dom = "frtip"))
  })

  # ═══════════════════════════════════════
  # PRODUCTS TAB
  # ═══════════════════════════════════════
  output$top_categories <- renderPlotly({
    df <- dbGetQuery(con, paste0("
      SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
             ROUND(SUM(oi.price)::NUMERIC, 2) AS total_revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.product_id
      LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
      JOIN orders o ON oi.order_id = o.order_id
      WHERE o.order_status = 'delivered' ", year_clause(), "
      GROUP BY 1 ORDER BY 2 DESC LIMIT 10"))
    df$category <- factor(df$category, levels = rev(df$category))
    plot_ly(df, x = ~total_revenue, y = ~category, type = "bar", orientation = "h",
            marker = list(color = "#3C8DBC")) %>%
      layout(xaxis = list(title = "Revenue (R$)"), yaxis = list(title = ""))
  })

  output$avg_price_cat <- renderPlotly({
    df <- dbGetQuery(con, paste0("
      SELECT COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
             ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_price
      FROM order_items oi
      JOIN products p ON oi.product_id = p.product_id
      LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
      JOIN orders o ON oi.order_id = o.order_id
      WHERE o.order_status = 'delivered' ", year_clause(), "
      GROUP BY 1 ORDER BY 2 DESC LIMIT 10"))
    df$category <- factor(df$category, levels = rev(df$category))
    plot_ly(df, x = ~avg_price, y = ~category, type = "bar", orientation = "h",
            marker = list(color = "#F39C12")) %>%
      layout(xaxis = list(title = "Avg Price (R$)"), yaxis = list(title = ""))
  })

  # ═══════════════════════════════════════
  # CUSTOMERS (RFM) TAB
  # ═══════════════════════════════════════
  rfm_data <- reactive({
    dbGetQuery(con, "
      WITH rfm_base AS (
        SELECT c.customer_unique_id,
               MAX(o.order_purchase_timestamp) AS last_order_date,
               COUNT(DISTINCT o.order_id) AS frequency,
               ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS monetary
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
      ),
      rfm_scores AS (
        SELECT *,
          NTILE(4) OVER (ORDER BY DATE_PART('day', NOW()-last_order_date) DESC) AS r_score,
          NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
          NTILE(4) OVER (ORDER BY monetary ASC)  AS m_score
        FROM rfm_base
      )
      SELECT
        CASE
          WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
          WHEN r_score >= 3 AND f_score >= 2                  THEN 'Loyal Customers'
          WHEN r_score >= 3 AND f_score = 1                   THEN 'Recent Customers'
          WHEN r_score = 2  AND f_score >= 2                  THEN 'At Risk'
          ELSE 'Lost Customers'
        END AS segment,
        COUNT(*) AS customer_count,
        ROUND(AVG(monetary)::NUMERIC, 2) AS avg_monetary
      FROM rfm_scores
      GROUP BY segment ORDER BY customer_count DESC")
  })

  output$rfm_pie <- renderPlotly({
    df <- rfm_data()
    colors <- c("#3C8DBC","#00A65A","#F39C12","#DD4B39","#605CA8")
    plot_ly(df, labels = ~segment, values = ~customer_count, type = "pie",
            hole = 0.45, marker = list(colors = colors)) %>%
      layout(showlegend = TRUE)
  })

  output$rfm_bar <- renderPlotly({
    df <- rfm_data()
    df$segment <- factor(df$segment, levels = df$segment)
    plot_ly(df, x = ~segment, y = ~avg_monetary, type = "bar",
            marker = list(color = c("#3C8DBC","#00A65A","#F39C12","#DD4B39","#605CA8"))) %>%
      layout(xaxis = list(title = ""), yaxis = list(title = "Avg Monetary (R$)"))
  })

  output$rfm_table <- renderDT({
    df <- rfm_data()
    df$avg_monetary <- paste0("R$ ", format(df$avg_monetary, big.mark = ","))
    datatable(df, colnames = c("Segment","Customer Count","Avg Monetary Value"),
              options = list(dom = "t", pageLength = 10))
  })

  # ═══════════════════════════════════════
  # DELIVERY TAB
  # ═══════════════════════════════════════
  delivery_data <- reactive({
    dbGetQuery(con, paste0("
      SELECT c.customer_state,
             COUNT(o.order_id) AS total_orders,
             ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400)::NUMERIC,1) AS avg_days,
             ROUND(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) / COUNT(*), 1) AS ontime_pct
      FROM orders o
      JOIN customers c ON o.customer_id = c.customer_id
      WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL ", year_clause(), "
      GROUP BY c.customer_state
      HAVING COUNT(o.order_id) >= 30
      ORDER BY avg_days DESC LIMIT 15"))
  })

  output$delivery_state <- renderPlotly({
    df <- delivery_data()
    df$customer_state <- factor(df$customer_state, levels = df$customer_state)
    plot_ly(df, x = ~avg_days, y = ~customer_state, type = "bar", orientation = "h",
            marker = list(color = ~avg_days,
                          colorscale = list(c(0,"#00A65A"), c(0.5,"#F39C12"), c(1,"#DD4B39"))),
            text = ~paste0(avg_days, " days"), textposition = "outside") %>%
      layout(xaxis = list(title = "Avg Delivery Days"), yaxis = list(title = "State"))
  })

  output$ontime_gauge <- renderPlotly({
    df <- delivery_data()
    overall_pct <- round(mean(df$ontime_pct, na.rm = TRUE), 1)
    plot_ly(
      type = "indicator", mode = "gauge+number",
      value = overall_pct,
      title = list(text = "On-Time Rate (%)"),
      gauge = list(
        axis = list(range = list(0, 100)),
        bar   = list(color = "#00A65A"),
        steps = list(
          list(range = c(0, 60),  color = "#FADBD8"),
          list(range = c(60, 80), color = "#FDEBD0"),
          list(range = c(80, 100),color = "#D5F5E3")
        ),
        threshold = list(line = list(color = "#DD4B39", width = 2), value = 80)
      )
    ) %>% layout(margin = list(t = 60))
  })

  # ═══════════════════════════════════════
  # PAYMENTS TAB
  # ═══════════════════════════════════════
  payment_data <- reactive({
    dbGetQuery(con, "
      SELECT payment_type,
             COUNT(DISTINCT order_id) AS total_transactions,
             ROUND(SUM(payment_value)::NUMERIC, 2) AS total_revenue,
             ROUND(AVG(payment_value)::NUMERIC, 2) AS avg_payment,
             ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS pct_share
      FROM order_payments
      GROUP BY payment_type ORDER BY total_revenue DESC")
  })

  output$payment_pie <- renderPlotly({
    df <- payment_data()
    plot_ly(df, labels = ~payment_type, values = ~pct_share, type = "pie",
            hole = 0.4, textinfo = "label+percent") %>%
      layout(showlegend = FALSE)
  })

  output$payment_bar <- renderPlotly({
    df <- payment_data()
    df$payment_type <- factor(df$payment_type, levels = rev(df$payment_type))
    plot_ly(df, x = ~total_revenue, y = ~payment_type, type = "bar", orientation = "h",
            marker = list(color = "#605CA8"),
            text = ~paste0("R$ ", format(total_revenue, big.mark = ",")),
            textposition = "outside") %>%
      layout(xaxis = list(title = "Revenue (R$)"), yaxis = list(title = ""))
  })

  # ═══════════════════════════════════════
  # SELLERS TAB
  # ═══════════════════════════════════════
  seller_data <- reactive({
    dbGetQuery(con, paste0("
      SELECT s.seller_id, s.seller_state,
             COUNT(DISTINCT oi.order_id)          AS total_orders,
             ROUND(SUM(oi.price)::NUMERIC, 2)     AS total_revenue,
             ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_rating
      FROM sellers s
      JOIN order_items oi ON s.seller_id = oi.seller_id
      JOIN orders o       ON oi.order_id = o.order_id
      LEFT JOIN order_reviews r ON o.order_id = r.order_id
      WHERE o.order_status = 'delivered' ", year_clause(), "
      GROUP BY s.seller_id, s.seller_state
      HAVING COUNT(DISTINCT oi.order_id) >= 10
      ORDER BY total_revenue DESC LIMIT 20"))
  })

  output$seller_table <- renderDT({
    df <- seller_data()
    df$seller_id    <- substr(df$seller_id, 1, 8)  # shortening for display
    df$total_revenue <- paste0("R$ ", format(df$total_revenue, big.mark = ","))
    datatable(df,
              colnames = c("Seller ID","State","Orders","Revenue","Avg Rating"),
              options  = list(pageLength = 10, dom = "frtip"),
              rownames = FALSE)
  })

  output$seller_scatter <- renderPlotly({
    df <- seller_data()
    plot_ly(df, x = ~total_revenue, y = ~avg_rating,
            type = "scatter", mode = "markers",
            color = ~seller_state,
            marker = list(
              opacity = 0.8,
              size = 14          # ukuran tetap, tidak pakai size dinamis
            ),
            text = ~paste0("State: ", seller_state,
                           "<br>Orders: ", total_orders,
                           "<br>Revenue: R$ ", format(total_revenue, big.mark = ",")),
            hoverinfo = "text") %>%
      layout(xaxis = list(title = "Total Revenue (R$)"),
             yaxis = list(title = "Avg Review Score"))
  })
}
