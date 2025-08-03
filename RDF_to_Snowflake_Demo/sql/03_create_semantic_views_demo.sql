-- Snowflake Semantic Views Demo - Native Implementation
-- This script creates ACTUAL Snowflake Semantic Views using CREATE SEMANTIC VIEW syntax
-- Compatible with Cortex Analyst for natural language queries

-- Set the correct Snowflake context
USE ROLE SYSADMIN;
USE WAREHOUSE RDF_DEMO_WH;
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- STEP 1: CREATE ACTUAL SNOWFLAKE SEMANTIC VIEWS
-- ================================================================

SELECT '=== Creating Real Snowflake Semantic Views for Cortex Analyst ===' as DEMO_STATUS;

-- Drop existing semantic views if they exist
DROP SEMANTIC VIEW IF EXISTS ECOMMERCE_SEMANTIC_MODEL;
DROP SEMANTIC VIEW IF EXISTS PRODUCT_ANALYTICS_MODEL;
DROP SEMANTIC VIEW IF EXISTS CUSTOMER_ANALYTICS_MODEL;

-- ================================================================
-- Main E-commerce Semantic View
-- ================================================================

CREATE OR REPLACE SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL
(
    -- Define the physical tables and their primary keys
    TABLES (
        PRODUCT primary key (ID),
        CATEGORY primary key (ID), 
        CUSTOMER primary key (ID),
        ORDER_ as ORDER_TABLE primary key (ID),
        ORDERITEM primary key (ID),
        SUPPLIER primary key (ID)
    ),

    -- Define relationships between tables using foreign keys
    RELATIONSHIPS (
        -- OrderItem belongs to Order
        ORDERITEM(ORDERID) references ORDER_TABLE(ID) as ORDERITEM_TO_ORDER,
        
        -- OrderItem references Product
        ORDERITEM(PRODUCTID) references PRODUCT(ID) as ORDERITEM_TO_PRODUCT,
        
        -- Order belongs to Customer
        ORDER_TABLE(CUSTOMERID) references CUSTOMER(ID) as ORDER_TO_CUSTOMER
    ),

    -- Define business dimensions for analysis and filtering
    DIMENSIONS (
        -- Product dimensions
        PRODUCT.PRODUCTNAME as PRODUCT_NAME 
            synonyms ('product', 'item', 'merchandise', 'goods', 'product name') 
            description 'Name of the product available for purchase'
            sample_values ('Laptop', 'Smartphone', 'Tablet', 'Headphones', 'Camera'),
        
        PRODUCT.PRICE as PRODUCT_PRICE 
            synonyms ('price', 'cost', 'amount', 'unit price') 
            description 'Price of the product in dollars'
            sample_values (299.99, 599.99, 149.99, 89.99, 1299.99),
            
        -- Category dimensions  
        CATEGORY.CATEGORYNAME as CATEGORY_NAME
            synonyms ('category', 'type', 'classification', 'group', 'product category')
            description 'Product category for classification'
            sample_values ('Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports'),
            
        CATEGORY.DESCRIPTION as CATEGORY_DESCRIPTION
            synonyms ('category description', 'category details', 'category info')
            description 'Detailed description of the product category',
            
        -- Customer dimensions
        CUSTOMER.CUSTOMERNAME as CUSTOMER_NAME
            synonyms ('customer', 'client', 'buyer', 'user', 'customer name')
            description 'Name of the customer'
            sample_values ('John Smith', 'Jane Doe', 'Bob Johnson', 'Sarah Wilson'),
            
        CUSTOMER.EMAIL as CUSTOMER_EMAIL
            synonyms ('email', 'email address', 'contact email', 'customer email')
            description 'Customer email address for contact'
            sample_values ('john@example.com', 'jane@example.com', 'bob@company.com'),
            
        -- Order dimensions
        ORDER_TABLE.ORDERDATE as ORDER_DATE
            synonyms ('order date', 'purchase date', 'transaction date', 'sale date')
            description 'Date when the order was placed'
            sample_values ('2024-01-15', '2024-02-20', '2024-03-10', '2024-04-05'),
            
        -- OrderItem dimensions
        ORDERITEM.QUANTITY as ORDER_QUANTITY
            synonyms ('quantity', 'amount', 'units', 'count')
            description 'Quantity of items ordered'
            sample_values (1, 2, 3, 5, 10),
            
        -- Supplier dimensions
        SUPPLIER.CONTACT_INFO as SUPPLIER_CONTACT
            synonyms ('supplier contact', 'vendor contact', 'supplier info')
            description 'Contact information for the supplier'
    ),

    -- Define business metrics for KPI analysis
    METRICS (
        -- Revenue metrics
        SUM(ORDER_TABLE.TOTAL_AMOUNT) as TOTAL_REVENUE
            synonyms ('revenue', 'sales', 'total sales', 'income', 'earnings')
            description 'Total revenue from all orders',
            
        -- Order metrics
        COUNT(ORDER_TABLE.ID) as ORDER_COUNT
            synonyms ('number of orders', 'order count', 'total orders', 'orders placed')
            description 'Total number of orders placed',
            
        -- Product metrics
        COUNT(DISTINCT PRODUCT.ID) as UNIQUE_PRODUCTS
            synonyms ('product count', 'number of products', 'distinct products')
            description 'Count of unique products available',
            
        -- Customer metrics
        COUNT(DISTINCT CUSTOMER.ID) as UNIQUE_CUSTOMERS
            synonyms ('customer count', 'number of customers', 'distinct customers')
            description 'Count of unique customers',
            
        -- OrderItem metrics
        SUM(ORDERITEM.QUANTITY) as TOTAL_QUANTITY_SOLD
            synonyms ('total quantity', 'items sold', 'units sold', 'total units')
            description 'Total quantity of all items sold',
            
        -- Average metrics
        AVG(ORDER_TABLE.TOTAL_AMOUNT) as AVERAGE_ORDER_VALUE
            synonyms ('AOV', 'average order value', 'avg order', 'mean order value')
            description 'Average monetary value per order',
            
        AVG(ORDERITEM.QUANTITY) as AVERAGE_QUANTITY_PER_ORDER
            synonyms ('avg quantity', 'average items per order', 'mean quantity')
            description 'Average quantity of items per order',
            
        -- Product performance
        SUM(ORDERITEM.QUANTITY * PRODUCT.PRICE) as TOTAL_PRODUCT_REVENUE
            synonyms ('product revenue', 'item revenue', 'product sales')
            description 'Total revenue generated from product sales'
    ),

    -- Define filters for common business scenarios
    FILTERS (
        high_value_orders: ORDER_TABLE.TOTAL_AMOUNT > 100
            synonyms ('expensive orders', 'high value orders', 'premium orders')
            description 'Orders with total amount greater than $100',
            
        recent_orders: ORDER_TABLE.ORDERDATE >= DATEADD('day', -30, CURRENT_DATE())
            synonyms ('recent orders', 'last 30 days', 'current month')
            description 'Orders placed in the last 30 days',
            
        electronics_category: CATEGORY.CATEGORYNAME = 'Electronics'
            synonyms ('electronics', 'electronic products', 'tech products')
            description 'Products in the Electronics category',
            
        high_quantity_orders: ORDERITEM.QUANTITY >= 5
            synonyms ('bulk orders', 'large quantity', 'high volume')
            description 'Order items with quantity of 5 or more'
    )
);

