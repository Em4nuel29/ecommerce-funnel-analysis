# E-Commerce Funnel Analysis

A end-to-end data analytics portfolio project covering data generation, SQL analysis in PostgreSQL, and Tableau dashboard visualization.

---

## Project Overview

This project analyzes a simulated e-commerce dataset of 10,000 user sessions across four funnel stages: Browse, Add to Cart, Checkout, and Purchase. The goal was to identify where users drop off in the purchase funnel and surface actionable business insights by channel, device, region, and product category.

**Tools used:** Python · PostgreSQL · pgAdmin · Tableau Public

---

## Repository Contents

```
ecommerce-funnel-analysis/
│
├── data/
│   └── funnel_analysis_data.csv        # Raw synthetic dataset (10,000 sessions)
│
├── sql/
│   └── funnel_analysis.sql             # All SQL: table creation, cleaning, analysis queries
│
├── tableau/
│   └── dashboard_screenshot.png        # Dashboard preview image
│
└── README.md
```

---

## Dataset

The dataset was generated using a custom Python script with the `faker` and `pandas` libraries. Each row represents one user event, with 10,000 total sessions simulated across:

| Column | Description |
|---|---|
| User_ID | Unique user identifier |
| Session_ID | Unique session identifier |
| Event | Funnel stage (Browse, Add to Cart, Checkout, Purchase) |
| Timestamp | Event datetime |
| Device | Mobile, Tablet, or Desktop |
| Region | East, West, North, South |
| Channel | Social Media, Organic, Google Ads, Email |
| Product_Category | Sports, Electronics, Home, Beauty, Fashion |
| Revenue | Revenue generated (Purchase events only) |
| Bounce_Flag | Raw bounce indicator from data generation |

---

## Data Pipeline

### 1. Raw ingestion
Loaded CSV into PostgreSQL table `funnel_data_raw`.

### 2. Data cleaning
Created `funnel_clean` with corrected data types and standardized values.

### 3. Session-level aggregation
Built `final_funnel_sessions` — one row per session — with:
- Stage flags: `has_browse`, `has_add_to_cart`, `has_checkout`, `has_purchase`
- Session revenue, start/end timestamps, total events
- Improved bounce definition: a session is a bounce only if it has exactly one event and that event is Browse

---

## Key SQL Queries

### Overall funnel volume
```sql
SELECT
    SUM(has_browse) AS browse,
    SUM(has_add_to_cart) AS add_to_cart,
    SUM(has_checkout) AS checkout,
    SUM(has_purchase) AS purchase
FROM final_funnel_sessions;
```

### Conversion rate by segment
```sql
SELECT
    channel,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS conversion_rate_pct
FROM final_funnel_sessions
GROUP BY channel
ORDER BY conversion_rate_pct DESC;
```

---

## Results

### Funnel Performance

| Stage | Sessions | Drop-off |
|---|---|---|
| Browse | 10,000 | — |
| Add to Cart | 7,048 | 29.5% |
| Checkout | 3,576 | 49.3% |
| Purchase | 1,115 | 68.8% |

**Overall conversion rate: 11.15% | Bounce rate: 29.52%**

### By Channel
| Channel | Conversion Rate |
|---|---|
| Social Media | 11.97% |
| Organic | 11.05% |
| Google Ads | 10.80% |
| Email | 10.77% |

### By Device
| Device | Conversion Rate |
|---|---|
| Mobile | 11.32% |
| Tablet | 11.11% |
| Desktop | 11.02% |

### By Region
| Region | Conversion Rate |
|---|---|
| East | 12.28% |
| West | 11.66% |
| North | 11.18% |
| South | 9.53% |

### By Product Category
| Category | Conversion Rate |
|---|---|
| Sports | 11.67% |
| Electronics | 11.42% |
| Home | 11.40% |
| Beauty | 11.18% |
| Fashion | 10.13% |

---

## Key Insights

1. **Biggest friction point is Add to Cart → Checkout** — nearly half of users who add items never reach checkout. This suggests issues with the checkout flow, unexpected costs, or a lack of urgency.

2. **South region is a high-priority problem** — it generates the most traffic (2,581 sessions) but converts at the lowest rate (9.53%), nearly 3 points below the East. Targeted offers or UX improvements in this region could yield significant revenue gains.

3. **Fashion underperforms across the board** — lowest conversion rate (10.13%) and lowest average revenue per session ($114.12) of all categories. Pricing strategy or product page quality may be factors.

4. **Google Ads has the worst revenue efficiency** — despite similar session volume to other channels, it generates the least total revenue and lowest average revenue per session, raising questions about paid campaign targeting.

5. **Email has the highest bounce rate (30.59%)** — suggesting a mismatch between email content and landing page experience.

6. **Mobile converts best (11.32%)** — contrary to typical e-commerce patterns where desktop outperforms mobile, suggesting a well-optimized mobile experience.

---

## Recommendations

- **Audit the checkout flow** — add progress indicators, reduce form fields, and display trust signals to address the 49% Add to Cart → Checkout drop.
- **Run targeted campaigns in the South region** — investigate whether pricing, shipping costs, or product mix is driving the conversion gap.
- **Review Fashion category pages** — A/B test product images, descriptions, and pricing against higher-performing categories like Sports.
- **Reassess Google Ads spend** — reallocate budget toward Social Media and Organic channels which deliver better revenue per session.
- **Improve email landing pages** — align email creative with destination page content to reduce the 30.59% bounce rate.

---

## Tableau Dashboard

[View the live dashboard on Tableau Public](https://public.tableau.com/app/profile/emanuel.ortega5911/viz/E-CommerceFunnelAnalysis_17808767596520/E-CommerceFunnelAnalysis?publish=yes) ← 

---

## How to Reproduce

1. Run the Python data generation script to produce `funnel_analysis_data.csv`
2. Create a PostgreSQL database called `ecommerce_funnel_project`
3. Run `funnel_analysis.sql` in order — it creates and populates all tables
4. Connect `final_funnel_sessions` to Tableau and use the provided workbook

---

*Dataset is fully synthetic. All user data was generated programmatically and does not represent real individuals.*
