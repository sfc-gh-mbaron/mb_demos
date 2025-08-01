-- Example script for loading RDF instance data into semantic views
-- This demonstrates how to use the RDF data loader UDF

USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- === STEP 1: Prepare sample RDF instance data ===

-- Load comprehensive sample data
SET sample_rdf_data = '# Sample E-commerce Data Instances
@prefix ex: <http://example.com/ecommerce#> .
@prefix inst: <http://example.com/instances#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Category instances
inst:electronics rdf:type ex:Category ;
    rdfs:label "Electronics" .

inst:computers rdf:type ex:Category ;
    rdfs:label "Computers" ;
    ex:parentCategory inst:electronics .

inst:laptops rdf:type ex:Category ;
    rdfs:label "Laptops" ;
    ex:parentCategory inst:computers .

# Product instances
inst:product1 rdf:type ex:Product ;
    ex:productName "UltraBook Pro 15" ;
    ex:price "1299.99"^^xsd:decimal ;
    ex:belongsToCategory inst:laptops .

inst:product2 rdf:type ex:Product ;
    ex:productName "Wireless Mouse" ;
    ex:price "29.99"^^xsd:decimal ;
    ex:belongsToCategory inst:electronics .

inst:product3 rdf:type ex:Product ;
    ex:productName "Gaming Laptop X1" ;
    ex:price "1899.99"^^xsd:decimal ;
    ex:belongsToCategory inst:laptops .

inst:product4 rdf:type ex:Product ;
    ex:productName "USB-C Cable" ;
    ex:price "15.99"^^xsd:decimal ;
    ex:belongsToCategory inst:electronics .

# Customer instances
inst:customer1 rdf:type ex:Customer ;
    ex:customerName "John Smith" ;
    ex:email "john.smith@email.com" .

inst:customer2 rdf:type ex:Customer ;
    ex:customerName "Sarah Johnson" ;
    ex:email "sarah.johnson@email.com" .

inst:customer3 rdf:type ex:Customer ;
    ex:customerName "Mike Wilson" ;
    ex:email "mike.wilson@email.com" .

# Order instances
inst:order1 rdf:type ex:Order ;
    ex:orderDate "2024-01-15T10:30:00"^^xsd:dateTime ;
    ex:placedBy inst:customer1 .

inst:order2 rdf:type ex:Order ;
    ex:orderDate "2024-01-16T14:45:00"^^xsd:dateTime ;
    ex:placedBy inst:customer2 .

inst:order3 rdf:type ex:Order ;
    ex:orderDate "2024-01-17T09:15:00"^^xsd:dateTime ;
    ex:placedBy inst:customer3 .';

-- === STEP 2: Use the RDF data loader UDF ===

-- Process the RDF data and generate insert statements
SELECT 
    'Processing RDF instance data...' as STATUS;

-- Call the RDF data loader UDF
SET load_result = (SELECT LOAD_RDF_DATA($sample_rdf_data, 'turtle', 'RDF_SEMANTIC_DB', 'SEMANTIC_VIEWS'));

-- Display the loading results
SELECT 
    'RDF Data Loading Results:' as INFO,
    PARSE_JSON($load_result) as LOAD_RESULTS;

-- Extract and display the data summary
SELECT 
    'Data Summary:' as INFO,
    PARSE_JSON($load_result):data_summary as DATA_SUMMARY;

-- Extract and display the generated INSERT statements
SELECT 
    'Generated INSERT Statements:' as INFO,
    value as INSERT_STATEMENT,
    row_number() OVER (ORDER BY seq) as STATEMENT_NUMBER
FROM TABLE(FLATTEN(PARSE_JSON($load_result):insert_statements));

-- === STEP 3: Execute the generated INSERT statements ===
-- Note: In a production environment, you would extract and execute these statements programmatically

-- Clear existing data for clean demo
DELETE FROM PRODUCT;
DELETE FROM CATEGORY;  
DELETE FROM CUSTOMER;
DELETE FROM ORDER_;
DELETE FROM RELATIONSHIPS;

-- Sample manual data insertion based on the RDF data
-- (In practice, you would execute the generated INSERT statements from the UDF)