-- ================================================================
-- Product Analytics Semantic View
-- ================================================================

CREATE OR REPLACE SEMANTIC VIEW PRODUCT_ANALYTICS_MODEL
(
    TABLES (
        PRODUCT primary key (ID),
        CATEGORY primary key (ID),
        ORDERITEM primary key (ID)
    ),

    RELATIONSHIPS (
        ORDERITEM(PRODUCTID) references PRODUCT(ID) as PRODUCT_SALES
    ),

    DIMENSIONS (
        PRODUCT.PRODUCTNAME as PRODUCT_NAME
            synonyms ('product', 'item name', 'product title')
            description 'Name of the product'
            sample_values ('Gaming Laptop', 'Wireless Headphones', 'Smart Watch'),
            
        CATEGORY.CATEGORYNAME as CATEGORY 
            synonyms ('product category', 'type', 'classification')
            description 'Product category classification'
            sample_values ('Electronics', 'Accessories', 'Computers'),
            
        PRODUCT.PRICE as UNIT_PRICE
            synonyms ('price', 'cost per unit', 'unit cost')
            description 'Price per unit of the product'
    ),

    METRICS (
        SUM(ORDERITEM.QUANTITY) as TOTAL_UNITS_SOLD
            synonyms ('units sold', 'quantity sold', 'sales volume', 'items sold')
            description 'Total units sold for each product',
            
        SUM(ORDERITEM.QUANTITY * PRODUCT.PRICE) as TOTAL_PRODUCT_REVENUE
            synonyms ('product revenue', 'sales revenue', 'product income')
            description 'Total revenue generated by each product',
            
        COUNT(DISTINCT ORDERITEM.ORDERID) as ORDERS_CONTAINING_PRODUCT
            synonyms ('order count', 'number of orders', 'order frequency')
            description 'Number of distinct orders containing this product',
            
        AVG(ORDERITEM.QUANTITY) as AVERAGE_QUANTITY_PER_ORDER
            synonyms ('avg quantity per order', 'typical order size')
            description 'Average quantity ordered per transaction'
    ),

    FILTERS (
        bestsellers: SUM(ORDERITEM.QUANTITY) > 10
            synonyms ('popular products', 'top sellers', 'high demand')
            description 'Products with more than 10 units sold',
            
        high_revenue_products: SUM(ORDERITEM.QUANTITY * PRODUCT.PRICE) > 1000
            synonyms ('high revenue', 'profitable products')
            description 'Products generating more than $1000 in revenue'
    )
);

