-- RDF to Snowflake Semantic Views Demo - Snowsight Deployment
-- Execute these commands in Snowflake Snowsight (Web UI) to deploy the demo
-- https://app.snowflake.com

-- ================================================================
-- CONFIGURATION - UPDATE THESE VALUES FOR YOUR ACCOUNT
-- ================================================================

-- Set your preferred names (or use defaults)
SET database_name = 'RDF_SEMANTIC_DB';
SET schema_name = 'SEMANTIC_VIEWS';  
SET warehouse_name = 'RDF_DEMO_WH';

-- ================================================================
-- STEP 1: ENVIRONMENT SETUP
-- ================================================================

-- Create and use warehouse
CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER($warehouse_name) 
WITH WAREHOUSE_SIZE = 'SMALL' 
AUTO_SUSPEND = 300 
AUTO_RESUME = TRUE;

USE WAREHOUSE IDENTIFIER($warehouse_name);

-- Create and use database
CREATE DATABASE IF NOT EXISTS IDENTIFIER($database_name);
USE DATABASE IDENTIFIER($database_name);

-- Create and use schema
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($schema_name);
USE SCHEMA IDENTIFIER($schema_name);

SELECT 'Environment setup completed successfully!' as STATUS,
       CURRENT_DATABASE() as DATABASE_NAME,
       CURRENT_SCHEMA() as SCHEMA_NAME,
       CURRENT_WAREHOUSE() as WAREHOUSE_NAME;

-- ================================================================
-- STEP 2: CREATE PYTHON UDFs
-- ================================================================

-- Copy and paste the contents of each UDF file below:

-- 2a. Copy contents from: python_udfs/rdf_parser_udf.sql
-- 2b. Copy contents from: python_udfs/semantic_view_generator_udf.sql  
-- 2c. Copy contents from: python_udfs/rdf_data_loader_udf.sql

SELECT 'Python UDFs created successfully!' as STATUS;

-- ================================================================
-- STEP 3: CREATE SUPPORTING TABLES
-- ================================================================

-- Create table to store RDF schemas
CREATE OR REPLACE TABLE RDF_SCHEMAS (
    SCHEMA_ID VARCHAR(100) NOT NULL,
    SCHEMA_NAME VARCHAR(255) NOT NULL,
    RDF_FORMAT VARCHAR(50) NOT NULL,
    RDF_CONTENT TEXT NOT NULL,
    UPLOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    DESCRIPTION TEXT,
    PRIMARY KEY (SCHEMA_ID)
);

-- Create table to store conversion results
CREATE OR REPLACE TABLE CONVERSION_RESULTS (
    CONVERSION_ID VARCHAR(100) NOT NULL,
    SCHEMA_ID VARCHAR(100) NOT NULL,
    CONVERSION_TYPE VARCHAR(50) NOT NULL,
    RESULT_DATA VARIANT,
    STATUS VARCHAR(20) DEFAULT 'SUCCESS',
    ERROR_MESSAGE TEXT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CONVERSION_ID),
    FOREIGN KEY (SCHEMA_ID) REFERENCES RDF_SCHEMAS(SCHEMA_ID)
);

-- Create metadata table for tracking semantic views
CREATE OR REPLACE TABLE SEMANTIC_VIEW_METADATA (
    VIEW_ID VARCHAR(100) NOT NULL,
    VIEW_NAME VARCHAR(255) NOT NULL,
    VIEW_TYPE VARCHAR(50) NOT NULL,
    SOURCE_RDF_CLASS VARCHAR(1000),
    BASE_TABLE VARCHAR(255),
    PROPERTIES VARIANT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (VIEW_ID)
);

