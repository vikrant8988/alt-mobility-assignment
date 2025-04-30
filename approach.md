
## Analysis Approach
The SQL-based analysis is organized into five sections, leveraging `customer_orders` and `payments` tables to derive actionable insights:

### 0. Data Handling & Cleaning
- **Missing Data Check**: Identifies null values in `order_status`, `order_amount`, `order_date`, and `customer_id` to ensure data completeness.
- **Duplicate Orders**: Detects duplicate `order_id` entries to maintain data integrity.
- **Payment Discrepancies**: Compares `order_amount` with total `payment_amount` to flag inconsistencies.

### 1. Order and Sales Analysis
- **Order Status Distribution**: Quantifies orders by status (e.g., delivered, shipped) to assess fulfillment efficiency.
- **Monthly Sales Trends**: Tracks order counts, total sales, and average order value by year and month for trend analysis.
- **Sales by Status**: Breaks down sales by order status to understand revenue sources.
- **High-Value Orders**: Identifies delivered orders above the average order amount for targeted strategies.
- **Payment Method Performance**: Analyzes payment methods by volume, success rate, and average payment amount.
- **Payment Processing Time**: Measures days between order and payment to optimize workflows.

### 2. Customer Analysis
- **Order Frequency**: Summarizes customer order counts, total spend, and lifetime to identify loyal customers.
- **Monthly Active Customers**: Counts distinct customers with delivered orders monthly to gauge engagement.
- **Segmentation by Ordering Behavior**: Groups customers by order frequency (e.g., one-time, 2-3 orders) for retention strategies.
- **Spending-Based Segmentation**: Categorizes customers into high, medium, and low spenders based on total spend.
- **New vs. Repeat Orders**: Quantifies new and repeat orders monthly to evaluate acquisition and retention.

### 3. Payment Status Analysis
- **Payment Status Distribution**: Summarizes payment statuses (e.g., completed, failed) and their financial impact.
- **Payment Method Analysis**: Compares payment methods by volume and amount to optimize options.
- **Success/Failure by Method**: Analyzes success and failure rates per payment method to identify reliability issues.
- **Monthly Payment Trends**: Tracks payment statuses and failure rates over time to detect patterns.
- **Multiple Payment Attempts**: Identifies orders with multiple payment attempts to investigate processing issues.
- **Failure by Order Amount**: Correlates payment failures with order amount ranges (low, medium, high).

### 4. Order Details Report
- **Comprehensive Order Report**: Combines order and payment details with summaries (e.g., "Paid", "Payment failed") for a holistic view.
- **Fulfillment Performance**: Measures delivery, shipped, and pending rates monthly to assess operations.
- **Revenue Report**: Compares order amounts with completed payments to identify revenue gaps.

### 5. Customer Retention Analysis
- **Cohort Analysis**: Tracks customer retention over 3-month intervals post-first order to measure loyalty.
- **Cohort Retention Rate**: Calculates retention percentages for each cohort to quantify repeat purchases.
- **At-Risk Customers**: Identifies customers with longer-than-average gaps since their last order, categorizing them as high, medium, or low risk for churn.