-- ================================================================
-- Customer Analytics Semantic View  
-- ================================================================

CREATE OR REPLACE SEMANTIC VIEW CUSTOMER_ANALYTICS_MODEL
(
    TABLES (
        CUSTOMER primary key (ID),
        ORDER_ as ORDERS primary key (ID),
        ORDERITEM primary key (ID)
    ),

    RELATIONSHIPS (
        ORDERS(CUSTOMERID) references CUSTOMER(ID) as CUSTOMER_ORDERS,
        ORDERITEM(ORDERID) references ORDERS(ID) as ORDER_ITEMS
    ),

    DIMENSIONS (
        CUSTOMER.CUSTOMERNAME as CUSTOMER_NAME
            synonyms ('customer', 'client name', 'buyer name')
            description 'Full name of the customer'
            sample_values ('Alice Johnson', 'Mike Brown', 'Lisa Davis'),
            
        CUSTOMER.EMAIL as EMAIL_ADDRESS
            synonyms ('email', 'customer email', 'contact email')
            description 'Customer email address'
            sample_values ('alice@email.com', 'mike@company.org'),
            
        ORDERS.ORDERDATE as ORDER_DATE
            synonyms ('purchase date', 'order date', 'transaction date')
            description 'Date when the order was placed'
    ),

    METRICS (
        COUNT(ORDERS.ID) as TOTAL_ORDERS
            synonyms ('order count', 'number of orders', 'orders placed')
            description 'Total number of orders placed by each customer',
            
        SUM(ORDERS.TOTAL_AMOUNT) as CUSTOMER_LIFETIME_VALUE
            synonyms ('CLV', 'lifetime value', 'total spent', 'customer value')
            description 'Total amount spent by customer across all orders',
            
        AVG(ORDERS.TOTAL_AMOUNT) as AVERAGE_ORDER_VALUE
            synonyms ('AOV', 'avg order value', 'typical spend')
            description 'Average order value for each customer',
            
        SUM(ORDERITEM.QUANTITY) as TOTAL_ITEMS_PURCHASED
            synonyms ('items bought', 'total quantity', 'units purchased')
            description 'Total number of items purchased by customer',
            
        MAX(ORDERS.ORDERDATE) as LAST_ORDER_DATE
            synonyms ('last purchase', 'most recent order', 'latest transaction')
            description 'Date of customer most recent order',
            
        COUNT(DISTINCT ORDERS.ORDERDATE) as SHOPPING_FREQUENCY
            synonyms ('purchase frequency', 'order frequency')
            description 'Number of distinct dates customer placed orders'
    ),

    FILTERS (
        high_value_customers: SUM(ORDERS.TOTAL_AMOUNT) > 500
            synonyms ('VIP customers', 'premium customers', 'valuable customers')
            description 'Customers who have spent more than $500 total',
            
        frequent_customers: COUNT(ORDERS.ID) >= 3
            synonyms ('loyal customers', 'repeat customers', 'frequent buyers')
            description 'Customers with 3 or more orders',
            
        recent_customers: MAX(ORDERS.ORDERDATE) >= DATEADD('day', -60, CURRENT_DATE())
            synonyms ('active customers', 'recent buyers')
            description 'Customers who made a purchase in the last 60 days'
    )
);

