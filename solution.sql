-- 0. Data Handling & Cleaning

-- 0.1 Check for missing order_status, order_amount, order_date, customer_id
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) AS missing_order_amount,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS missing_order_status,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id
FROM customer_orders;

-- 0.2 Check for duplicate orders
SELECT 
    order_id, 
    COUNT(*) 
FROM customer_orders 
GROUP BY order_id 
HAVING COUNT(*) > 1;

-- 0.3 Check payment amounts vs. order amounts (potential discrepancies)
SELECT 
    co.order_id,
    co.order_amount,
    SUM(p.payment_amount) AS total_paid
FROM customer_orders co
LEFT JOIN payments p ON co.order_id = p.order_id
GROUP BY co.order_id, co.order_amount
HAVING SUM(p.payment_amount) != co.order_amount;


-- 1. ORDER AND SALES ANALYSIS

-- 1.1 Distribution of orders by status
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_orders), 2) AS percentage
FROM customer_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 1.2 Monthly sales trends
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(*) AS order_count,
    ROUND(SUM(order_amount), 2) AS total_sales,
    ROUND(AVG(order_amount), 2) AS average_order_value
FROM customer_orders
GROUP BY year, month
ORDER BY year, month;

-- 1.3 Sales trend by order status
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(order_amount), 2) AS total_sales
FROM customer_orders
GROUP BY year, month, order_status
ORDER BY year, month, order_status;

-- 1.4 High value orders analysis (Delivered Only)
-- Identify orders with values above then the average order amount as a threshold
WITH AOV AS (
    SELECT AVG(order_amount) AS average_order_value
    FROM customer_orders
    WHERE order_status = 'delivered'
)
SELECT 
    order_id,
    customer_id,
    order_date,
    order_amount,
    order_status
FROM customer_orders
WHERE order_amount > (SELECT average_order_value FROM AOV)
ORDER BY order_amount DESC
LIMIT 100;

-- 1.5 Payment Method Performance Analysis
SELECT 
    payment_method,
    COUNT(*) AS no_of_payments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage,
    SUM(payment_amount) AS total_amount,
    ROUND(AVG(payment_amount), 2) AS avg_payment,
    SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) AS no_of_successful_payments,
    ROUND(SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate
FROM payments
GROUP BY payment_method
ORDER BY total_amount DESC;

-- 1.7 Payment Processing Time Analysis
SELECT 
    o.order_id,
    o.order_date,
    p.payment_date,
    o.order_status,
    p.payment_status,
    EXTRACT(DAY FROM (p.payment_date - o.order_date)) AS days_to_payment
FROM customer_orders o
JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_date > o.order_date
ORDER BY days_to_payment DESC;


-- 2. CUSTOMER ANALYSIS

-- 2.1 Frequency of orders per customer
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    ROUND(SUM(order_amount), 2) AS total_spent,
    ROUND(AVG(order_amount), 2) AS average_order_value,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS most_recent_order_date,
    timestampdiff(Month, MIN(order_date), MAX(order_date)) AS customer_lifetime_months
FROM customer_orders
GROUP BY customer_id
ORDER BY order_count DESC;

-- 2. Monthly Active Customers
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(*) AS total_orders
FROM customer_orders
WHERE order_status = 'delivered'
GROUP BY year, month
ORDER BY year, month;

-- 2.2 Customer segmentation based on ordering behavior
WITH customer_stats AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(order_amount) AS total_spent,
        AVG(order_amount) AS average_order_value,
        EXTRACT(DAY FROM MAX(order_date) - MIN(order_date)) AS customer_lifetime_days
    FROM customer_orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
)

SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN order_count BETWEEN 4 AND 5 THEN '4-5 orders'
        ELSE '6+ orders'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(AVG(average_order_value), 2) AS avg_order_value,
    ROUND(AVG(customer_lifetime_days), 0) AS avg_lifetime_days
FROM customer_stats
GROUP BY customer_segment
ORDER BY 
    CASE 
        WHEN customer_segment = '1 order' THEN 1
        WHEN customer_segment = '2-3 orders' THEN 2
        WHEN customer_segment = '4-5 orders' THEN 3
        ELSE 4
    END;

