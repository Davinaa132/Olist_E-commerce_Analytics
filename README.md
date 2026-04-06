# Brazilian E-Commerce Analytics Dashboard

Interactive analytics dashboard for Olist's Brazilian e-commerce dataset,
built with PostgreSQL + R Shiny.
https://davinamufidah.shinyapps.io/shiny

## Features
- **Revenue Trend** — Monthly GMV and average order value
- **Product Analysis** — Top categories by revenue and price
- **RFM Segmentation** — Customer segmentation (Champions, Loyal, At Risk, Lost)
- **Delivery Performance** — On-time rate by state
- **Payment Methods** — Distribution and revenue breakdown
- **Seller Leaderboard** — Top sellers with rating vs revenue scatter

## Tech Stack
- **Database:** PostgreSQL 15
- **Language:** R 4.x
- **Packages:** Shiny, shinydashboard, DBI, RPostgres, plotly, DT, dplyr
- **IDE:** VS Code

## Dataset
Olist Brazilian E-Commerce Public Dataset — 100k orders (2016–2018)
Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Setup
1. Clone this repo
2. Import CSV to PostgreSQL: `psql -U postgres -d olist_db -f sql/01_create_schema.sql`
3. Load data: `psql -U postgres -d olist_db -f sql/02_import_data.sql`
4. Run app: `Rscript -e "shiny::runApp('shiny')"`

## Key SQL Concepts Demonstrated
- Window functions (NTILE, SUM OVER)
- CTEs for RFM analysis
- Multi-table JOINs
- Date arithmetic with EXTRACT/EPOCH
- Conditional aggregation with CASE WHEN
