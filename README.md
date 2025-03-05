# SQL Data Analyst Projects

This repository contains a comprehensive collection of SQL projects designed for aspiring data analysts or anyone looking to enhance their SQL skills. With 20 projects ranging from beginner to advanced level, this collection simulates real-world data analysis scenarios in an e-commerce environment.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Database Schema](#database-schema)
- [Projects](#projects)
  - [Beginner Level Projects](#beginner-level-projects)
  - [Intermediate Level Projects](#intermediate-level-projects)
  - [Advanced Level Projects](#advanced-level-projects)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

This collection of SQL projects is designed to help you practice and improve your data analysis skills by working with e-commerce scenarios. Each project focuses on specific analysis problems and utilizes various SQL concepts and techniques.

The projects are organized into three difficulty levels:
- **Beginner Level**: Basic data exploration and simple analysis
- **Intermediate Level**: More complex analysis like trends, correlations, and customer metrics
- **Advanced Level**: Sophisticated analysis techniques such as cohort analysis, RFM segmentation, and anomaly detection

## Installation

To use this project, you need to set up a relational database and execute the SQL scripts to create the schema and load sample data.

### Prerequisites

- MySQL, PostgreSQL, or any SQL database management system
- A SQL client such as MySQL Workbench, pgAdmin, or DBeaver

### Setup Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/sql-data-analyst-projects.git
   cd sql-data-analyst-projects
   ```

2. Create the database schema:
   ```bash
   # Using MySQL CLI
   mysql -u username -p < schema/ecommerce_schema.sql
   
   # Or open the file in your SQL client and execute it
   ```

3. Load the sample data:
   ```bash
   mysql -u username -p < data/sample_data.sql
   ```

4. (Optional) Generate more random data:
   ```bash
   mysql -u username -p < data/random_data_generator.sql
   ```

## Database Schema

The database schema represents an e-commerce business with the following tables:

- `categories` - Product categories
- `products` - Product information including price, cost, and inventory
- `customers` - Customer information
- `orders` - Order information and status
- `order_items` - Items within each order
- `payments` - Payment information for orders
- `returns` - Product returns
- `return_items` - Items included in each return
- `campaigns` - Marketing campaigns
- `campaign_products` - Products included in each campaign
- `inventory` - Inventory levels by product
- `click_stream_data` - Website user behavior data

The schema includes relationships between tables with appropriate foreign keys to maintain data integrity.

## Projects

### Beginner Level Projects

1. **Basic Data Exploration**
   - Listing top priced products
   - Counting products by category
   - Identifying out-of-stock products
   - Filtering products by price range

2. **Customer Segmentation**
   - Ranking customers by total spending
   - Finding active customers
   - Grouping customers by average order value
   - Calculating time between purchases

3. **Order Analysis**
   - Calculating daily, weekly, and monthly order totals
   - Finding average basket size
   - Analyzing order status distribution
   - Measuring delivery times

4. **Returns Analysis**
   - Identifying most returned products
   - Grouping returns by reason
   - Calculating return rates
   - Visualizing return trends over time

### Intermediate Level Projects

5. **Sales Trend Analysis**
   - Calculating monthly and quarterly sales
   - Determining year-over-year growth rates
   - Identifying seasonal sales patterns
   - Comparing performance to previous year

6. **Product Performance Analysis**
   - Identifying best-selling products
   - Finding highest margin products
   - Analyzing poor-performing products
   - Calculating inventory turnover

7. **Correlation Analysis**
   - Analyzing relationship between price and sales volume
   - Finding correlation between campaigns and sales increases
   - Exploring relationship between demographics and purchasing behavior
   - Examining conversion rates from product views to purchases

8. **Customer Lifetime Value (LTV) Calculation**
   - Computing average order value
   - Determining purchase frequency
   - Calculating customer retention rate
   - Combining factors to calculate LTV

9. **Cross-Channel Performance Analysis**
   - Measuring sales volume by channel
   - Calculating customer acquisition cost by channel
   - Comparing conversion rates across channels
   - Analyzing customer value differences between channels

10. **Inventory Optimization Analysis**
    - Identifying products at risk of stockout
    - Determining overstocked products
    - Analyzing optimal order quantity
    - Planning inventory for seasonal demand changes

11. **Pricing Analysis**
    - Measuring effect of price changes on sales volume
    - Calculating price elasticity
    - Determining optimal price points
    - Comparing prices with competitors

12. **Campaign Effectiveness Measurement**
    - Comparing sales before and after campaigns
    - Calculating ROI (Return on Investment)
    - Analyzing customer response by campaign type
    - Identifying most effective campaign types

### Advanced Level Projects

13. **Cohort Analysis**
    - Creating monthly customer cohorts
    - Calculating retention rates by cohort
    - Comparing cohort performance over time
    - Analyzing LTV variation by cohort

14. **RFM (Recency, Frequency, Monetary) Analysis**
    - Calculating recency, frequency, and monetary metrics
    - Scoring customers on RFM dimensions
    - Segmenting customers based on RFM scores
    - Analyzing value by customer segment

15. **Basket Analysis**
    - Finding frequently co-purchased product pairs
    - Researching relationship between basket size and product categories
    - Identifying cross-selling opportunities
    - Preparing data for product recommendation algorithms

16. **Churn (Customer Attrition) Analysis**
    - Calculating churn rate
    - Identifying behavior patterns before churn
    - Comparing churn rates by demographic factors
    - Detecting at-risk customers

17. **A/B Test Result Analysis**
    - Evaluating results of A/B tests
    - Applying statistical significance tests
    - Analyzing test results by segment
    - Measuring long-term effects

18. **Seasonality and Trend Analysis**
    - Calculating yearly, quarterly, and monthly trends
    - Isolating seasonal factors
    - Measuring baseline performance without seasonality effects
    - Forecasting for future periods

19. **Customer Journey Analysis**
    - Calculating average time to conversion
    - Identifying critical touch points in customer journey
    - Detecting bottlenecks in conversion funnel
    - Creating journey maps for different customer segments

20. **Anomaly Detection**
    - Using standard deviation to detect outliers
    - Measuring deviations from seasonal expectations
    - Identifying potentially fraudulent transactions
    - Detecting data patterns that indicate system errors

## Usage

Each project is contained in its own SQL file in the appropriate directory based on difficulty level. To use a project:

1. Open the SQL file in your preferred SQL client
2. Execute the queries one by one to see the results
3. Modify queries as needed to fit your specific requirements or to experiment with different approaches

Example usage for a sales trend analysis:

```sql
-- Monthly sales calculation
SELECT 
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    SUM(oi.unit_price * oi.quantity) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY year, month
ORDER BY year DESC, month DESC;
```

## Contributing

Contributions to improve the project are welcome. Please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Created by [Your Name] - Feel free to contact me with any questions or feedback!