-- 2.3 Customer Segmentation by Spending
WITH customer_stats AS (
    SELECT 
        customer_id,
        SUM(order_amount) AS total_spend
    FROM customer_orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_spend >= 448 THEN 'High Spender'
        WHEN total_spend BETWEEN 170 AND 447 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS segment,
    COUNT(*) AS customers,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(SUM(total_spend), 2) AS total_revenue
FROM customer_stats
GROUP BY segment
ORDER BY total_revenue DESC;

-- 2.4 Repeat and New Order analysis
WITH first_order_date AS (
    SELECT 
        customer_id, 
        MIN(order_date) AS first_order_date
    FROM customer_orders
    GROUP BY customer_id
),
orders_with_flags AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_date,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_year_month,
        CASE 
            WHEN DATE_FORMAT(o.order_date, '%Y-%m') = DATE_FORMAT(f.first_order_date, '%Y-%m') THEN 'New'
            ELSE 'Repeated'
        END AS order_type
    FROM customer_orders o
    JOIN first_order_date f ON o.customer_id = f.customer_id
)
SELECT 
    order_year_month,
    COUNT(CASE WHEN order_type = 'New' THEN 1 END) AS new_orders,
    COUNT(CASE WHEN order_type = 'Repeated' THEN 1 END) AS repeated_orders
FROM orders_with_flags
GROUP BY order_year_month
ORDER BY order_year_month;


-- 3. PAYMENT STATUS ANALYSIS

-- 3.1 Payment status distribution
SELECT 
    payment_status,
    COUNT(*) AS payment_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments), 2) AS percentage,
    ROUND(SUM(payment_amount), 2) AS total_amount,
    ROUND(AVG(payment_amount), 2) AS average_amount
FROM payments
GROUP BY payment_status
ORDER BY payment_count DESC;

-- 3.2 Payment method analysis
SELECT 
    payment_method,
    COUNT(*) AS payment_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments), 2) AS percentage,
    ROUND(SUM(payment_amount), 2) AS total_amount,
    ROUND(AVG(payment_amount), 2) AS average_amount
FROM payments
GROUP BY payment_method
ORDER BY payment_count DESC;