-- Insert Categories
INSERT INTO CATEGORY (ID, URI, CLASS_URI)
VALUES 
    ('ELECTRONICS', 'http://example.com/instances#electronics', 'http://example.com/ecommerce#Category'),
    ('COMPUTERS', 'http://example.com/instances#computers', 'http://example.com/ecommerce#Category'),
    ('LAPTOPS', 'http://example.com/instances#laptops', 'http://example.com/ecommerce#Category');

-- Insert Products
INSERT INTO PRODUCT (ID, URI, CLASS_URI, PRODUCTNAME, PRICE)
VALUES 
    ('PRODUCT1', 'http://example.com/instances#product1', 'http://example.com/ecommerce#Product', 'UltraBook Pro 15', 1299.99),
    ('PRODUCT2', 'http://example.com/instances#product2', 'http://example.com/ecommerce#Product', 'Wireless Mouse', 29.99),
    ('PRODUCT3', 'http://example.com/instances#product3', 'http://example.com/ecommerce#Product', 'Gaming Laptop X1', 1899.99),
    ('PRODUCT4', 'http://example.com/instances#product4', 'http://example.com/ecommerce#Product', 'USB-C Cable', 15.99);

-- Insert Customers
INSERT INTO CUSTOMER (ID, URI, CLASS_URI, CUSTOMERNAME)
VALUES 
    ('CUSTOMER1', 'http://example.com/instances#customer1', 'http://example.com/ecommerce#Customer', 'John Smith'),
    ('CUSTOMER2', 'http://example.com/instances#customer2', 'http://example.com/ecommerce#Customer', 'Sarah Johnson'),
    ('CUSTOMER3', 'http://example.com/instances#customer3', 'http://example.com/ecommerce#Customer', 'Mike Wilson');

-- Insert Orders
INSERT INTO ORDER_ (ID, URI, CLASS_URI, ORDERDATE)
VALUES 
    ('ORDER1', 'http://example.com/instances#order1', 'http://example.com/ecommerce#Order', '2024-01-15 10:30:00'),
    ('ORDER2', 'http://example.com/instances#order2', 'http://example.com/ecommerce#Order', '2024-01-16 14:45:00'),
    ('ORDER3', 'http://example.com/instances#order3', 'http://example.com/ecommerce#Order', '2024-01-17 09:15:00');

