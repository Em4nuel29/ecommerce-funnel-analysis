-- =========================================
-- E-commerce Funnel Analysis SQL
-- Project: ecommerce-funnel-analysis
-- Tool: PostgreSQL
-- =========================================

-- 1. Create raw table
CREATE TABLE funnel_data_raw (
    User_ID TEXT,
    Session_ID TEXT,
    Event TEXT,
    Timestamp TIMESTAMP,
    Device TEXT,
    Region TEXT,
    Channel TEXT,
    Product_Category TEXT,
    Revenue NUMERIC,
    Bounce_Flag TEXT
);

-- 2. Preview imported raw data
SELECT COUNT(*) AS total_rows
FROM funnel_data_raw;

SELECT *
FROM funnel_data_raw
LIMIT 10;

-- 3. Create cleaned table
CREATE TABLE funnel_clean AS
SELECT
    User_ID,
    Session_ID,
    Event,
    Timestamp,
    Device,
    Region,
    Channel,
    Product_Category,
    Revenue::NUMERIC AS Revenue,
    Bounce_Flag
FROM funnel_data_raw
WHERE User_ID IS NOT NULL
  AND Session_ID IS NOT NULL
  AND Event IS NOT NULL
  AND Timestamp IS NOT NULL;

-- 4. Validate cleaned data
SELECT COUNT(*) AS total_rows
FROM funnel_clean;

SELECT
    MIN(Revenue) AS min_revenue,
    MAX(Revenue) AS max_revenue,
    AVG(Revenue) AS avg_revenue
FROM funnel_clean
WHERE Event = 'Purchase';

-- 5. Create session summary table
CREATE TABLE session_summary AS
SELECT
    Session_ID,
    MIN(User_ID) AS User_ID,
    MIN(Timestamp) AS session_start,
    MAX(Timestamp) AS session_end,
    COUNT(*) AS total_events,
    MAX(CASE WHEN Event = 'Browse' THEN 1 ELSE 0 END) AS has_browse,
    MAX(CASE WHEN Event = 'Add to Cart' THEN 1 ELSE 0 END) AS has_add_to_cart,
    MAX(CASE WHEN Event = 'Checkout' THEN 1 ELSE 0 END) AS has_checkout,
    MAX(CASE WHEN Event = 'Purchase' THEN 1 ELSE 0 END) AS has_purchase,
    MAX(CASE WHEN Event = 'Purchase' THEN Revenue ELSE 0 END) AS session_revenue
FROM funnel_clean
GROUP BY Session_ID;

-- 6. Capture first event attributes for each session
CREATE TABLE session_first_event AS
SELECT DISTINCT ON (Session_ID)
    Session_ID,
    User_ID,
    Device,
    Region,
    Channel,
    Product_Category,
    Timestamp
FROM funnel_clean
ORDER BY Session_ID, Timestamp;

-- 7. Create corrected bounce flag
CREATE TABLE session_summary_final AS
SELECT
    *,
    CASE
        WHEN total_events = 1 AND has_browse = 1 THEN 'Yes'
        ELSE 'No'
    END AS true_bounce_flag
FROM session_summary;

-- 8. Create final Tableau-ready table
CREATE TABLE final_funnel_sessions AS
SELECT
    s.Session_ID,
    s.User_ID,
    s.session_start,
    s.session_end,
    s.total_events,
    s.has_browse,
    s.has_add_to_cart,
    s.has_checkout,
    s.has_purchase,
    s.session_revenue,
    s.true_bounce_flag,
    f.Device,
    f.Region,
    f.Channel,
    f.Product_Category
FROM session_summary_final s
LEFT JOIN session_first_event f
    ON s.Session_ID = f.Session_ID;

-- 9. Preview final table
SELECT COUNT(*) AS total_rows
FROM final_funnel_sessions;

SELECT *
FROM final_funnel_sessions
LIMIT 10;

SELECT *
FROM final_funnel_sessions;

-- 10. Overall funnel volume
SELECT 'Browse' AS stage, SUM(has_browse) AS sessions_reached
FROM final_funnel_sessions
UNION ALL
SELECT 'Add to Cart', SUM(has_add_to_cart)
FROM final_funnel_sessions
UNION ALL
SELECT 'Checkout', SUM(has_checkout)
FROM final_funnel_sessions
UNION ALL
SELECT 'Purchase', SUM(has_purchase)
FROM final_funnel_sessions;

-- 11. Overall conversion rate
SELECT
    COUNT(*) AS total_sessions,
    SUM(has_purchase) AS total_purchases,
    ROUND(100.0 * SUM(has_purchase) / COUNT(*), 2) AS conversion_rate_pct
FROM final_funnel_sessions;

-- 12. Overall bounce rate
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN true_bounce_flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS bounce_rate_pct
FROM final_funnel_sessions;

-- 13. Check bounce flag values
SELECT DISTINCT true_bounce_flag
FROM final_funnel_sessions;

-- 14. Check final table schema
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'final_funnel_sessions'
ORDER BY ordinal_position;

-- 15. Conversion by channel
SELECT
    channel,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_pct,
    ROUND(
        SUM(CASE WHEN true_bounce_flag = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS bounce_rate_pct
FROM final_funnel_sessions
GROUP BY channel
ORDER BY conversion_rate_pct DESC;

-- 16. Conversion by device
SELECT
    device,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_pct,
    ROUND(
        SUM(CASE WHEN true_bounce_flag = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS bounce_rate_pct
FROM final_funnel_sessions
GROUP BY device
ORDER BY conversion_rate_pct DESC;

-- 17. Conversion by product category
SELECT
    product_category,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_pct,
    ROUND(AVG(session_revenue), 2) AS avg_revenue_per_session
FROM final_funnel_sessions
GROUP BY product_category
ORDER BY conversion_rate_pct DESC;

-- 18. Conversion by region
SELECT
    region,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchases,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_pct,
    ROUND(
        SUM(CASE WHEN true_bounce_flag = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS bounce_rate_pct
FROM final_funnel_sessions
GROUP BY region
ORDER BY conversion_rate_pct DESC;

-- 19. Revenue by channel
SELECT
    channel,
    ROUND(SUM(session_revenue), 2) AS total_revenue,
    ROUND(AVG(session_revenue), 2) AS avg_revenue_per_session,
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS total_purchases
FROM final_funnel_sessions
GROUP BY channel
ORDER BY total_revenue DESC;