-- 3.3 Payment failure and success analysis by payment method
SELECT 
    payment_method,
    COUNT(*) AS total_payments,
    SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) AS success_payments,
    ROUND(SUM(CASE WHEN payment_status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate,
    ROUND(AVG(CASE WHEN payment_status = 'completed' THEN payment_amount ELSE NULL END), 2) AS avg_success_amount,
    SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payments,
    ROUND(SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate,
    ROUND(AVG(CASE WHEN payment_status = 'failed' THEN payment_amount ELSE NULL END), 2) AS avg_failed_amount
FROM payments
GROUP BY payment_method
ORDER BY failure_rate DESC;

-- 3.4 Monthly payment status trends
SELECT 
    EXTRACT(YEAR FROM payment_date) AS payment_year,
    EXTRACT(MONTH FROM payment_date) AS payment_month,
    payment_status,
    COUNT(*) AS payment_count,
    SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payments,
    ROUND(SUM(CASE WHEN payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate,
    ROUND(SUM(payment_amount), 2) AS total_amount,
    ROUND(coalesce(SUM(CASE WHEN payment_status = 'failed' THEN payment_amount ELSE NULL END), 0), 2) AS failed_amount
FROM payments
GROUP BY payment_year,payment_month, payment_status
ORDER BY payment_year,payment_month, payment_status;

-- 3.5 Identify orders with multiple payment attempts
SELECT 
    order_id,
    COUNT(*) AS payment_attempts,
    GROUP_CONCAT(payment_status ORDER BY payment_date SEPARATOR ', ') AS payment_statuses,
    MIN(payment_date) AS first_attempt,
    MAX(payment_date) AS last_attempt,
    DATEDIFF(MAX(DATE(payment_date)), MIN(DATE(payment_date))) AS days_between_attempts
FROM payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_attempts DESC;

-- 3.6 Analyze Payment Failures by Order Amount
-- Check if failed payments correlate with high or low order amounts
WITH amount_ranges AS (
  SELECT 
    MIN(order_amount) AS min_amount,
    MAX(order_amount) AS max_amount,
    MAX(order_amount) - MIN(order_amount) AS range_diff
  FROM customer_orders
),
range_thresholds AS (
  SELECT
    min_amount + (range_diff * 0.33) AS low_threshold,
    min_amount + (range_diff * 0.66) AS medium_threshold
  FROM amount_ranges
)
SELECT 
  CASE 
    WHEN o.order_amount <= rt.low_threshold THEN CONCAT('Low (<= $', ROUND(rt.low_threshold, 2), ')')
    WHEN o.order_amount <= rt.medium_threshold THEN CONCAT('Medium ($', ROUND(rt.low_threshold + 0.01, 2), '-$', ROUND(rt.medium_threshold, 2), ')')
    ELSE CONCAT('High (> $', ROUND(rt.medium_threshold, 2), ')')
  END AS amount_range,
  COUNT(p.payment_id) AS total_payments,
  SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) AS failed_payments,
  ROUND(SUM(CASE WHEN p.payment_status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(p.payment_id), 2) AS failure_rate
FROM payments p
JOIN customer_orders o ON p.order_id = o.order_id
CROSS JOIN range_thresholds rt
GROUP BY amount_range
ORDER BY failure_rate;


-- 4. ORDER DETAILS REPORT

-- 4.1 Comprehensive order report with payment details
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_amount,
    o.order_status,
    p.payment_id,
    p.payment_date,
    p.payment_amount,
    p.payment_method,
    p.payment_status,
    CASE 
        WHEN p.payment_id IS NULL THEN 'No payment record'
        WHEN p.payment_status = 'completed' THEN 'Paid'
        WHEN p.payment_status = 'pending' THEN 'Payment pending'
        WHEN p.payment_status = 'failed' THEN 'Payment failed'
    END AS payment_summary,
    CASE 
        WHEN o.order_status = 'delivered' AND p.payment_status = 'completed' THEN 'Completed'
        WHEN o.order_status = 'delivered' AND (p.payment_status != 'completed' OR p.payment_id IS NULL) THEN 'Delivered but payment issue'
        WHEN o.order_status = 'shipped' AND p.payment_status = 'completed' THEN 'In transit, paid'
        WHEN o.order_status = 'shipped' AND (p.payment_status != 'completed' OR p.payment_id IS NULL) THEN 'In transit, payment issue'
        WHEN o.order_status = 'pending' THEN 'Processing'
        ELSE 'Other'
    END AS order_summary
FROM customer_orders o
LEFT JOIN payments p ON o.order_id = p.order_id
ORDER BY o.order_date DESC;

-- 4.2 Order fulfillment performance metrics
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered_orders,
    ROUND(COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) * 100.0 / COUNT(*), 2) AS delivery_rate,
    COUNT(CASE WHEN order_status = 'shipped' THEN 1 END) AS shipped_orders,
    ROUND(COUNT(CASE WHEN order_status = 'shipped' THEN 1 END) * 100.0 / COUNT(*), 2) AS shipped_rate,
    COUNT(CASE WHEN order_status = 'pending' THEN 1 END) AS pending_orders,
    ROUND(COUNT(CASE WHEN order_status = 'pending' THEN 1 END) * 100.0 / COUNT(*), 2) AS pending_rate
FROM customer_orders
GROUP BY year, month
ORDER BY year, month;

-- 4.3 Yearly-Monthly Revenue report
WITH orders_agg AS (
    SELECT
        order_id,
        order_date,
        SUM(order_amount) AS t_order_amount
    FROM customer_orders
    GROUP BY order_id, order_date
),
payments_agg AS (
    SELECT 
        order_id,
        COUNT(DISTINCT p.payment_id) AS t_payments,
        SUM(p.payment_amount) AS t_payment_amount
    FROM payments p
    WHERE p.payment_status = 'completed'
    GROUP BY order_id
)
SELECT 
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.t_order_amount), 2) AS total_order_amount,
    SUM(p.t_payments) AS total_payments,
    ROUND(SUM(p.t_payment_amount), 2) AS total_payment_amount,
    ROUND(SUM(o.t_order_amount) - COALESCE(SUM(p.t_payment_amount), 0), 2) AS revenue_gap,
    COUNT(DISTINCT o.order_id) - SUM(CASE WHEN p.t_payments > 0 THEN 1 ELSE 0 END) AS orders_without_payments,
    ROUND(
        (SUM(o.t_order_amount) - COALESCE(SUM(p.t_payment_amount), 0)) * 100.0 / SUM(o.t_order_amount), 
        2
    ) AS revenue_gap_percentage
FROM orders_agg o
LEFT JOIN payments_agg p ON o.order_id = p.order_id
GROUP BY year, month
ORDER BY year, month;


-- 5. CUSTOMER RETENTION ANALYSIS

-- 5.1 Customer cohort analysis (1 year cohort)
WITH customer_first_order AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_year_month  -- Capture first order month (Year-Month)
    FROM customer_orders
    WHERE order_status = 'delivered'  -- Only consider 'delivered' orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT 
        cfo.cohort_year_month,
        co.order_id,
        co.customer_id,
        co.order_date,
        DATE_FORMAT(co.order_date, '%Y-%m') AS order_month,
		TIMESTAMPDIFF(
			MONTH,
			STR_TO_DATE(CONCAT(cfo.cohort_year_month, '-01'), '%Y-%m-%d'),
			DATE(co.order_date)
		) AS months_since_first_order
    FROM customer_orders co
    JOIN customer_first_order cfo ON co.customer_id = cfo.customer_id
    WHERE order_status = 'delivered'  -- Only consider 'delivered' orders 
)
SELECT 
    cohort_year_month AS cohort_start_month,
    COUNT(DISTINCT CASE WHEN months_since_first_order = 0 THEN customer_id END) AS cohort_size,
    COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 1 AND 12 THEN customer_id END) AS year_1,
    COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 13 AND 24 THEN customer_id END) AS year_2,
    COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 25 AND 36 THEN customer_id END) AS year_3,
    COUNT(DISTINCT CASE WHEN months_since_first_order > 36 THEN customer_id END) AS year_4_plus