-- ================================================================
-- STEP 2: VERIFY SEMANTIC VIEW CREATION
-- ================================================================

SELECT '=== Verifying Semantic View Creation ===' as DEMO_STATUS;

-- Show all created semantic views
SHOW SEMANTIC VIEWS;

-- Show dimensions for the main semantic view
SHOW SEMANTIC DIMENSIONS FOR SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL;

-- Show metrics for the main semantic view
SHOW SEMANTIC METRICS FOR SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL;

-- ================================================================
-- STEP 3: DEMONSTRATE SEMANTIC VIEW QUERIES
-- ================================================================

SELECT '=== Demonstrating Semantic View Queries ===' as DEMO_STATUS;

-- Query using semantic view syntax
SELECT * FROM SEMANTIC_VIEW(
    ECOMMERCE_SEMANTIC_MODEL
    DIMENSIONS (
        PRODUCT_NAME,
        CATEGORY_NAME,
        CUSTOMER_NAME
    )
    METRICS (
        TOTAL_REVENUE,
        ORDER_COUNT,
        AVERAGE_ORDER_VALUE
    )
    WHERE recent_orders
) 
LIMIT 10;

-- Product analytics query
SELECT * FROM SEMANTIC_VIEW(
    PRODUCT_ANALYTICS_MODEL
    DIMENSIONS (
        PRODUCT_NAME,
        CATEGORY
    )
    METRICS (
        TOTAL_UNITS_SOLD,
        TOTAL_PRODUCT_REVENUE,
        ORDERS_CONTAINING_PRODUCT
    )
    WHERE bestsellers
)
ORDER BY TOTAL_PRODUCT_REVENUE DESC
LIMIT 5;

-- Customer analytics query
SELECT * FROM SEMANTIC_VIEW(
    CUSTOMER_ANALYTICS_MODEL
    DIMENSIONS (
        CUSTOMER_NAME,
        EMAIL_ADDRESS
    )
    METRICS (
        CUSTOMER_LIFETIME_VALUE,
        TOTAL_ORDERS,
        AVERAGE_ORDER_VALUE,
        LAST_ORDER_DATE
    )
    WHERE high_value_customers
)
ORDER BY CUSTOMER_LIFETIME_VALUE DESC
LIMIT 5;

-- ================================================================
-- STEP 4: CORTEX ANALYST NATURAL LANGUAGE EXAMPLES
-- ================================================================

SELECT '=== Natural Language Query Examples for Cortex Analyst ===' as DEMO_STATUS;

-- These are example natural language queries that Cortex Analyst can now answer
-- using the semantic views we created:

SELECT 
    'Natural Language Queries Supported:' as QUERY_TYPE,
    'What is our total revenue?' as EXAMPLE_1,
    'Show me the top-selling products' as EXAMPLE_2,
    'Which customers have the highest lifetime value?' as EXAMPLE_3,
    'What are our best-performing product categories?' as EXAMPLE_4,
    'How many orders did we have last month?' as EXAMPLE_5,
    'What is the average order value for electronics?' as EXAMPLE_6,
    'Show me recent high-value customers' as EXAMPLE_7,
    'Which products generate the most revenue?' as EXAMPLE_8;

-- ================================================================
-- COMPLETION STATUS
-- ================================================================

SELECT '=== Semantic Views Demo Completed Successfully ===' as COMPLETION_STATUS;

SELECT 
    'Created Native Snowflake Semantic Views:' as SUMMARY_TYPE,
    'ECOMMERCE_SEMANTIC_MODEL - Complete e-commerce domain model' as VIEW_1,
    'PRODUCT_ANALYTICS_MODEL - Product performance analytics' as VIEW_2,
    'CUSTOMER_ANALYTICS_MODEL - Customer behavior and value analysis' as VIEW_3;

SELECT 
    'Key Features Implemented:' as SUMMARY_TYPE,
    'Native CREATE SEMANTIC VIEW syntax' as FEATURE_1,
    'Cortex Analyst compatible dimensions and metrics' as FEATURE_2,
    'Business-friendly synonyms and sample values' as FEATURE_3,
    'Natural language query support' as FEATURE_4,
    'Advanced filtering and business logic' as FEATURE_5;

SELECT 
    'Ready for Cortex Analyst!' as FINAL_STATUS,
    'Natural language queries fully supported through native semantic views' as CAPABILITY,
    CURRENT_TIMESTAMP() as COMPLETION_TIME;