-- Create helper function
CREATE OR REPLACE FUNCTION GENERATE_ID(prefix VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    SELECT prefix || '_' || REPLACE(UUID_STRING(), '-', '')
$$;

SELECT 'Supporting tables created successfully!' as STATUS;

-- ================================================================
-- STEP 4: CREATE SAMPLE SCHEMA AND DATA TABLES
-- ================================================================

-- Create base tables for RDF classes
CREATE OR REPLACE TABLE PRODUCT (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    PRODUCTID VARCHAR(255),
    PRODUCTNAME VARCHAR(16777216),
    PRICE NUMBER(38,2),
    STOCKQUANTITY NUMBER(38,0),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE CATEGORY (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    CATEGORYNAME VARCHAR(16777216),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE CUSTOMER (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    CUSTOMERNAME VARCHAR(16777216),
    EMAIL VARCHAR(16777216),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE ORDER_ (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    ORDERDATE TIMESTAMP_NTZ,
    ORDERTOTAL NUMBER(38,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE RELATIONSHIPS (
    ID VARCHAR(255) NOT NULL,
    SUBJECT_URI VARCHAR(1000) NOT NULL,
    PREDICATE_URI VARCHAR(1000) NOT NULL,
    OBJECT_URI VARCHAR(1000) NOT NULL,
    RELATIONSHIP_TYPE VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

SELECT 'Base tables created successfully!' as STATUS;

-- ================================================================
-- STEP 5: CREATE SEMANTIC VIEWS
-- ================================================================

-- Create semantic views with RDF annotations
CREATE OR REPLACE VIEW SV_PRODUCT AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    PRODUCTID as "Product ID",
    PRODUCTNAME as "Product Name", 
    PRICE as "Price",
    STOCKQUANTITY as "Stock Quantity",
    CREATED_AT,
    UPDATED_AT
FROM PRODUCT
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Product';

CREATE OR REPLACE VIEW SV_CATEGORY AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    CATEGORYNAME as "Category Name",
    CREATED_AT,
    UPDATED_AT
FROM CATEGORY
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Category';

CREATE OR REPLACE VIEW SV_CUSTOMER AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    CUSTOMERNAME as "Customer Name",
    EMAIL as "Email",
    CREATED_AT,
    UPDATED_AT
FROM CUSTOMER
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Customer';

CREATE OR REPLACE VIEW SV_ORDER AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    ORDERDATE as "Order Date",
    ORDERTOTAL as "Order Total",
    CREATED_AT,
    UPDATED_AT
FROM ORDER_
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Order';

CREATE OR REPLACE VIEW SV_RELATIONSHIPS AS
SELECT 
    ID,
    SUBJECT_URI,
    PREDICATE_URI,
    OBJECT_URI,
    RELATIONSHIP_TYPE,
    CREATED_AT
FROM RELATIONSHIPS
COMMENT = 'Semantic view for RDF object properties and relationships';

SELECT 'Semantic views created successfully!' as STATUS;

-- ================================================================
-- STEP 6: LOAD SAMPLE DATA
-- ================================================================

-- Load sample categories
INSERT INTO CATEGORY (ID, URI, CLASS_URI, CATEGORYNAME)
VALUES 
    ('ELECTRONICS', 'http://example.com/instances#electronics', 'http://example.com/ecommerce#Category', 'Electronics'),
    ('COMPUTERS', 'http://example.com/instances#computers', 'http://example.com/ecommerce#Category', 'Computers'),
    ('LAPTOPS', 'http://example.com/instances#laptops', 'http://example.com/ecommerce#Category', 'Laptops');

-- Load sample products
INSERT INTO PRODUCT (ID, URI, CLASS_URI, PRODUCTID, PRODUCTNAME, PRICE, STOCKQUANTITY)
VALUES 
    ('PRODUCT1', 'http://example.com/instances#product1', 'http://example.com/ecommerce#Product', 'PROD-001', 'UltraBook Pro 15', 1299.99, 25),
    ('PRODUCT2', 'http://example.com/instances#product2', 'http://example.com/ecommerce#Product', 'PROD-002', 'Wireless Mouse', 29.99, 150),
    ('PRODUCT3', 'http://example.com/instances#product3', 'http://example.com/ecommerce#Product', 'PROD-003', 'Gaming Laptop X1', 1899.99, 10);

-- Load sample customers
INSERT INTO CUSTOMER (ID, URI, CLASS_URI, CUSTOMERNAME, EMAIL)
VALUES 
    ('CUSTOMER1', 'http://example.com/instances#customer1', 'http://example.com/ecommerce#Customer', 'John Smith', 'john.smith@email.com'),
    ('CUSTOMER2', 'http://example.com/instances#customer2', 'http://example.com/ecommerce#Customer', 'Sarah Johnson', 'sarah.johnson@email.com');

-- Load sample orders
INSERT INTO ORDER_ (ID, URI, CLASS_URI, ORDERDATE, ORDERTOTAL)
VALUES 
    ('ORDER1', 'http://example.com/instances#order1', 'http://example.com/ecommerce#Order', '2024-01-15 10:30:00', 1329.98),
    ('ORDER2', 'http://example.com/instances#order2', 'http://example.com/ecommerce#Order', '2024-01-16 14:45:00', 1899.99);

-- Load sample relationships
INSERT INTO RELATIONSHIPS (ID, SUBJECT_URI, PREDICATE_URI, OBJECT_URI, RELATIONSHIP_TYPE)
VALUES 
    ('REL001', 'http://example.com/instances#product1', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#laptops', 'belongsToCategory'),
    ('REL002', 'http://example.com/instances#product2', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#electronics', 'belongsToCategory'),
    ('REL003', 'http://example.com/instances#order1', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer1', 'placedBy'),
    ('REL004', 'http://example.com/instances#order2', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer2', 'placedBy');

SELECT 'Sample data loaded successfully!' as STATUS;

-- ================================================================
-- STEP 7: VERIFICATION AND TESTING
-- ================================================================

-- Verify semantic views are working
SELECT 'Semantic Views Test:' as TEST_TYPE;

SELECT COUNT(*) as PRODUCT_COUNT FROM SV_PRODUCT;
SELECT COUNT(*) as CUSTOMER_COUNT FROM SV_CUSTOMER;
SELECT COUNT(*) as ORDER_COUNT FROM SV_ORDER;
SELECT COUNT(*) as RELATIONSHIP_COUNT FROM SV_RELATIONSHIPS;

-- Test a semantic query
SELECT 
    'Sample Semantic Query:' as QUERY_TYPE,
    p."Product Name",
    p."Price",
    c."Category Name"
FROM SV_PRODUCT p
JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI AND r.RELATIONSHIP_TYPE = 'belongsToCategory'
JOIN SV_CATEGORY c ON r.OBJECT_URI = c.URI
ORDER BY p."Price" DESC;

-- Show created views
SHOW VIEWS LIKE 'SV_%';

-- ================================================================
-- DEPLOYMENT COMPLETED!
-- ================================================================

SELECT 
    '🎉 RDF to Snowflake Demo Deployed Successfully! 🎉' as COMPLETION_STATUS,
    CURRENT_DATABASE() as DATABASE_NAME,
    CURRENT_SCHEMA() as SCHEMA_NAME,
    CURRENT_WAREHOUSE() as WAREHOUSE_NAME,
    CURRENT_TIMESTAMP() as DEPLOYMENT_TIME;

-- Next steps message
SELECT 'Next Steps:' as INFO,
       '1. Explore the semantic views (SV_*)' as STEP_1,
       '2. Try queries in examples/semantic_queries.sql' as STEP_2,
       '3. Load your own RDF data using the UDFs' as STEP_3;