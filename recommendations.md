# Analysis Report for Alt Mobility

## Key Findings

### 0. Data Quality and Integrity
- **Missing Data**: The dataset is clean, with no missing values for critical fields (`order_status`, `order_amount`, `order_date`, `customer_id`) across 15,000 orders.
- **Duplicate Orders**: No duplicate `order_id` records were found, ensuring data integrity.
- **Payment Discrepancies**: Significant discrepancies exist between `order_amount` and `total_paid` for 9,495 orders. In 6,240 cases, payments exceed order amounts, and in 3,255 cases, payments are less than order amounts. This suggests potential issues in payment processing, refunds, or data recording.


### 1. Order and Sales Analysis
- **Order Status Distribution**: Orders are nearly evenly split among `pending` (33.79%), `delivered` (33.71%), and `shipped` (32.49%).
- **Monthly Sales Trends**: Sales show seasonal fluctuations, with peaks in mid-year (June-August) and year-end (December). The average order value ranges between `₹232.88` and `₹271.03`.
- **High-Value Orders**: Identified 100 high-value orders (above average), with amounts close to ₹500. These orders are primarily in `shipped` or `pending` status.
- **Payment Method Performance**:  
  - **Bank Transfer**: Most used (34.03%) but has the highest failure rate (34.44%).  
  - **Credit Card**: Moderate usage (33.17%) with a 33.48% failure rate.  
  - **PayPal**: Lowest usage (32.79%) but highest success rate (34.42%).

### 2. Customer Analysis
- **Customer Segmentation**:  
  - **High Spenders(`>= ₹448`) (962 customers)**: Contribute 45% of total revenue (₹592,886).  
  - **Medium Spenders(`Between ₹170 AND ₹447`) (1,930 customers)**: Contribute 49% of revenue (₹599,897).  
  - **Low Spenders(`< ₹170`) (971 customers)**: Contribute 6% of revenue (₹91,833).  
- **Repeat Orders**:  
  - New orders dominate initially, but repeat orders grow over time, peaking at 187 repeat orders in April 2025.  
  - Customers with 2-3 orders have a 10-day average lifetime, while 4-5 orders show 7 days.  
- **Active Customers**: Monthly active customers range between 66 and 96, with consistent delivery rates.

### 3. Payment Status Analysis
- **Payment Status Distribution**:  
  - `pending` (33.37%), `failed` (33.35%), and `completed` (33.27%) are evenly split.  
- **Failure Trends**:  
  - Bank transfers have the highest failure rate (34.44%), while PayPal has the lowest (32.10%).  
  - Some orders have up to 7 payment attempts, with delays spanning 921 days. 

  ### 💸 Payment Method Performance
  | Method         | % of Payments | Total Amount | Avg Payment | Success Rate |
  |----------------|----------------|----------------|----------------|----------------|
  | Bank Transfer  | 34.0%          | ₹1.3M          | ₹254.9         | 32.0%          |
  | Credit Card    | 33.2%          | ₹1.26M         | ₹254.0         | 33.4%          |
  | PayPal         | 32.8%          | ₹1.24M         | ₹251.9         | **34.4%**   | 

---

## Observations from Customer Retention Analysis
- **Low Retention**: 2,896 customers (61%) placed only one order, indicating low retention.  
- **High-Value Potential**: Customers with 6+ orders spend significantly more (avg. ₹616 vs. ₹255 for one-time buyers).  
- **Lifetime Value**: High spenders have longer lifetimes (avg. 10 days vs. 0 for one-time buyers).  

---

## Recommendations for Alt Mobility
1. **Improve Payment Success Rates**:  
   - Investigate and resolve issues with bank transfers (highest failure rate).  
   - Promote PayPal (highest success rate) through incentives.  

2. **Enhance Customer Retention**:  
   - Launch loyalty programs for repeat customers (e.g., discounts for 2+ orders).  
   - Target high spenders with personalized offers to encourage repeat purchases.  

3. **Optimize Order Fulfillment**:  
   - Address discrepancies in order vs. payment amounts (9,495 cases found).  
   - Prioritize high-value orders to ensure timely delivery and customer satisfaction.  

4. **Seasonal Promotions**:  
   - Capitalize on mid-year and year-end sales peaks with targeted marketing campaigns.  

5. **Reduce Payment Delays**:  
   - Streamline payment processing to minimize multi-attempt orders (some take 2+ years to resolve).  

---  
**Conclusion**: Focus on payment reliability and customer retention to drive revenue growth and operational efficiency.  