library(shinydashboard)
library(plotly)
library(DT)

ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(title = "Olist E-Commerce Analytics"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview",          tabName = "overview",  icon = icon("chart-line")),
      menuItem("Revenue Trend",     tabName = "revenue",   icon = icon("dollar-sign")),
      menuItem("Product Categories",tabName = "products",  icon = icon("box")),
      menuItem("Customer Segments", tabName = "customers", icon = icon("users")),
      menuItem("Delivery Analysis", tabName = "delivery",  icon = icon("truck")),
      menuItem("Payment Methods",   tabName = "payments",  icon = icon("credit-card")),
      menuItem("Seller Performance",tabName = "sellers",   icon = icon("store"))
    ),
    br(),
    # Filter global: rentang tahun
    selectInput("year_filter", "Filter Tahun:",
                choices = c("All", "2016", "2017", "2018"),
                selected = "All")
  ),

  dashboardBody(
    tabItems(

      # ── TAB 1: Overview ──────────────────────────
      tabItem(tabName = "overview",
        fluidRow(
          valueBoxOutput("box_total_orders", width = 3),
          valueBoxOutput("box_total_revenue", width = 3),
          valueBoxOutput("box_avg_rating", width = 3),
          valueBoxOutput("box_total_customers", width = 3)
        ),
        fluidRow(
          box(title = "Monthly Orders Trend", width = 8,
              plotlyOutput("overview_trend", height = "300px")),
          box(title = "Order Status Breakdown", width = 4,
              plotlyOutput("overview_status", height = "300px"))
        )
      ),

      # ── TAB 2: Revenue ────────────────────────────
      tabItem(tabName = "revenue",
        fluidRow(
          box(title = "Monthly Revenue", width = 12,
              plotlyOutput("revenue_trend", height = "350px"))
        ),
        fluidRow(
          box(title = "Revenue Data Table", width = 12,
              DTOutput("revenue_table"))
        )
      ),

      # ── TAB 3: Products ───────────────────────────
      tabItem(tabName = "products",
        fluidRow(
          box(title = "Top 10 Categories by Revenue", width = 7,
              plotlyOutput("top_categories", height = "380px")),
          box(title = "Average Price per Category", width = 5,
              plotlyOutput("avg_price_cat", height = "380px"))
        )
      ),

      # ── TAB 4: Customers (RFM) ────────────────────
      tabItem(tabName = "customers",
        fluidRow(
          box(title = "Customer Segment Distribution", width = 6,
              plotlyOutput("rfm_pie", height = "340px")),
          box(title = "Average Monetary Value by Segment", width = 6,
              plotlyOutput("rfm_bar", height = "340px"))
        ),
        fluidRow(
          box(title = "Segment Details", width = 12,
              DTOutput("rfm_table"))
        )
      ),

      # ── TAB 5: Delivery ───────────────────────────
      tabItem(tabName = "delivery",
        fluidRow(
          box(title = "Avg Delivery Days by State", width = 8,
              plotlyOutput("delivery_state", height = "380px")),
          box(title = "On-time Delivery Rate", width = 4,
              plotlyOutput("ontime_gauge", height = "380px"))
        )
      ),

      # ── TAB 6: Payments ───────────────────────────
      tabItem(tabName = "payments",
        fluidRow(
          box(title = "Payment Method Share", width = 5,
              plotlyOutput("payment_pie", height = "340px")),
          box(title = "Revenue by Payment Type", width = 7,
              plotlyOutput("payment_bar", height = "340px"))
        )
      ),

      # ── TAB 7: Sellers ────────────────────────────
      tabItem(tabName = "sellers",
        fluidRow(
          box(title = "Top 20 Sellers by Revenue", width = 12,
              DTOutput("seller_table"))
        ),
        fluidRow(
          box(title = "Revenue vs Rating (Top Sellers)", width = 12,
              plotlyOutput("seller_scatter", height = "380px"))
        )
      )
    )
  )
)