-- Insert Relationships
INSERT INTO RELATIONSHIPS (ID, SUBJECT_URI, PREDICATE_URI, OBJECT_URI, RELATIONSHIP_TYPE)
VALUES 
    ('REL001', 'http://example.com/instances#product1', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#laptops', 'belongsToCategory'),
    ('REL002', 'http://example.com/instances#product2', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#electronics', 'belongsToCategory'),
    ('REL003', 'http://example.com/instances#product3', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#laptops', 'belongsToCategory'),
    ('REL004', 'http://example.com/instances#product4', 'http://example.com/ecommerce#belongsToCategory', 'http://example.com/instances#electronics', 'belongsToCategory'),
    ('REL005', 'http://example.com/instances#order1', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer1', 'placedBy'),
    ('REL006', 'http://example.com/instances#order2', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer2', 'placedBy'),
    ('REL007', 'http://example.com/instances#order3', 'http://example.com/ecommerce#placedBy', 'http://example.com/instances#customer3', 'placedBy'),
    ('REL008', 'http://example.com/instances#computers', 'http://example.com/ecommerce#parentCategory', 'http://example.com/instances#electronics', 'parentCategory'),
    ('REL009', 'http://example.com/instances#laptops', 'http://example.com/ecommerce#parentCategory', 'http://example.com/instances#computers', 'parentCategory');

-- === STEP 4: Verify the loaded data ===

SELECT 'Data loading verification:' as INFO;

-- Check loaded products
SELECT 
    'Products:' as ENTITY_TYPE,
    COUNT(*) as RECORD_COUNT,
    AVG(PRICE) as AVERAGE_PRICE
FROM SV_PRODUCT;

-- Check loaded customers  
SELECT 
    'Customers:' as ENTITY_TYPE,
    COUNT(*) as RECORD_COUNT,
    NULL as AVERAGE_PRICE
FROM SV_CUSTOMER;

-- Check loaded orders
SELECT 
    'Orders:' as ENTITY_TYPE,
    COUNT(*) as RECORD_COUNT,
    NULL as AVERAGE_PRICE
FROM SV_ORDER;

-- Check relationships
SELECT 
    'Relationships:' as ENTITY_TYPE,
    COUNT(*) as RECORD_COUNT,
    COUNT(DISTINCT RELATIONSHIP_TYPE) as RELATIONSHIP_TYPES
FROM SV_RELATIONSHIPS;

-- === STEP 5: Test semantic queries on loaded data ===

-- Products with their categories
SELECT 
    'Products with Categories:' as QUERY_TYPE,
    p.PRODUCTNAME,
    p.PRICE,
    r.OBJECT_URI as CATEGORY_URI
FROM SV_PRODUCT p
LEFT JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI AND r.RELATIONSHIP_TYPE = 'belongsToCategory'
ORDER BY p.PRICE DESC;

-- Orders with customers
SELECT 
    'Orders with Customers:' as QUERY_TYPE,
    o.URI as ORDER_URI,
    o.ORDERDATE,
    c.CUSTOMERNAME
FROM SV_ORDER o
LEFT JOIN SV_RELATIONSHIPS r ON o.URI = r.SUBJECT_URI AND r.RELATIONSHIP_TYPE = 'placedBy'
LEFT JOIN SV_CUSTOMER c ON r.OBJECT_URI = c.URI
ORDER BY o.ORDERDATE;

-- Category hierarchy
SELECT 
    'Category Hierarchy:' as QUERY_TYPE,
    child_cat.URI as CHILD_CATEGORY,
    parent_rel.OBJECT_URI as PARENT_CATEGORY,
    parent_rel.RELATIONSHIP_TYPE
FROM CATEGORY child_cat
LEFT JOIN SV_RELATIONSHIPS parent_rel ON child_cat.URI = parent_rel.SUBJECT_URI 
    AND parent_rel.RELATIONSHIP_TYPE = 'parentCategory'
ORDER BY parent_rel.OBJECT_URI, child_cat.URI;

-- === STEP 6: Data loading statistics ===

-- Record loading statistics
INSERT INTO DATA_LOAD_STATS (
    LOAD_ID, 
    SCHEMA_ID, 
    TABLE_NAME, 
    RECORDS_LOADED, 
    LOAD_STATUS,
    LOAD_START_TIME,
    LOAD_END_TIME
)
SELECT 
    GENERATE_ID('LOAD'),
    'DEMO_SCHEMA',
    table_name,
    record_count,
    'SUCCESS',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM (
    SELECT 'PRODUCT' as table_name, COUNT(*) as record_count FROM PRODUCT
    UNION ALL
    SELECT 'CUSTOMER' as table_name, COUNT(*) as record_count FROM CUSTOMER  
    UNION ALL
    SELECT 'ORDER_' as table_name, COUNT(*) as record_count FROM ORDER_
    UNION ALL
    SELECT 'CATEGORY' as table_name, COUNT(*) as record_count FROM CATEGORY
    UNION ALL
    SELECT 'RELATIONSHIPS' as table_name, COUNT(*) as record_count FROM RELATIONSHIPS
);

-- Display loading statistics
SELECT 
    'Data Loading Statistics:' as INFO,
    TABLE_NAME,
    RECORDS_LOADED,
    LOAD_STATUS,
    LOAD_END_TIME
FROM DATA_LOAD_STATS
WHERE LOAD_ID LIKE 'LOAD_%'
ORDER BY LOAD_END_TIME DESC;

-- Final summary
SELECT 
    'RDF Data Loading Demo Completed Successfully!' as COMPLETION_STATUS,
    (SELECT SUM(RECORDS_LOADED) FROM DATA_LOAD_STATS WHERE LOAD_ID LIKE 'LOAD_%') as TOTAL_RECORDS_LOADED,
    CURRENT_TIMESTAMP as COMPLETION_TIME;