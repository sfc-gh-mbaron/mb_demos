-- Main conversion demo script
-- This script demonstrates the complete RDF to Snowflake semantic views conversion process

USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- Step 1: Load sample RDF schema
-- In a real scenario, you would load this from a file or external source
INSERT INTO RDF_SCHEMAS (SCHEMA_ID, SCHEMA_NAME, RDF_FORMAT, RDF_CONTENT, DESCRIPTION)
SELECT 
    GENERATE_ID('SCHEMA'),
    'E-commerce Domain Model',
    'turtle',
    '# E-commerce RDF Schema in Turtle format
@prefix ex: <http://example.com/ecommerce#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Domain Classes
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

# Data Properties
ex:productName rdf:type rdf:Property ;
    rdfs:label "Product Name" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:string .

ex:price rdf:type rdf:Property ;
    rdfs:label "Price" ;
    rdfs:domain ex:Product ;
    rdfs:range xsd:decimal .

ex:customerName rdf:type rdf:Property ;
    rdfs:label "Customer Name" ;
    rdfs:domain ex:Customer ;
    rdfs:range xsd:string .

ex:orderDate rdf:type rdf:Property ;
    rdfs:label "Order Date" ;
    rdfs:domain ex:Order ;
    rdfs:range xsd:dateTime .

# Object Properties
ex:belongsToCategory rdf:type rdf:Property ;
    rdfs:label "belongs to category" ;
    rdfs:domain ex:Product ;
    rdfs:range ex:Category .

ex:placedBy rdf:type rdf:Property ;
    rdfs:label "placed by" ;
    rdfs:domain ex:Order ;
    rdfs:range ex:Customer .',
    'Sample e-commerce RDF schema for demonstration';

-- Step 2: Parse the RDF schema
SET schema_id = (SELECT SCHEMA_ID FROM RDF_SCHEMAS WHERE SCHEMA_NAME = 'E-commerce Domain Model' LIMIT 1);

-- Parse the schema and store results
INSERT INTO CONVERSION_RESULTS (CONVERSION_ID, SCHEMA_ID, CONVERSION_TYPE, RESULT_DATA)
SELECT 
    GENERATE_ID('PARSE'),
    $schema_id,
    'SCHEMA_PARSE',
    PARSE_RDF_SCHEMA(RDF_CONTENT, RDF_FORMAT)
FROM RDF_SCHEMAS 
WHERE SCHEMA_ID = $schema_id;

-- Check parsing results
SELECT 
    CONVERSION_ID,
    STATUS,
    RESULT_DATA:classes as CLASSES,
    RESULT_DATA:properties as PROPERTIES,
    RESULT_DATA:statistics as STATISTICS
FROM CONVERSION_RESULTS 
WHERE SCHEMA_ID = $schema_id AND CONVERSION_TYPE = 'SCHEMA_PARSE';

-- Step 3: Generate semantic view DDL
INSERT INTO CONVERSION_RESULTS (CONVERSION_ID, SCHEMA_ID, CONVERSION_TYPE, RESULT_DATA)
SELECT 
    GENERATE_ID('DDL'),
    $schema_id,
    'DDL_GENERATION',
    GENERATE_SEMANTIC_VIEW_DDL(RESULT_DATA, 'RDF_SEMANTIC_DB', 'SEMANTIC_VIEWS', 'SV_ECOMMERCE_MASTER')
FROM CONVERSION_RESULTS 
WHERE SCHEMA_ID = $schema_id AND CONVERSION_TYPE = 'SCHEMA_PARSE';

-- Step 4: Execute the generated DDL (in a real scenario, you would extract and execute these statements)
-- For demonstration, let's show the generated DDL
SELECT 
    'Generated DDL Statements:' as INFO,
    RESULT_DATA:ddl_statements as DDL_STATEMENTS,
    RESULT_DATA:semantic_views as SEMANTIC_VIEWS,
    RESULT_DATA:metadata as METADATA
FROM CONVERSION_RESULTS 
WHERE SCHEMA_ID = $schema_id AND CONVERSION_TYPE = 'DDL_GENERATION';

-- Step 5: Manually create the base tables based on the schema (for demo purposes)
-- In practice, you would execute the generated DDL statements