FROM cohort_data
GROUP BY cohort_year_month
ORDER BY cohort_year_month;


-- 5.2 Cohort retention rate
WITH customer_first_order AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_year_month 
    FROM customer_orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
),
cohort_data AS (
    SELECT 
        cfo.cohort_year_month,
        co.order_id,
        co.customer_id,
        co.order_date,
        DATE_FORMAT(co.order_date, '%Y-%m') AS order_month,
		TIMESTAMPDIFF(
			MONTH,
			STR_TO_DATE(CONCAT(cfo.cohort_year_month, '-01'), '%Y-%m-%d'),
			DATE(co.order_date)
		) AS months_since_first_order
    FROM customer_orders co
    JOIN customer_first_order cfo ON co.customer_id = cfo.customer_id
    WHERE order_status = 'delivered'  -- Only consider 'delivered' orders 
),
cohort_table AS (
    SELECT 
		cohort_year_month AS cohort_start_month,
		COUNT(DISTINCT CASE WHEN months_since_first_order = 0 THEN customer_id END) AS cohort_size,
		COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 1 AND 12 THEN customer_id END) AS year_1,
		COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 13 AND 24 THEN customer_id END) AS year_2,
		COUNT(DISTINCT CASE WHEN months_since_first_order BETWEEN 25 AND 36 THEN customer_id END) AS year_3,
		COUNT(DISTINCT CASE WHEN months_since_first_order > 36 THEN customer_id END) AS year_4_plus
	FROM cohort_data
	GROUP BY cohort_year_month
)
SELECT
    cohort_start_month,
    ROUND((cohort_size / CAST(cohort_size AS DECIMAL)) * 100, 0) AS y0,  -- always 100%
    ROUND((year_1 / CAST(cohort_size AS DECIMAL)) * 100, 0) AS y1,
    ROUND((year_2 / CAST(cohort_size AS DECIMAL)) * 100, 0) AS y2,
    ROUND((year_3 / CAST(cohort_size AS DECIMAL)) * 100, 0) AS y3,
    ROUND((year_4_plus / CAST(cohort_size AS DECIMAL)) * 100, 0) AS y4_plus
FROM cohort_table;

-- 5.3 Identifying at-risk customers
WITH order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM customer_orders
),

gaps_with_diff AS (
    SELECT 
        customer_id,
        order_date,
        previous_order_date,
        TIMESTAMPDIFF(MONTH, previous_order_date, order_date) AS gap_months
    FROM order_gaps
    WHERE previous_order_date IS NOT NULL
),

customer_activity AS (
    SELECT 
        co.customer_id,
        MAX(co.order_date) AS last_order_date,
        TIMESTAMPDIFF(MONTH, MAX(co.order_date), CURRENT_DATE()) AS months_since_last_order,
        COUNT(*) AS total_orders,
        ROUND(AVG(gwd.gap_months), 1) AS avg_months_between_orders
    FROM customer_orders co
    LEFT JOIN gaps_with_diff gwd ON co.customer_id = gwd.customer_id
    GROUP BY co.customer_id
)

SELECT 
    customer_id,
    last_order_date,
    months_since_last_order,
    total_orders,
    avg_months_between_orders,
    CASE 
        WHEN months_since_last_order > 2 * avg_months_between_orders AND total_orders > 1 THEN 'High Risk'
        WHEN months_since_last_order > 1.5 * avg_months_between_orders AND total_orders > 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM customer_activity
WHERE total_orders > 1 AND avg_months_between_orders IS NOT NULL;
