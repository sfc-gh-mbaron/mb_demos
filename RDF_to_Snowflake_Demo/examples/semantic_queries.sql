-- Example queries demonstrating Snowflake semantic views created from RDF schemas
-- These queries showcase various semantic patterns and relationships

USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- === BASIC SEMANTIC VIEW QUERIES ===

-- Query 1: View all products with their semantic information
SELECT 
    'All Products' as QUERY_NAME,
    ID,
    URI,
    PRODUCTNAME,
    PRICE
FROM SV_PRODUCT
ORDER BY PRICE DESC;

-- Query 2: View all customers
SELECT 
    'All Customers' as QUERY_NAME,
    ID,
    URI, 
    CUSTOMERNAME
FROM SV_CUSTOMER;

-- Query 3: View all orders with dates
SELECT 
    'All Orders' as QUERY_NAME,
    ID,
    URI,
    ORDERDATE
FROM SV_ORDER
ORDER BY ORDERDATE DESC;

-- === RELATIONSHIP QUERIES ===

-- Query 4: Products and their categories (using relationships)
SELECT 
    'Products with Categories' as QUERY_NAME,
    p.PRODUCTNAME,
    p.PRICE,
    r.OBJECT_URI as CATEGORY_URI,
    r.RELATIONSHIP_TYPE
FROM SV_PRODUCT p
JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI
WHERE r.RELATIONSHIP_TYPE = 'belongsToCategory';

-- Query 5: Orders and their customers (using relationships)
SELECT 
    'Orders with Customers' as QUERY_NAME,
    o.URI as ORDER_URI,
    o.ORDERDATE,
    c.CUSTOMERNAME,
    r.RELATIONSHIP_TYPE
FROM SV_ORDER o
JOIN SV_RELATIONSHIPS r ON o.URI = r.SUBJECT_URI
JOIN SV_CUSTOMER c ON r.OBJECT_URI = c.URI
WHERE r.RELATIONSHIP_TYPE = 'placedBy';

-- === SEMANTIC PATTERN QUERIES ===

-- Query 6: Find all entities of a specific RDF type
SELECT 
    'Entities by RDF Type' as QUERY_NAME,
    CLASS_URI,
    COUNT(*) as ENTITY_COUNT
FROM (
    SELECT CLASS_URI FROM SV_PRODUCT
    UNION ALL
    SELECT CLASS_URI FROM SV_CUSTOMER
    UNION ALL
    SELECT CLASS_URI FROM SV_ORDER
) entities
GROUP BY CLASS_URI
ORDER BY ENTITY_COUNT DESC;

-- Query 7: Comprehensive entity-relationship view
SELECT 
    'Entity-Relationship Overview' as QUERY_NAME,
    r.SUBJECT_URI,
    r.PREDICATE_URI,
    r.OBJECT_URI,
    r.RELATIONSHIP_TYPE,
    'Object Property' as PROPERTY_TYPE
FROM SV_RELATIONSHIPS r

UNION ALL

SELECT 
    'Data Properties Overview' as QUERY_NAME,
    URI as SUBJECT_URI,
    'http://example.com/ecommerce#productName' as PREDICATE_URI,
    PRODUCTNAME as OBJECT_URI,
    'productName' as RELATIONSHIP_TYPE,
    'Data Property' as PROPERTY_TYPE
FROM SV_PRODUCT
WHERE PRODUCTNAME IS NOT NULL

UNION ALL

SELECT 
    'Data Properties Overview' as QUERY_NAME,
    URI as SUBJECT_URI,
    'http://example.com/ecommerce#price' as PREDICATE_URI,
    PRICE::VARCHAR as OBJECT_URI,
    'price' as RELATIONSHIP_TYPE,
    'Data Property' as PROPERTY_TYPE
FROM SV_PRODUCT
WHERE PRICE IS NOT NULL

ORDER BY SUBJECT_URI, PROPERTY_TYPE;

-- === ADVANCED SEMANTIC QUERIES ===

-- Query 8: Products in specific price ranges with semantic metadata
SELECT 
    'Products by Price Range' as QUERY_NAME,
    CASE 
        WHEN PRICE < 50 THEN 'Budget'
        WHEN PRICE BETWEEN 50 AND 500 THEN 'Mid-range'
        WHEN PRICE > 500 THEN 'Premium'
        ELSE 'Unpriced'
    END as PRICE_CATEGORY,
    COUNT(*) as PRODUCT_COUNT,
    AVG(PRICE) as AVERAGE_PRICE,
    MIN(PRICE) as MIN_PRICE,
    MAX(PRICE) as MAX_PRICE
FROM SV_PRODUCT
WHERE PRICE IS NOT NULL
GROUP BY PRICE_CATEGORY
ORDER BY AVERAGE_PRICE;

