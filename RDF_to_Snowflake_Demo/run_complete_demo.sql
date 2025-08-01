-- Complete RDF to Snowflake Semantic Views Demo
-- This script runs the entire demonstration from start to finish

-- ================================================================
-- PART 1: SETUP AND INITIALIZATION
-- ================================================================

SELECT '=== Starting RDF to Snowflake Semantic Views Demo ===' as DEMO_STATUS;

-- Set up the environment
CREATE DATABASE IF NOT EXISTS RDF_SEMANTIC_DB;
USE DATABASE RDF_SEMANTIC_DB;
CREATE SCHEMA IF NOT EXISTS SEMANTIC_VIEWS;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- PART 2: CREATE PYTHON UDFs FOR RDF PROCESSING
-- ================================================================

SELECT '=== Creating Python UDFs for RDF Processing ===' as DEMO_STATUS;

-- Note: In practice, you would execute the UDF creation scripts from the python_udfs/ directory
-- For this demo, we'll assume the UDFs are created and proceed with the demonstration

-- ================================================================
-- PART 3: LOAD AND PARSE RDF SCHEMA
-- ================================================================

SELECT '=== Loading and Parsing RDF Schema ===' as DEMO_STATUS;

-- Create supporting tables
CREATE OR REPLACE TABLE RDF_SCHEMAS (
    SCHEMA_ID VARCHAR(100) NOT NULL,
    SCHEMA_NAME VARCHAR(255) NOT NULL,
    RDF_FORMAT VARCHAR(50) NOT NULL,
    RDF_CONTENT TEXT NOT NULL,
    UPLOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    DESCRIPTION TEXT,
    PRIMARY KEY (SCHEMA_ID)
);

-- Load sample RDF schema
INSERT INTO RDF_SCHEMAS (SCHEMA_ID, SCHEMA_NAME, RDF_FORMAT, RDF_CONTENT, DESCRIPTION)
VALUES (
    'ECOMMERCE_SCHEMA_001',
    'E-commerce Domain Model',
    'turtle',
    '# E-commerce RDF Schema
@prefix ex: <http://example.com/ecommerce#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Core Classes
ex:Product rdf:type rdfs:Class ;
    rdfs:label "Product" ;
    rdfs:comment "A product available for purchase" .

ex:Category rdf:type rdfs:Class ;
    rdfs:label "Category" ;
    rdfs:comment "A product category" .

ex:Customer rdf:type rdfs:Class ;
    rdfs:label "Customer" ;
    rdfs:comment "A customer who can place orders" .

ex:Order rdf:type rdfs:Class ;
    rdfs:label "Order" ;
    rdfs:comment "A purchase order" .

ex:OrderItem rdf:type rdfs:Class ;
    rdfs:label "Order Item" ;
    rdfs:comment "An individual item within an order" .

ex:Supplier rdf:type rdfs:Class ;
    rdfs:label "Supplier" ;
    rdfs:comment "A product supplier" .

# Data Properties
ex:productId rdf:type rdf:Property ;
    rdfs:label "Product ID" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:string .

ex:productName rdf:type rdf:Property ;
    rdfs:label "Product Name" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:string .

ex:price rdf:type rdf:Property ;
    rdfs:label "Price" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:decimal .

ex:stockQuantity rdf:type rdf:Property ;
    rdfs:label "Stock Quantity" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:integer .

ex:categoryName rdf:type rdf:Property ;
    rdfs:label "Category Name" ;
    rdfs:domain ex:Category ;
    rdfs:range xsd:string .

ex:customerName rdf:type rdf:Property ;
    rdfs:label "Customer Name" ;
    rdfs:domain ex:Customer ;
    rdfs:range xsd:string .

ex:email rdf:type rdf:Property ;
    rdfs:label "Email" ;
    rdfs:domain ex:Customer ;
    rdfs:range xsd:string .

ex:orderDate rdf:type rdf:Property ;
    rdfs:label "Order Date" ;
    rdfs:domain ex:Order ;
    rdfs:range xsd:dateTime .

ex:orderTotal rdf:type rdf:Property ;
    rdfs:label "Order Total" ;
    rdfs:domain ex:Order ;
    rdfs:range xsd:decimal .

# Object Properties (Relationships)
ex:belongsToCategory rdf:type rdf:Property ;
    rdfs:label "belongs to category" ;
    rdfs:domain ex:Product ;
    rdfs:range ex:Category .

ex:suppliedBy rdf:type rdf:Property ;
    rdfs:label "supplied by" ;
    rdfs:domain ex:Product ;
    rdfs:range ex:Supplier .

ex:placedBy rdf:type rdf:Property ;
    rdfs:label "placed by" ;
    rdfs:domain ex:Order ;
    rdfs:range ex:Customer .

ex:contains rdf:type rdf:Property ;
    rdfs:label "contains" ;
    rdfs:domain ex:Order ;
    rdfs:range ex:OrderItem .

ex:orderItemProduct rdf:type rdf:Property ;
    rdfs:label "order item product" ;
    rdfs:domain ex:OrderItem ;
    rdfs:range ex:Product .

# Hierarchical relationships
ex:parentCategory rdf:type rdf:Property ;
    rdfs:label "parent category" ;
    rdfs:domain ex:Category ;
    rdfs:range ex:Category .',
    'Complete e-commerce RDF schema with classes, properties, and relationships'
);