CREATE OR REPLACE TABLE PRODUCT (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    PRODUCTNAME VARCHAR(16777216),
    PRICE NUMBER(38,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE CATEGORY (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    CATEGORYNAME VARCHAR(255),
    DESCRIPTION VARCHAR(1000),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE CUSTOMER (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    CUSTOMERNAME VARCHAR(16777216),
    EMAIL VARCHAR(255),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);

CREATE OR REPLACE TABLE ORDER_ (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    ORDERDATE TIMESTAMP_NTZ,
    CUSTOMERID VARCHAR(255),
    TOTAL_AMOUNT NUMBER(10,2),
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

-- Create supplier table
CREATE OR REPLACE TABLE SUPPLIER (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    SUPPLIERNAME VARCHAR(255),
    CONTACT_INFO VARCHAR(1000),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ID)
);

-- Create order item table
CREATE OR REPLACE TABLE ORDERITEM (
    ID VARCHAR(255) NOT NULL,
    URI VARCHAR(1000) NOT NULL,
    CLASS_URI VARCHAR(1000) NOT NULL,
    ORDERID VARCHAR(255),
    PRODUCTID VARCHAR(255),
    QUANTITY NUMBER(10,0),
    UNIT_PRICE NUMBER(10,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ID)
);

-- Step 6: Create semantic views
CREATE OR REPLACE VIEW SV_PRODUCT 
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Product'
AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    PRODUCTNAME, -- Product Name
    PRICE, -- Price
    CREATED_AT,
    UPDATED_AT
FROM PRODUCT;

CREATE OR REPLACE VIEW SV_CUSTOMER 
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Customer'
AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    CUSTOMERNAME, -- Customer Name
    CREATED_AT,
    UPDATED_AT
FROM CUSTOMER;

CREATE OR REPLACE VIEW SV_ORDER 
COMMENT = 'Semantic view for RDF class: http://example.com/ecommerce#Order'
AS
SELECT 
    ID,
    URI,
    CLASS_URI,
    ORDERDATE, -- Order Date
    CREATED_AT,
    UPDATED_AT
FROM ORDER_;

CREATE OR REPLACE VIEW SV_RELATIONSHIPS 
COMMENT = 'Semantic view for RDF object properties and relationships'
AS
SELECT 
    ID,
    SUBJECT_URI,
    PREDICATE_URI,
    OBJECT_URI,
    RELATIONSHIP_TYPE,
    CREATED_AT
FROM RELATIONSHIPS;

-- Step 7: Load sample instance data
INSERT INTO RDF_SCHEMAS (SCHEMA_ID, SCHEMA_NAME, RDF_FORMAT, RDF_CONTENT, DESCRIPTION)
SELECT 
    GENERATE_ID('DATA'),
    'E-commerce Sample Data',
    'turtle',
    '# Sample E-commerce Data Instances
@prefix ex: <http://example.com/ecommerce#> .
@prefix inst: <http://example.com/instances#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Product instances
inst:product1 a ex:Product ;
    ex:productName "UltraBook Pro 15" ;
    ex:price "1299.99"^^xsd:decimal .

inst:product2 a ex:Product ;
    ex:productName "Wireless Mouse" ;
    ex:price "29.99"^^xsd:decimal .

# Category instances  
inst:electronics a ex:Category .
inst:computers a ex:Category .

# Customer instances
inst:customer1 a ex:Customer ;
    ex:customerName "John Smith" .

# Order instances
inst:order1 a ex:Order ;
    ex:orderDate "2024-01-15T10:30:00"^^xsd:dateTime ;
    ex:placedBy inst:customer1 .

# Relationships
inst:product1 ex:belongsToCategory inst:computers .
inst:product2 ex:belongsToCategory inst:electronics .',
    'Sample e-commerce instance data for demonstration';

-- Step 8: Demonstrate conversion summary
SELECT 
    '=== RDF to Snowflake Conversion Demo Summary ===' as DEMO_SUMMARY;

SELECT 
    'Schema Information:' as INFO,
    SCHEMA_NAME,
    RDF_FORMAT,
    UPLOADED_AT,
    DESCRIPTION
FROM RDF_SCHEMAS
WHERE SCHEMA_NAME LIKE '%E-commerce%';

SELECT 
    'Conversion Results:' as INFO,
    CONVERSION_TYPE,
    STATUS,
    CREATED_AT
FROM CONVERSION_RESULTS cr
JOIN RDF_SCHEMAS rs ON cr.SCHEMA_ID = rs.SCHEMA_ID
WHERE rs.SCHEMA_NAME = 'E-commerce Domain Model'
ORDER BY cr.CREATED_AT;

-- Step 9: Verify semantic views are created
SELECT 
    'Created Semantic Views:' as INFO;

SHOW VIEWS LIKE 'SV_%';

-- Step 10: Display final success message
SELECT 
    'RDF to Snowflake Semantic Views conversion demo completed successfully!' as COMPLETION_STATUS,
    CURRENT_TIMESTAMP() as COMPLETION_TIME;