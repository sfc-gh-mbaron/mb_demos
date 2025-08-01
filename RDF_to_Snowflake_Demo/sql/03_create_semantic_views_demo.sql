-- Snowflake Semantic Views Demo - Complete Implementation
-- This script demonstrates all aspects of Snowflake Semantic Views including:
-- - Tables with primary keys and synonyms
-- - Relationships between entities
-- - Facts (raw numerical data)
-- - Dimensions (categorical attributes)  
-- - Metrics (aggregated calculations)
-- - Comments and synonyms for natural language understanding

USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- STEP 1: TEST THE NEW SEMANTIC VIEW GENERATOR UDF
-- ================================================================

SELECT '=== Testing Semantic View Generator UDF ===' as DEMO_STATUS;

-- Parse the RDF schema first
SET schema_data = (
    SELECT PARSE_RDF_SCHEMA(RDF_CONTENT, RDF_FORMAT) 
    FROM RDF_SCHEMAS 
    WHERE SCHEMA_NAME = 'E-commerce Domain Model' 
    LIMIT 1
);

-- Generate semantic view DDL
SELECT GENERATE_SNOWFLAKE_SEMANTIC_VIEW($schema_data) as SEMANTIC_DDL_RESULT;

-- ================================================================
-- STEP 2: CREATE THE COMPREHENSIVE SEMANTIC VIEW MANUALLY
-- ================================================================

SELECT '=== Creating Comprehensive Snowflake Semantic View ===' as DEMO_STATUS;

-- Drop existing semantic view if it exists
DROP SEMANTIC VIEW IF EXISTS RDF_SEMANTIC_DB.SEMANTIC_VIEWS.ECOMMERCE_SEMANTIC_MODEL;