-- Query 9: Semantic network analysis - find connection patterns
WITH entity_connections AS (
    SELECT 
        SUBJECT_URI as ENTITY_URI,
        COUNT(DISTINCT OBJECT_URI) as OUTGOING_CONNECTIONS,
        COUNT(DISTINCT PREDICATE_URI) as RELATIONSHIP_TYPES
    FROM SV_RELATIONSHIPS
    GROUP BY SUBJECT_URI
    
    UNION ALL
    
    SELECT 
        OBJECT_URI as ENTITY_URI,
        COUNT(DISTINCT SUBJECT_URI) as INCOMING_CONNECTIONS,
        COUNT(DISTINCT PREDICATE_URI) as RELATIONSHIP_TYPES
    FROM SV_RELATIONSHIPS
    GROUP BY OBJECT_URI
)
SELECT 
    'Entity Connection Analysis' as QUERY_NAME,
    ENTITY_URI,
    SUM(OUTGOING_CONNECTIONS) as TOTAL_OUTGOING,
    SUM(INCOMING_CONNECTIONS) as TOTAL_INCOMING,
    MAX(RELATIONSHIP_TYPES) as RELATIONSHIP_DIVERSITY
FROM entity_connections
GROUP BY ENTITY_URI
HAVING TOTAL_OUTGOING > 0 OR TOTAL_INCOMING > 0
ORDER BY (TOTAL_OUTGOING + TOTAL_INCOMING) DESC;

-- Query 10: Temporal analysis of semantic data
SELECT 
    'Temporal Data Analysis' as QUERY_NAME,
    DATE_TRUNC('DAY', ORDERDATE) as ORDER_DAY,
    COUNT(*) as ORDERS_COUNT,
    COUNT(DISTINCT URI) as UNIQUE_ORDERS
FROM SV_ORDER
WHERE ORDERDATE IS NOT NULL
GROUP BY ORDER_DAY
ORDER BY ORDER_DAY;

-- === SEMANTIC VIEW METADATA QUERIES ===

-- Query 11: View information about the semantic model structure
SELECT 
    'Semantic Model Structure' as QUERY_NAME,
    'Tables' as OBJECT_TYPE,
    COUNT(*) as COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'
  AND TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT 
    'Semantic Model Structure' as QUERY_NAME,
    'Views' as OBJECT_TYPE,
    COUNT(*) as COUNT
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'
  AND VIEW_NAME LIKE 'SV_%'

UNION ALL

SELECT 
    'Semantic Model Structure' as QUERY_NAME,
    'Functions' as OBJECT_TYPE,
    COUNT(*) as COUNT
FROM INFORMATION_SCHEMA.FUNCTIONS
WHERE FUNCTION_SCHEMA = 'SEMANTIC_VIEWS';

-- Query 12: Data quality and completeness analysis
SELECT 
    'Data Quality Analysis' as QUERY_NAME,
    'Products' as ENTITY_TYPE,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(PRODUCTNAME) as RECORDS_WITH_NAME,
    COUNT(PRICE) as RECORDS_WITH_PRICE,
    ROUND((COUNT(PRODUCTNAME)::FLOAT / COUNT(*)) * 100, 2) as NAME_COMPLETENESS_PCT,
    ROUND((COUNT(PRICE)::FLOAT / COUNT(*)) * 100, 2) as PRICE_COMPLETENESS_PCT
FROM SV_PRODUCT

UNION ALL

SELECT 
    'Data Quality Analysis' as QUERY_NAME,
    'Customers' as ENTITY_TYPE,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(CUSTOMERNAME) as RECORDS_WITH_NAME,
    NULL as RECORDS_WITH_PRICE,
    ROUND((COUNT(CUSTOMERNAME)::FLOAT / COUNT(*)) * 100, 2) as NAME_COMPLETENESS_PCT,
    NULL as PRICE_COMPLETENESS_PCT
FROM SV_CUSTOMER

UNION ALL

SELECT 
    'Data Quality Analysis' as QUERY_NAME,
    'Orders' as ENTITY_TYPE,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(ORDERDATE) as RECORDS_WITH_DATE,
    NULL as RECORDS_WITH_PRICE,
    ROUND((COUNT(ORDERDATE)::FLOAT / COUNT(*)) * 100, 2) as DATE_COMPLETENESS_PCT,
    NULL as PRICE_COMPLETENESS_PCT
FROM SV_ORDER;

-- === SPARQL-LIKE QUERIES IN SQL ===

-- Query 13: SPARQL-style triple pattern matching using SQL
-- This simulates: SELECT ?product ?name ?price WHERE { ?product ex:productName ?name . ?product ex:price ?price }
WITH product_triples AS (
    SELECT 
        URI as PRODUCT,
        'productName' as PREDICATE1,
        PRODUCTNAME as NAME,
        'price' as PREDICATE2,
        PRICE as PRICE
    FROM SV_PRODUCT
    WHERE PRODUCTNAME IS NOT NULL AND PRICE IS NOT NULL
)
SELECT 
    'SPARQL-style Query Results' as QUERY_NAME,
    PRODUCT,
    NAME,
    PRICE
FROM product_triples
ORDER BY PRICE DESC;

-- Query 14: Complex semantic pattern matching
-- Find products that belong to categories and have prices > 100
SELECT 
    'Complex Semantic Pattern' as QUERY_NAME,
    p.URI as PRODUCT_URI,
    p.PRODUCTNAME,
    p.PRICE,
    r.OBJECT_URI as CATEGORY_URI
FROM SV_PRODUCT p
JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI
WHERE r.RELATIONSHIP_TYPE = 'belongsToCategory'
  AND p.PRICE > 100
ORDER BY p.PRICE DESC;

-- Final summary
SELECT 
    '=== Semantic Query Demo Completed ===' as COMPLETION_MESSAGE,
    COUNT(*) as TOTAL_SAMPLE_QUERIES
FROM (
    SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
) queries;