SELECT 'RDF Schema loaded successfully' as STATUS, SCHEMA_NAME, UPLOADED_AT 
FROM RDF_SCHEMAS WHERE SCHEMA_ID = 'ECOMMERCE_SCHEMA_001';

-- ================================================================
-- PART 4: CREATE SEMANTIC TABLES AND VIEWS
-- ================================================================

SELECT '=== Creating Semantic Tables and Views ===' as DEMO_STATUS;

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

CREATE OR REPLACE TABLE ORDERITEM (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    QUANTITY NUMBER(38,0),
    UNITPRICE NUMBER(38,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE SUPPLIER (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    SUPPLIERNAME VARCHAR(16777216),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

-- Create relationships table
CREATE OR REPLACE TABLE RELATIONSHIPS (
    ID VARCHAR(255) NOT NULL,
    SUBJECT_URI VARCHAR(1000) NOT NULL,
    PREDICATE_URI VARCHAR(1000) NOT NULL,
    OBJECT_URI VARCHAR(1000) NOT NULL,
    RELATIONSHIP_TYPE VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

-- Create semantic views
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

CREATE OR REPLACE VIEW SV_ORDERITEM AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    QUANTITY as "Quantity",
    UNITPRICE as "Unit Price",
    CREATED_AT,
    UPDATED_AT
FROM ORDERITEM
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#OrderItem';

CREATE OR REPLACE VIEW SV_SUPPLIER AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    SUPPLIERNAME as "Supplier Name",
    CREATED_AT,
    UPDATED_AT
FROM SUPPLIER
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Supplier';

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

-- Create hierarchical view
CREATE OR REPLACE VIEW SV_CLASS_HIERARCHY AS
WITH RECURSIVE hierarchy_cte AS (
    -- Base case: direct parent-child relationships
    SELECT 
        SUBJECT_URI as CHILD_CLASS,
        OBJECT_URI as PARENT_CLASS,
        1 as LEVEL,
        SUBJECT_URI as ROOT_CLASS
    FROM RELATIONSHIPS 
    WHERE RELATIONSHIP_TYPE = 'subClassOf'
    
    UNION ALL
    
    -- Recursive case: transitive relationships
    SELECT 
        h.CHILD_CLASS,
        r.OBJECT_URI as PARENT_CLASS,
        h.LEVEL + 1,
        h.ROOT_CLASS
    FROM hierarchy_cte h
    JOIN RELATIONSHIPS r ON h.PARENT_CLASS = r.SUBJECT_URI
    WHERE r.RELATIONSHIP_TYPE = 'subClassOf' AND h.LEVEL < 10
)
SELECT * FROM hierarchy_cte
COMMENT = 'Hierarchical view of RDF class relationships';

-- Create master semantic view
CREATE OR REPLACE VIEW SV_MASTER_SEMANTIC_MODEL AS
SELECT 
    'CLASS' as ENTITY_TYPE,
    URI as ENTITY_URI,
    CLASS_URI as TYPE_URI,
    NULL as PROPERTY_URI,
    NULL as VALUE_,
    CREATED_AT
FROM (
    SELECT URI, CLASS_URI, CREATED_AT FROM PRODUCT
    UNION ALL
    SELECT URI, CLASS_URI, CREATED_AT FROM CATEGORY
    UNION ALL
    SELECT URI, CLASS_URI, CREATED_AT FROM CUSTOMER
    UNION ALL
    SELECT URI, CLASS_URI, CREATED_AT FROM ORDER_
    UNION ALL
    SELECT URI, CLASS_URI, CREATED_AT FROM ORDERITEM
    UNION ALL
    SELECT URI, CLASS_URI, CREATED_AT FROM SUPPLIER
) classes

UNION ALL

SELECT 
    'RELATIONSHIP' as ENTITY_TYPE,
    SUBJECT_URI as ENTITY_URI,
    PREDICATE_URI as TYPE_URI,
    PREDICATE_URI as PROPERTY_URI,
    OBJECT_URI as VALUE_,
    CREATED_AT
FROM RELATIONSHIPS
COMMENT = 'Master semantic model view combining all RDF entities and relationships';

SELECT 'Semantic tables and views created successfully' as STATUS;

-- ================================================================
-- PART 5: LOAD SAMPLE DATA
-- ================================================================

SELECT '=== Loading Sample RDF Instance Data ===' as DEMO_STATUS;

-- Load categories
INSERT INTO CATEGORY (ID, URI, CLASS_URI, CATEGORYNAME)
VALUES 
    ('ELECTRONICS', 'http://example.com/instances#electronics', 'http://example.com/ecommerce#Category', 'Electronics'),
    ('COMPUTERS', 'http://example.com/instances#computers', 'http://example.com/ecommerce#Category', 'Computers'),
    ('LAPTOPS', 'http://example.com/instances#laptops', 'http://example.com/ecommerce#Category', 'Laptops'),
    ('ACCESSORIES', 'http://example.com/instances#accessories', 'http://example.com/ecommerce#Category', 'Accessories');

-- Load suppliers
INSERT INTO SUPPLIER (ID, URI, CLASS_URI, SUPPLIERNAME)
VALUES 
    ('SUPPLIER1', 'http://example.com/instances#supplier1', 'http://example.com/ecommerce#Supplier', 'TechCorp Inc.'),
    ('SUPPLIER2', 'http://example.com/instances#supplier2', 'http://example.com/ecommerce#Supplier', 'GadgetPro Ltd.');

-- Load products
INSERT INTO PRODUCT (ID, URI, CLASS_URI, PRODUCTID, PRODUCTNAME, PRICE, STOCKQUANTITY)
VALUES 
    ('PRODUCT1', 'http://example.com/instances#product1', 'http://example.com/ecommerce#Product', 'PROD-001', 'UltraBook Pro 15', 1299.99, 25),
    ('PRODUCT2', 'http://example.com/instances#product2', 'http://example.com/ecommerce#Product', 'PROD-002', 'Wireless Mouse', 29.99, 150),
    ('PRODUCT3', 'http://example.com/instances#product3', 'http://example.com/ecommerce#Product', 'PROD-003', 'Gaming Laptop X1', 1899.99, 10),
    ('PRODUCT4', 'http://example.com/instances#product4', 'http://example.com/ecommerce#Product', 'PROD-004', 'USB-C Cable', 15.99, 200),
    ('PRODUCT5', 'http://example.com/instances#product5', 'http://example.com/ecommerce#Product', 'PROD-005', 'Mechanical Keyboard', 129.99, 75);

-- Load customers
INSERT INTO CUSTOMER (ID, URI, CLASS_URI, CUSTOMERNAME, EMAIL)
VALUES 
    ('CUSTOMER1', 'http://example.com/instances#customer1', 'http://example.com/ecommerce#Customer', 'John Smith', 'john.smith@email.com'),
    ('CUSTOMER2', 'http://example.com/instances#customer2', 'http://example.com/ecommerce#Customer', 'Sarah Johnson', 'sarah.johnson@email.com'),
    ('CUSTOMER3', 'http://example.com/instances#customer3', 'http://example.com/ecommerce#Customer', 'Mike Wilson', 'mike.wilson@email.com'),
    ('CUSTOMER4', 'http://example.com/instances#customer4', 'http://example.com/ecommerce#Customer', 'Emily Davis', 'emily.davis@email.com');

-- Load orders
INSERT INTO ORDER_ (ID, URI, CLASS_URI, ORDERDATE, ORDERTOTAL)
VALUES 
    ('ORDER1', 'http://example.com/instances#order1', 'http://example.com/ecommerce#Order', '2024-01-15 10:30:00', 1329.98),
    ('ORDER2', 'http://example.com/instances#order2', 'http://example.com/ecommerce#Order', '2024-01-16 14:45:00', 1899.99),
    ('ORDER3', 'http://example.com/instances#order3', 'http://example.com/ecommerce#Order', '2024-01-17 09:15:00', 175.97),
    ('ORDER4', 'http://example.com/instances#order4', 'http://example.com/ecommerce#Order', '2024-01-18 16:20:00', 129.99);

-- Load order items
INSERT INTO ORDERITEM (ID, URI, CLASS_URI, QUANTITY, UNITPRICE)
VALUES 
    ('ORDERITEM1', 'http://example.com/instances#orderitem1', 'http://example.com/ecommerce#OrderItem', 1, 1299.99),
    ('ORDERITEM2', 'http://example.com/instances#orderitem2', 'http://example.com/ecommerce#OrderItem', 1, 29.99),
    ('ORDERITEM3', 'http://example.com/instances#orderitem3', 'http://example.com/ecommerce#OrderItem', 1, 1899.99),
    ('ORDERITEM4', 'http://example.com/instances#orderitem4', 'http://example.com/ecommerce#OrderItem', 10, 15.99),
    ('ORDERITEM5', 'http://example.com/instances#orderitem5', 'http://example.com/ecommerce#OrderItem', 1, 129.99);

-- Load relationships
INSERT INTO RELATIONSHIPS (ID, SUBJECT_URI, PREDICATE_URI, OBJECT_URI, RELATIONSHIP_TYPE)
VALUES 
    -- Product categories
    ('REL001', 'http://example.com/instances#product1', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#laptops', 'belongsToCategory'),
    ('REL002', 'http://example.com/instances#product2', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#accessories', 'belongsToCategory'),
    ('REL003', 'http://example.com/instances#product3', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#laptops', 'belongsToCategory'),
    ('REL004', 'http://example.com/instances#product4', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#accessories', 'belongsToCategory'),
    ('REL005', 'http://example.com/instances#product5', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#accessories', 'belongsToCategory'),
    
    -- Product suppliers
    ('REL006', 'http://example.com/instances#product1', 'http://example.com/ecommerce#suppliedBy', 'http://example.com/instances#supplier1', 'suppliedBy'),
    ('REL007', 'http://example.com/instances#product2', 'http://example.com/ecommerce#suppliedBy', 'http://example.com/instances#supplier2', 'suppliedBy'),
    ('REL008', 'http://example.com/instances#product3', 'http://example.com/ecommerce#suppliedBy', 'http://example.com/instances#supplier1', 'suppliedBy'),
    ('REL009', 'http://example.com/instances#product4', 'http://example.com/ecommerce#suppliedBy', 'http://example.com/instances#supplier2', 'suppliedBy'),
    ('REL010', 'http://example.com/instances#product5', 'http://example.com/ecommerce#suppliedBy', 'http://example.com/instances#supplier1', 'suppliedBy'),
    
    -- Order customers
    ('REL011', 'http://example.com/instances#order1', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer1', 'placedBy'),
    ('REL012', 'http://example.com/instances#order2', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer2', 'placedBy'),
    ('REL013', 'http://example.com/instances#order3', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer3', 'placedBy'),
    ('REL014', 'http://example.com/instances#order4', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer4', 'placedBy'),
    
    -- Order items
    ('REL015', 'http://example.com/instances#order1', 'http://example.com/ecommerce#contains', 'http://example.com/instances#orderitem1', 'contains'),
    ('REL016', 'http://example.com/instances#order1', 'http://example.com/ecommerce#contains', 'http://example.com/instances#orderitem2', 'contains'),
    ('REL017', 'http://example.com/instances#order2', 'http://example.com/ecommerce#contains', 'http://example.com/instances#orderitem3', 'contains'),
    ('REL018', 'http://example.com/instances#order3', 'http://example.com/ecommerce#contains', 'http://example.com/instances#orderitem4', 'contains'),
    ('REL019', 'http://example.com/instances#order4', 'http://example.com/ecommerce#contains', 'http://example.com/instances#orderitem5', 'contains'),
    
    -- Order item products
    ('REL020', 'http://example.com/instances#orderitem1', 'http://example.com/ecommerce#orderItemProduct', 'http://example.com/instances#product1', 'orderItemProduct'),
    ('REL021', 'http://example.com/instances#orderitem2', 'http://example.com/ecommerce#orderItemProduct', 'http://example.com/instances#product2', 'orderItemProduct'),
    ('REL022', 'http://example.com/instances#orderitem3', 'http://example.com/ecommerce#orderItemProduct', 'http://example.com/instances#product3', 'orderItemProduct'),
    ('REL023', 'http://example.com/instances#orderitem4', 'http://example.com/ecommerce#orderItemProduct', 'http://example.com/instances#product4', 'orderItemProduct'),
    ('REL024', 'http://example.com/instances#orderitem5', 'http://example.com/ecommerce#orderItemProduct', 'http://example.com/instances#product5', 'orderItemProduct'),
    
    -- Category hierarchy
    ('REL025', 'http://example.com/instances#computers', 'http://example.com/ecommerce#parentCategory', 'http://example.com/instances#electronics', 'parentCategory'),
    ('REL026', 'http://example.com/instances#laptops', 'http://example.com/ecommerce#parentCategory', 'http://example.com/instances#computers', 'parentCategory'),
    ('REL027', 'http://example.com/instances#accessories', 'http://example.com/ecommerce#parentCategory', 'http://example.com/instances#electronics', 'parentCategory');

SELECT 'Sample data loaded successfully' as STATUS;

-- ================================================================
-- PART 6: DEMONSTRATE SEMANTIC QUERIES
-- ================================================================

SELECT '=== Demonstrating Semantic Queries ===' as DEMO_STATUS;

-- Basic entity queries
SELECT 'Products Overview:' as QUERY_TYPE, COUNT(*) as TOTAL_PRODUCTS, AVG(PRICE) as AVERAGE_PRICE
FROM SV_PRODUCT;

SELECT 'Customers Overview:' as QUERY_TYPE, COUNT(*) as TOTAL_CUSTOMERS, NULL as AVERAGE_PRICE
FROM SV_CUSTOMER;

SELECT 'Orders Overview:' as QUERY_TYPE, COUNT(*) as TOTAL_ORDERS, AVG(ORDERTOTAL) as AVERAGE_ORDER_VALUE
FROM SV_ORDER;

-- Relationship queries
SELECT 
    'Product-Category Relationships:' as QUERY_TYPE,
    p."Product Name",
    p."Price",
    c."Category Name"
FROM SV_PRODUCT p
JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI AND r.RELATIONSHIP_TYPE = 'belongsToCategory'
JOIN SV_CATEGORY c ON r.OBJECT_URI = c.URI
ORDER BY p."Price" DESC;

-- Order analysis
SELECT 
    'Order Analysis:' as QUERY_TYPE,
    o.URI as ORDER_URI,
    o."Order Date",
    o."Order Total",
    c."Customer Name"
FROM SV_ORDER o
JOIN SV_RELATIONSHIPS r ON o.URI = r.SUBJECT_URI AND r.RELATIONSHIP_TYPE = 'placedBy'
JOIN SV_CUSTOMER c ON r.OBJECT_URI = c.URI
ORDER BY o."Order Date" DESC;

-- Complex semantic query: Full order details
SELECT 
    'Complete Order Details:' as QUERY_TYPE,
    o."Order Date",
    c."Customer Name",
    p."Product Name",
    oi."Quantity",
    oi."Unit Price",
    (oi."Quantity" * oi."Unit Price") as LINE_TOTAL
FROM SV_ORDER o
JOIN SV_RELATIONSHIPS r1 ON o.URI = r1.SUBJECT_URI AND r1.RELATIONSHIP_TYPE = 'placedBy'
JOIN SV_CUSTOMER c ON r1.OBJECT_URI = c.URI
JOIN SV_RELATIONSHIPS r2 ON o.URI = r2.SUBJECT_URI AND r2.RELATIONSHIP_TYPE = 'contains'
JOIN SV_ORDERITEM oi ON r2.OBJECT_URI = oi.URI
JOIN SV_RELATIONSHIPS r3 ON oi.URI = r3.SUBJECT_URI AND r3.RELATIONSHIP_TYPE = 'orderItemProduct'
JOIN SV_PRODUCT p ON r3.OBJECT_URI = p.URI
ORDER BY o."Order Date", c."Customer Name", p."Product Name";

-- ================================================================
-- PART 7: SUMMARY AND METRICS
-- ================================================================

SELECT '=== Demo Summary and Metrics ===' as DEMO_STATUS;

-- Data summary
SELECT 
    'Entity Counts:' as METRIC_TYPE,
    'Products' as ENTITY_TYPE,
    COUNT(*) as COUNT
FROM SV_PRODUCT
UNION ALL
SELECT 'Entity Counts:', 'Categories', COUNT(*) FROM SV_CATEGORY
UNION ALL
SELECT 'Entity Counts:', 'Customers', COUNT(*) FROM SV_CUSTOMER
UNION ALL
SELECT 'Entity Counts:', 'Orders', COUNT(*) FROM SV_ORDER
UNION ALL
SELECT 'Entity Counts:', 'Order Items', COUNT(*) FROM SV_ORDERITEM
UNION ALL
SELECT 'Entity Counts:', 'Suppliers', COUNT(*) FROM SV_SUPPLIER
UNION ALL
SELECT 'Entity Counts:', 'Relationships', COUNT(*) FROM SV_RELATIONSHIPS;

-- Relationship type summary
SELECT 
    'Relationship Types:' as METRIC_TYPE,
    RELATIONSHIP_TYPE as ENTITY_TYPE,
    COUNT(*) as COUNT
FROM SV_RELATIONSHIPS
GROUP BY RELATIONSHIP_TYPE
ORDER BY COUNT DESC;

-- Final success message
SELECT 
    '=== RDF to Snowflake Semantic Views Demo Completed Successfully! ===' as DEMO_COMPLETION,
    CURRENT_TIMESTAMP as COMPLETION_TIME;

-- Show created objects
SELECT 'Created Semantic Views:' as INFO;
SHOW VIEWS LIKE 'SV_%';

SELECT 'Demo database and schema information:' as INFO,
       CURRENT_DATABASE() as DATABASE_NAME,
       CURRENT_SCHEMA() as SCHEMA_NAME;