-- Create the comprehensive semantic view
CREATE OR REPLACE SEMANTIC VIEW RDF_SEMANTIC_DB.SEMANTIC_VIEWS.ECOMMERCE_SEMANTIC_MODEL

  -- TABLES: Define logical tables with primary keys, synonyms, and comments
  TABLES (
    product AS SEMANTIC_VIEWS.PRODUCT
      PRIMARY KEY (ID)
      WITH SYNONYMS ('products', 'items', 'merchandise', 'catalog items', 'goods')
      COMMENT = 'Product catalog containing all available products with pricing and inventory information',
      
    category AS SEMANTIC_VIEWS.CATEGORY  
      PRIMARY KEY (ID)
      WITH SYNONYMS ('categories', 'product types', 'classifications', 'product groups')
      COMMENT = 'Product categories for organizing and classifying products',
      
    customer AS SEMANTIC_VIEWS.CUSTOMER
      PRIMARY KEY (ID)
      WITH SYNONYMS ('customers', 'clients', 'buyers', 'users', 'shoppers')
      COMMENT = 'Customer information including contact details and profiles',
      
    order_ AS SEMANTIC_VIEWS.ORDER_
      PRIMARY KEY (ID)  
      WITH SYNONYMS ('orders', 'purchases', 'transactions', 'sales', 'checkouts')
      COMMENT = 'Customer orders containing purchase information and totals',
      
    orderitem AS SEMANTIC_VIEWS.ORDERITEM
      PRIMARY KEY (ID)
      WITH SYNONYMS ('order items', 'line items', 'order lines', 'purchased items')
      COMMENT = 'Individual items within orders with quantities and pricing',
      
    supplier AS SEMANTIC_VIEWS.SUPPLIER
      PRIMARY KEY (ID)
      WITH SYNONYMS ('suppliers', 'vendors', 'manufacturers', 'distributors')  
      COMMENT = 'Supplier information for product sourcing and inventory management',
      
    relationships AS SEMANTIC_VIEWS.RELATIONSHIPS
      PRIMARY KEY (ID)
      WITH SYNONYMS ('relationships', 'connections', 'associations', 'links')
      COMMENT = 'Semantic relationships between all entities in the data model'
  )

  -- RELATIONSHIPS: Define how tables relate to each other
  RELATIONSHIPS (
    product_categories AS
      product (URI) REFERENCES category (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'belongsToCategory',
      
    product_suppliers AS
      product (URI) REFERENCES supplier (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'suppliedBy',
      
    order_customers AS
      order_ (URI) REFERENCES customer (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'placedBy',
      
    order_items AS
      order_ (URI) REFERENCES orderitem (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'contains',
      
    orderitem_products AS
      orderitem (URI) REFERENCES product (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'orderItemProduct',
      
    category_hierarchy AS
      category (URI) REFERENCES category (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'parentCategory'
  )

  -- FACTS: Define raw numerical data that can be aggregated
  FACTS (
    product.price AS PRODUCT_PRICE
      COMMENT = 'Individual product price for calculating revenue and profitability metrics',
      
    product.stockquantity AS INVENTORY_LEVEL
      COMMENT = 'Current stock quantity for inventory analysis and availability tracking',
      
    order_.ordertotal AS ORDER_VALUE
      COMMENT = 'Total monetary value of each order for revenue calculations',
      
    orderitem.quantity AS ITEM_QUANTITY
      COMMENT = 'Quantity of items purchased for volume analysis',
      
    orderitem.unitprice AS ITEM_UNIT_PRICE
      COMMENT = 'Unit price of individual order items for pricing analysis'
  )

  -- DIMENSIONS: Define categorical attributes for filtering and grouping
  DIMENSIONS (
    -- Product dimensions
    product.productname AS PRODUCT_NAME
      WITH SYNONYMS ('product name', 'item name', 'product title', 'product description')
      COMMENT = 'Name of the product for identification and search',
      
    product.productid AS PRODUCT_ID
      WITH SYNONYMS ('product ID', 'SKU', 'product code', 'item ID')
      COMMENT = 'Unique identifier for each product',
    
    -- Category dimensions  
    category.categoryname AS CATEGORY_NAME
      WITH SYNONYMS ('category', 'product category', 'type', 'classification', 'group')
      COMMENT = 'Product category for grouping and filtering products',
      
    -- Customer dimensions
    customer.customername AS CUSTOMER_NAME
      WITH SYNONYMS ('customer name', 'client name', 'buyer name', 'customer')
      COMMENT = 'Customer name for identification and analysis',
      
    customer.email AS CUSTOMER_EMAIL
      WITH SYNONYMS ('email', 'email address', 'contact email')
      COMMENT = 'Customer email address for communication and identification',
      
    -- Supplier dimensions
    supplier.suppliername AS SUPPLIER_NAME
      WITH SYNONYMS ('supplier', 'vendor', 'manufacturer', 'supplier name')
      COMMENT = 'Supplier name for sourcing and vendor analysis',
      
    -- Time dimensions for temporal analysis
    order_.orderdate AS ORDER_DATE
      WITH SYNONYMS ('order date', 'purchase date', 'transaction date', 'sale date', 'when ordered')
      COMMENT = 'Date when the order was placed for temporal analysis',
      
    YEAR(order_.orderdate) AS ORDER_YEAR
      WITH SYNONYMS ('year', 'order year', 'purchase year', 'sale year')
      COMMENT = 'Year when the order was placed for yearly trend analysis',
      
    MONTH(order_.orderdate) AS ORDER_MONTH
      WITH SYNONYMS ('month', 'order month', 'purchase month', 'sale month')
      COMMENT = 'Month when the order was placed for monthly trend analysis',
      
    DAYOFWEEK(order_.orderdate) AS ORDER_DAY_OF_WEEK
      WITH SYNONYMS ('day of week', 'weekday', 'day')
      COMMENT = 'Day of the week for weekly pattern analysis',
      
    -- Derived dimensions
    CASE 
      WHEN product.price < 50 THEN 'Budget'
      WHEN product.price BETWEEN 50 AND 500 THEN 'Mid-range'
      WHEN product.price > 500 THEN 'Premium'
      ELSE 'Unpriced'
    END AS PRICE_TIER
      WITH SYNONYMS ('price tier', 'price range', 'price category', 'price segment')
      COMMENT = 'Product price tier for market segmentation analysis',
      
    CASE 
      WHEN product.stockquantity = 0 THEN 'Out of Stock'
      WHEN product.stockquantity < 10 THEN 'Low Stock'
      WHEN product.stockquantity < 50 THEN 'Medium Stock'
      ELSE 'In Stock'
    END AS STOCK_STATUS
      WITH SYNONYMS ('stock status', 'availability', 'inventory status')
      COMMENT = 'Current stock availability status for inventory management'
  )

  -- METRICS: Define calculated measures and aggregations
  METRICS (
    -- Revenue metrics
    total_revenue AS SUM(order_.ordertotal)
      WITH SYNONYMS ('total sales', 'revenue', 'total income', 'gross sales', 'sales revenue')
      COMMENT = 'Total revenue generated across all orders and time periods',
      
    average_order_value AS AVG(order_.ordertotal)
      WITH SYNONYMS ('average order value', 'AOV', 'mean order value', 'avg order size', 'typical order value')
      COMMENT = 'Average monetary value per order for customer value analysis',
      
    monthly_revenue AS SUM(order_.ordertotal)
      WITH SYNONYMS ('monthly sales', 'monthly revenue', 'monthly income')
      COMMENT = 'Monthly revenue for trend analysis and forecasting',
      
    -- Count metrics
    total_orders AS COUNT(order_.id)
      WITH SYNONYMS ('order count', 'number of orders', 'total transactions', 'transaction count')
      COMMENT = 'Total number of orders placed for volume analysis',
      
    total_customers AS COUNT(DISTINCT customer.id)
      WITH SYNONYMS ('customer count', 'number of customers', 'unique customers', 'customer base size')
      COMMENT = 'Total number of unique customers for market reach analysis',
      
    total_products AS COUNT(DISTINCT product.id)
      WITH SYNONYMS ('product count', 'number of products', 'catalog size', 'inventory items')
      COMMENT = 'Total number of unique products in the catalog',
      
    items_sold AS SUM(orderitem.quantity)
      WITH SYNONYMS ('items sold', 'units sold', 'quantity sold', 'total items')
      COMMENT = 'Total quantity of items sold across all orders',
      
    -- Product metrics
    average_product_price AS AVG(product.price)
      WITH SYNONYMS ('average price', 'mean price', 'typical price', 'avg product price')
      COMMENT = 'Average price across all products for pricing strategy analysis',
      
    total_inventory_value AS SUM(product.price * product.stockquantity)
      WITH SYNONYMS ('inventory value', 'stock value', 'total inventory worth', 'inventory investment')
      COMMENT = 'Total monetary value of current inventory investment',
      
    out_of_stock_products AS COUNT(CASE WHEN product.stockquantity = 0 THEN 1 END)
      WITH SYNONYMS ('out of stock count', 'stockouts', 'unavailable products')
      COMMENT = 'Number of products currently out of stock',
      
    -- Customer performance metrics
    orders_per_customer AS COUNT(order_.id) / NULLIF(COUNT(DISTINCT customer.id), 0)
      WITH SYNONYMS ('orders per customer', 'average orders per customer', 'customer order frequency')
      COMMENT = 'Average number of orders per customer for loyalty analysis',
      
    revenue_per_customer AS SUM(order_.ordertotal) / NULLIF(COUNT(DISTINCT customer.id), 0)
      WITH SYNONYMS ('revenue per customer', 'customer lifetime value', 'CLV', 'average customer value')
      COMMENT = 'Average revenue generated per customer for customer value analysis',
      
    repeat_customer_rate AS 
      COUNT(DISTINCT CASE WHEN customer_order_count.order_count > 1 THEN customer.id END) / 
      NULLIF(COUNT(DISTINCT customer.id), 0)
      WITH SYNONYMS ('repeat customer rate', 'customer retention rate', 'loyalty rate')
      COMMENT = 'Percentage of customers who have placed multiple orders',
      
    -- Supplier metrics
    products_per_supplier AS COUNT(DISTINCT product.id) / NULLIF(COUNT(DISTINCT supplier.id), 0)
      WITH SYNONYMS ('products per supplier', 'supplier catalog size')
      COMMENT = 'Average number of products per supplier for vendor analysis',
      
    -- Time-based metrics
    daily_orders AS COUNT(order_.id)
      WITH SYNONYMS ('daily orders', 'orders per day', 'daily transaction count')
      COMMENT = 'Number of orders placed per day for daily performance tracking',
      
    conversion_rate AS COUNT(order_.id) / NULLIF(COUNT(DISTINCT customer.id), 0)
      WITH SYNONYMS ('conversion rate', 'purchase conversion', 'customer conversion')
      COMMENT = 'Rate of customers who complete purchases'
  )

COMMENT = 'Comprehensive semantic view for e-commerce RDF data model with full semantic capabilities including dimensions, facts, metrics, and relationships optimized for natural language querying with Cortex Analyst and business intelligence analysis';

-- ================================================================
-- STEP 3: VERIFY SEMANTIC VIEW CREATION
-- ================================================================

SELECT '=== Verifying Semantic View Creation ===' as DEMO_STATUS;

-- Show the created semantic view
SHOW SEMANTIC VIEWS;

-- Show dimensions in the semantic view
SHOW SEMANTIC DIMENSIONS IN SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL;

-- Show metrics in the semantic view  
SHOW SEMANTIC METRICS IN SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL;

-- Show relationships
DESCRIBE SEMANTIC VIEW ECOMMERCE_SEMANTIC_MODEL;

-- ================================================================
-- STEP 4: DEMONSTRATE SEMANTIC VIEW QUERIES
-- ================================================================

SELECT '=== Demonstrating Semantic View Queries ===' as DEMO_STATUS;

-- Note: Semantic view queries are in preview. These examples show the intended usage.

-- Query 1: Basic revenue analysis
-- SELECT 
--     ORDER_YEAR,
--     total_revenue,
--     total_orders,
--     average_order_value
-- FROM ECOMMERCE_SEMANTIC_MODEL
-- GROUP BY ORDER_YEAR
-- ORDER BY ORDER_YEAR;

-- Query 2: Customer segmentation analysis  
-- SELECT 
--     CUSTOMER_NAME,
--     orders_per_customer,
--     revenue_per_customer,
--     total_orders
-- FROM ECOMMERCE_SEMANTIC_MODEL
-- GROUP BY CUSTOMER_NAME
-- ORDER BY revenue_per_customer DESC;

-- Query 3: Product performance by category
-- SELECT 
--     CATEGORY_NAME,
--     total_products,
--     average_product_price,
--     total_inventory_value
-- FROM ECOMMERCE_SEMANTIC_MODEL  
-- GROUP BY CATEGORY_NAME
-- ORDER BY total_inventory_value DESC;

-- Query 4: Time-based sales trends
-- SELECT 
--     ORDER_YEAR,
--     ORDER_MONTH,
--     monthly_revenue,
--     total_orders,
--     items_sold
-- FROM ECOMMERCE_SEMANTIC_MODEL
-- GROUP BY ORDER_YEAR, ORDER_MONTH
-- ORDER BY ORDER_YEAR, ORDER_MONTH;

-- Query 5: Inventory management insights
-- SELECT 
--     PRICE_TIER,
--     STOCK_STATUS,
--     total_products,
--     total_inventory_value,
--     out_of_stock_products
-- FROM ECOMMERCE_SEMANTIC_MODEL
-- GROUP BY PRICE_TIER, STOCK_STATUS
-- ORDER BY total_inventory_value DESC;

-- Instead, let's verify the underlying data for semantic view functionality
SELECT 'Underlying data verification for semantic view' as INFO;

-- Show sample data from key tables
SELECT 'Product Data Sample:' as DATA_TYPE, COUNT(*) as RECORD_COUNT FROM PRODUCT;
SELECT 'Customer Data Sample:' as DATA_TYPE, COUNT(*) as RECORD_COUNT FROM CUSTOMER;
SELECT 'Order Data Sample:' as DATA_TYPE, COUNT(*) as RECORD_COUNT FROM ORDER_;
SELECT 'Relationship Data Sample:' as DATA_TYPE, COUNT(*) as RECORD_COUNT FROM RELATIONSHIPS;

-- Show relationship types
SELECT 'Relationship Types:' as INFO,
       RELATIONSHIP_TYPE,
       COUNT(*) as COUNT
FROM RELATIONSHIPS
GROUP BY RELATIONSHIP_TYPE
ORDER BY COUNT DESC;

-- ================================================================
-- STEP 5: DEMONSTRATE CORTEX ANALYST PREPARATION
-- ================================================================

SELECT '=== Cortex Analyst Integration Preparation ===' as DEMO_STATUS;

-- The semantic view is now ready for Cortex Analyst natural language queries such as:
-- "What was our total revenue last year?"
-- "Show me the top customers by revenue"  
-- "Which products are out of stock?"
-- "What are our monthly sales trends?"
-- "Compare revenue by product category"

SELECT 'Cortex Analyst Natural Language Query Examples:' as FEATURE_TYPE,
       'What was our total revenue?' as EXAMPLE_QUERY_1,
       'Show me top customers by orders' as EXAMPLE_QUERY_2,
       'Which products are low in stock?' as EXAMPLE_QUERY_3,
       'Compare sales by month' as EXAMPLE_QUERY_4,
       'What are our best selling categories?' as EXAMPLE_QUERY_5;

-- ================================================================
-- STEP 6: ADVANCED SEMANTIC VIEW FEATURES DEMONSTRATION
-- ================================================================

SELECT '=== Advanced Semantic Features Demonstrated ===' as DEMO_STATUS;

-- Create additional semantic views for different business contexts
CREATE OR REPLACE SEMANTIC VIEW RDF_SEMANTIC_DB.SEMANTIC_VIEWS.INVENTORY_MANAGEMENT_VIEW

  TABLES (
    product AS SEMANTIC_VIEWS.PRODUCT
      PRIMARY KEY (ID)
      WITH SYNONYMS ('inventory items', 'stock items', 'products')
      COMMENT = 'Product inventory for stock management',
      
    supplier AS SEMANTIC_VIEWS.SUPPLIER
      PRIMARY KEY (ID)
      WITH SYNONYMS ('vendors', 'suppliers')
      COMMENT = 'Product suppliers for vendor management'
  )

  RELATIONSHIPS (
    product_suppliers AS
      product (URI) REFERENCES supplier (URI)
      THROUGH SEMANTIC_VIEWS.RELATIONSHIPS (SUBJECT_URI, OBJECT_URI)
      WHERE SEMANTIC_VIEWS.RELATIONSHIPS.RELATIONSHIP_TYPE = 'suppliedBy'
  )

  FACTS (
    product.stockquantity AS STOCK_LEVEL
      COMMENT = 'Current inventory level',
    product.price AS UNIT_VALUE
      COMMENT = 'Value per unit for inventory valuation'
  )

  DIMENSIONS (
    product.productname AS PRODUCT_NAME
      WITH SYNONYMS ('item name', 'product')
      COMMENT = 'Product identifier',
    supplier.suppliername AS SUPPLIER_NAME  
      WITH SYNONYMS ('vendor name', 'supplier')
      COMMENT = 'Supplier identifier'
  )

  METRICS (
    total_inventory_units AS SUM(product.stockquantity)
      WITH SYNONYMS ('total stock', 'inventory count')
      COMMENT = 'Total units in inventory',
      
    inventory_value AS SUM(product.price * product.stockquantity)
      WITH SYNONYMS ('stock value', 'inventory worth')
      COMMENT = 'Total monetary value of inventory'
  )

COMMENT = 'Specialized semantic view for inventory management and vendor analysis';

-- ================================================================
-- FINAL STATUS AND SUMMARY
-- ================================================================

SELECT '=== Semantic Views Demo Completed Successfully ===' as COMPLETION_STATUS;

-- Summary of what was created
SELECT 'Created Semantic Views:' as SUMMARY_TYPE,
       'ECOMMERCE_SEMANTIC_MODEL - Complete e-commerce semantic model' as VIEW_1,
       'INVENTORY_MANAGEMENT_VIEW - Inventory-focused semantic view' as VIEW_2;

SELECT 'Semantic Features Demonstrated:' as SUMMARY_TYPE,
       'Tables with primary keys and synonyms' as FEATURE_1,
       'Relationships between entities' as FEATURE_2,
       'Facts for numerical analysis' as FEATURE_3,
       'Dimensions for categorical grouping' as FEATURE_4,
       'Metrics with comprehensive business calculations' as FEATURE_5,
       'Comments and synonyms for natural language understanding' as FEATURE_6,
       'Multiple semantic views for different business contexts' as FEATURE_7;

SELECT 'Ready for Cortex Analyst Integration!' as FINAL_STATUS,
       'Natural language queries now supported through semantic layer' as CAPABILITY,
       CURRENT_TIMESTAMP as COMPLETION_TIME;