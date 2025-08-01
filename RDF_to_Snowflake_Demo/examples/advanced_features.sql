-- Advanced Snowflake Features for RDF Semantic Views
-- This script demonstrates advanced Snowflake capabilities for semantic data processing

USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- PART 1: SEMANTIC VIEW OPTIMIZATION WITH CLUSTERING
-- ================================================================

SELECT '=== Implementing Clustering for Semantic Views ===' as FEATURE_TYPE;

-- Add clustering keys to improve query performance
ALTER TABLE PRODUCT CLUSTER BY (CLASS_URI, PRICE);
ALTER TABLE RELATIONSHIPS CLUSTER BY (RELATIONSHIP_TYPE, SUBJECT_URI);

-- Create materialized view for frequently accessed semantic patterns
CREATE OR REPLACE SECURE MATERIALIZED VIEW MV_PRODUCT_ANALYTICS AS
SELECT 
    p.ID,
    p.URI,
    p.PRODUCTNAME,
    p.PRICE,
    p.STOCKQUANTITY,
    c.CATEGORYNAME,
    s.SUPPLIERNAME,
    CASE 
        WHEN p.PRICE < 50 THEN 'Budget'
        WHEN p.PRICE BETWEEN 50 AND 500 THEN 'Mid-range'
        WHEN p.PRICE > 500 THEN 'Premium'
        ELSE 'Unpriced'
    END as PRICE_SEGMENT,
    CASE 
        WHEN p.STOCKQUANTITY < 10 THEN 'Low Stock'
        WHEN p.STOCKQUANTITY BETWEEN 10 AND 50 THEN 'Medium Stock'
        WHEN p.STOCKQUANTITY > 50 THEN 'High Stock'
        ELSE 'Unknown'
    END as STOCK_LEVEL
FROM PRODUCT p
LEFT JOIN RELATIONSHIPS r1 ON p.URI = r1.SUBJECT_URI AND r1.RELATIONSHIP_TYPE = 'belongsToCategory'
LEFT JOIN CATEGORY c ON r1.OBJECT_URI = c.URI
LEFT JOIN RELATIONSHIPS r2 ON p.URI = r2.SUBJECT_URI AND r2.RELATIONSHIP_TYPE = 'suppliedBy'
LEFT JOIN SUPPLIER s ON r2.OBJECT_URI = s.URI;

-- ================================================================
-- PART 2: SEMANTIC SEARCH WITH VECTOR EMBEDDINGS
-- ================================================================

SELECT '=== Implementing Semantic Search Capabilities ===' as FEATURE_TYPE;

-- Create table for storing semantic embeddings (simulated)
CREATE OR REPLACE TABLE SEMANTIC_EMBEDDINGS (
    ENTITY_URI VARCHAR(1000) NOT NULL,
    ENTITY_TYPE VARCHAR(100) NOT NULL,
    EMBEDDING_VECTOR ARRAY,
    TEXT_REPRESENTATION TEXT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ENTITY_URI)
);

-- Python UDF for generating semantic embeddings (placeholder implementation)
CREATE OR REPLACE FUNCTION generate_semantic_embedding(text_input VARCHAR)
RETURNS ARRAY
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
HANDLER = 'generate_embedding'
AS
$$
import hashlib
import json

def generate_embedding(text_input):
    """
    Generate a simple semantic embedding vector (placeholder implementation)
    In production, you would use a proper embedding model like BERT, Sentence-BERT, etc.
    """
    if not text_input:
        return [0.0] * 384  # Return zero vector for empty input
    
    # Simple hash-based embedding (for demonstration only)
    hash_obj = hashlib.md5(text_input.encode())
    hash_hex = hash_obj.hexdigest()
    
    # Convert hex to normalized float values
    embedding = []
    for i in range(0, min(len(hash_hex), 64), 2):
        hex_pair = hash_hex[i:i+2]
        float_val = int(hex_pair, 16) / 255.0  # Normalize to [0,1]
        embedding.append(float_val)
    
    # Pad to 384 dimensions (common embedding size)
    while len(embedding) < 384:
        embedding.append(0.0)
    
    return embedding[:384]
$$;

-- Generate embeddings for products
INSERT INTO SEMANTIC_EMBEDDINGS (ENTITY_URI, ENTITY_TYPE, EMBEDDING_VECTOR, TEXT_REPRESENTATION)
SELECT 
    URI,
    'Product',
    generate_semantic_embedding(PRODUCTNAME || ' ' || COALESCE(PRODUCTID, '') || ' ' || COALESCE(PRICE::VARCHAR, '')),
    PRODUCTNAME || ' (ID: ' || COALESCE(PRODUCTID, 'N/A') || ', Price: $' || COALESCE(PRICE::VARCHAR, 'N/A') || ')'
FROM PRODUCT;

-- ================================================================
-- PART 3: TEMPORAL SEMANTIC VIEWS
-- ================================================================

SELECT '=== Implementing Temporal Semantic Capabilities ===' as FEATURE_TYPE;

-- Create temporal tracking for semantic changes
CREATE OR REPLACE TABLE SEMANTIC_CHANGE_LOG (
    CHANGE_ID VARCHAR(255) NOT NULL,
    ENTITY_URI VARCHAR(1000) NOT NULL,
    ENTITY_TYPE VARCHAR(100) NOT NULL,
    CHANGE_TYPE VARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE
    OLD_VALUES VARIANT,
    NEW_VALUES VARIANT,
    CHANGE_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    CHANGED_BY VARCHAR(255),
    PRIMARY KEY (CHANGE_ID)
);

-- Create time-travel enabled semantic view
CREATE OR REPLACE VIEW SV_PRODUCT_TEMPORAL AS
SELECT 
    p.*,
    scl.CHANGE_TIMESTAMP as LAST_MODIFIED,
    scl.CHANGE_TYPE as LAST_CHANGE_TYPE
FROM PRODUCT p
LEFT JOIN (
    SELECT 
        ENTITY_URI,
        CHANGE_TIMESTAMP,
        CHANGE_TYPE,
        ROW_NUMBER() OVER (PARTITION BY ENTITY_URI ORDER BY CHANGE_TIMESTAMP DESC) as rn
    FROM SEMANTIC_CHANGE_LOG
    WHERE ENTITY_TYPE = 'Product'
) scl ON p.URI = scl.ENTITY_URI AND scl.rn = 1;

-- ================================================================
-- PART 4: GRAPH ANALYTICS ON SEMANTIC DATA
-- ================================================================

SELECT '=== Implementing Graph Analytics ===' as FEATURE_TYPE;

-- Create recursive CTE for graph traversal
CREATE OR REPLACE VIEW SV_ENTITY_GRAPH AS
WITH RECURSIVE entity_graph AS (
    -- Base case: direct relationships
    SELECT 
        SUBJECT_URI as SOURCE,
        OBJECT_URI as TARGET,
        RELATIONSHIP_TYPE as EDGE_TYPE,
        1 as PATH_LENGTH,
        ARRAY_CONSTRUCT(SUBJECT_URI, OBJECT_URI) as PATH,
        SUBJECT_URI as ROOT_ENTITY
    FROM RELATIONSHIPS
    
    UNION ALL
    
    -- Recursive case: transitive relationships
    SELECT 
        eg.SOURCE,
        r.OBJECT_URI as TARGET,
        r.RELATIONSHIP_TYPE as EDGE_TYPE,
        eg.PATH_LENGTH + 1,
        ARRAY_APPEND(eg.PATH, r.OBJECT_URI) as PATH,
        eg.ROOT_ENTITY
    FROM entity_graph eg
    JOIN RELATIONSHIPS r ON eg.TARGET = r.SUBJECT_URI
    WHERE eg.PATH_LENGTH < 5  -- Limit recursion depth
      AND NOT ARRAY_CONTAINS(r.OBJECT_URI::VARIANT, eg.PATH)  -- Avoid cycles
)
SELECT * FROM entity_graph;

-- Create centrality analysis view
CREATE OR REPLACE VIEW SV_ENTITY_CENTRALITY AS
WITH entity_stats AS (
    SELECT 
        SUBJECT_URI as ENTITY_URI,
        COUNT(DISTINCT OBJECT_URI) as OUT_DEGREE,
        COUNT(DISTINCT RELATIONSHIP_TYPE) as OUT_RELATIONSHIP_TYPES
    FROM RELATIONSHIPS
    GROUP BY SUBJECT_URI
    
    UNION ALL
    
    SELECT 
        OBJECT_URI as ENTITY_URI,
        COUNT(DISTINCT SUBJECT_URI) as IN_DEGREE,
        COUNT(DISTINCT RELATIONSHIP_TYPE) as IN_RELATIONSHIP_TYPES
    FROM RELATIONSHIPS
    GROUP BY OBJECT_URI
),
centrality_metrics AS (
    SELECT 
        ENTITY_URI,
        SUM(COALESCE(OUT_DEGREE, 0)) as TOTAL_OUT_DEGREE,
        SUM(COALESCE(IN_DEGREE, 0)) as TOTAL_IN_DEGREE,
        MAX(COALESCE(OUT_RELATIONSHIP_TYPES, 0)) as OUT_RELATIONSHIP_DIVERSITY,
        MAX(COALESCE(IN_RELATIONSHIP_TYPES, 0)) as IN_RELATIONSHIP_DIVERSITY
    FROM entity_stats
    GROUP BY ENTITY_URI
)
SELECT 
    ENTITY_URI,
    TOTAL_OUT_DEGREE,
    TOTAL_IN_DEGREE,
    (TOTAL_OUT_DEGREE + TOTAL_IN_DEGREE) as TOTAL_DEGREE,
    OUT_RELATIONSHIP_DIVERSITY,
    IN_RELATIONSHIP_DIVERSITY,
    CASE 
        WHEN (TOTAL_OUT_DEGREE + TOTAL_IN_DEGREE) > 5 THEN 'Hub'
        WHEN (TOTAL_OUT_DEGREE + TOTAL_IN_DEGREE) BETWEEN 2 AND 5 THEN 'Connector'
        WHEN (TOTAL_OUT_DEGREE + TOTAL_IN_DEGREE) = 1 THEN 'Leaf'
        ELSE 'Isolated'
    END as CENTRALITY_CLASS
FROM centrality_metrics
ORDER BY TOTAL_DEGREE DESC;

-- ================================================================
-- PART 5: SEMANTIC DATA QUALITY MONITORING
-- ================================================================

SELECT '=== Implementing Data Quality Monitoring ===' as FEATURE_TYPE;

-- Create data quality rules table
CREATE OR REPLACE TABLE SEMANTIC_QUALITY_RULES (
    RULE_ID VARCHAR(255) NOT NULL,
    RULE_NAME VARCHAR(255) NOT NULL,
    ENTITY_TYPE VARCHAR(100) NOT NULL,
    RULE_QUERY TEXT NOT NULL,
    EXPECTED_RESULT VARCHAR(100),
    SEVERITY VARCHAR(20) DEFAULT 'WARNING',
    ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (RULE_ID)
);

-- Insert sample quality rules
INSERT INTO SEMANTIC_QUALITY_RULES (RULE_ID, RULE_NAME, ENTITY_TYPE, RULE_QUERY, EXPECTED_RESULT, SEVERITY)
VALUES 
    ('QR001', 'Products must have names', 'Product', 
     'SELECT COUNT(*) FROM PRODUCT WHERE PRODUCTNAME IS NULL OR PRODUCTNAME = ''''', 
     '0', 'ERROR'),
    ('QR002', 'Products must have positive prices', 'Product',
     'SELECT COUNT(*) FROM PRODUCT WHERE PRICE IS NULL OR PRICE <= 0',
     '0', 'WARNING'),
    ('QR003', 'Orders must have customers', 'Order',
     'SELECT COUNT(*) FROM ORDER_ o WHERE NOT EXISTS (SELECT 1 FROM RELATIONSHIPS r WHERE r.SUBJECT_URI = o.URI AND r.RELATIONSHIP_TYPE = ''placedBy'')',
     '0', 'ERROR'),
    ('QR004', 'Orphaned relationships check', 'Relationship',
     'SELECT COUNT(*) FROM RELATIONSHIPS r WHERE NOT EXISTS (SELECT 1 FROM PRODUCT p WHERE p.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM CATEGORY c WHERE c.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM CUSTOMER cu WHERE cu.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM ORDER_ o WHERE o.URI = r.SUBJECT_URI)',
     '0', 'WARNING');

-- Create quality monitoring view
CREATE OR REPLACE VIEW SV_DATA_QUALITY_DASHBOARD AS
WITH quality_checks AS (
    SELECT 
        RULE_ID,
        RULE_NAME,
        ENTITY_TYPE,
        SEVERITY,
        CASE RULE_ID
            WHEN 'QR001' THEN (SELECT COUNT(*) FROM PRODUCT WHERE PRODUCTNAME IS NULL OR PRODUCTNAME = '')::VARCHAR
            WHEN 'QR002' THEN (SELECT COUNT(*) FROM PRODUCT WHERE PRICE IS NULL OR PRICE <= 0)::VARCHAR
            WHEN 'QR003' THEN (SELECT COUNT(*) FROM ORDER_ o WHERE NOT EXISTS (SELECT 1 FROM RELATIONSHIPS r WHERE r.SUBJECT_URI = o.URI AND r.RELATIONSHIP_TYPE = 'placedBy'))::VARCHAR
            WHEN 'QR004' THEN (SELECT COUNT(*) FROM RELATIONSHIPS r WHERE NOT EXISTS (SELECT 1 FROM PRODUCT p WHERE p.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM CATEGORY c WHERE c.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM CUSTOMER cu WHERE cu.URI = r.SUBJECT_URI) AND NOT EXISTS (SELECT 1 FROM ORDER_ o WHERE o.URI = r.SUBJECT_URI))::VARCHAR
            ELSE 'N/A'
        END as ACTUAL_RESULT,
        EXPECTED_RESULT
    FROM SEMANTIC_QUALITY_RULES
    WHERE ACTIVE = TRUE
)
SELECT 
    *,
    CASE WHEN ACTUAL_RESULT = EXPECTED_RESULT THEN 'PASS' ELSE 'FAIL' END as STATUS,
    CURRENT_TIMESTAMP as CHECK_TIMESTAMP
FROM quality_checks;

-- ================================================================
-- PART 6: SEMANTIC QUERY OPTIMIZATION
-- ================================================================

SELECT '=== Demonstrating Query Optimization Techniques ===' as FEATURE_TYPE;

-- Create optimized view with pre-computed joins
CREATE OR REPLACE VIEW SV_OPTIMIZED_PRODUCT_CATALOG AS
SELECT 
    p.ID,
    p.URI,
    p.PRODUCTID,
    p.PRODUCTNAME,
    p.PRICE,
    p.STOCKQUANTITY,
    c.CATEGORYNAME,
    s.SUPPLIERNAME,
    -- Pre-computed derived fields
    CASE 
        WHEN p.PRICE < 50 THEN 'Budget'
        WHEN p.PRICE BETWEEN 50 AND 500 THEN 'Mid-range'
        WHEN p.PRICE > 500 THEN 'Premium'
        ELSE 'Unpriced'
    END as PRICE_TIER,
    
    CASE 
        WHEN p.STOCKQUANTITY = 0 THEN 'Out of Stock'
        WHEN p.STOCKQUANTITY < 10 THEN 'Low Stock'
        WHEN p.STOCKQUANTITY < 50 THEN 'Medium Stock'
        ELSE 'In Stock'
    END as AVAILABILITY_STATUS,
    
    -- Semantic enrichment
    UPPER(SUBSTRING(p.PRODUCTNAME, 1, 1)) || LOWER(SUBSTRING(p.PRODUCTNAME, 2)) as FORMATTED_NAME,
    p.PRICE * 1.1 as PRICE_WITH_TAX,
    
    -- Metadata
    p.CREATED_AT,
    p.UPDATED_AT
FROM PRODUCT p
LEFT JOIN RELATIONSHIPS r1 ON p.URI = r1.SUBJECT_URI AND r1.RELATIONSHIP_TYPE = 'belongsToCategory'
LEFT JOIN CATEGORY c ON r1.OBJECT_URI = c.URI
LEFT JOIN RELATIONSHIPS r2 ON p.URI = r2.SUBJECT_URI AND r2.RELATIONSHIP_TYPE = 'suppliedBy'
LEFT JOIN SUPPLIER s ON r2.OBJECT_URI = s.URI;

-- ================================================================
-- PART 7: SEMANTIC ANALYTICS FUNCTIONS
-- ================================================================

SELECT '=== Creating Advanced Analytics Functions ===' as FEATURE_TYPE;

-- Function to calculate semantic similarity between entities
CREATE OR REPLACE FUNCTION calculate_semantic_similarity(entity1_uri VARCHAR, entity2_uri VARCHAR)
RETURNS FLOAT
LANGUAGE SQL
AS
$$
    WITH entity1_relationships AS (
        SELECT DISTINCT RELATIONSHIP_TYPE, OBJECT_URI 
        FROM RELATIONSHIPS 
        WHERE SUBJECT_URI = entity1_uri
    ),
    entity2_relationships AS (
        SELECT DISTINCT RELATIONSHIP_TYPE, OBJECT_URI 
        FROM RELATIONSHIPS 
        WHERE SUBJECT_URI = entity2_uri
    ),
    common_relationships AS (
        SELECT COUNT(*) as common_count
        FROM entity1_relationships e1
        INNER JOIN entity2_relationships e2 
        ON e1.RELATIONSHIP_TYPE = e2.RELATIONSHIP_TYPE 
        AND e1.OBJECT_URI = e2.OBJECT_URI
    ),
    total_relationships AS (
        SELECT COUNT(*) as total_count
        FROM (
            SELECT RELATIONSHIP_TYPE, OBJECT_URI FROM entity1_relationships
            UNION
            SELECT RELATIONSHIP_TYPE, OBJECT_URI FROM entity2_relationships
        ) all_rels
    )
    SELECT 
        CASE 
            WHEN total_count = 0 THEN 0.0
            ELSE common_count::FLOAT / total_count::FLOAT
        END
    FROM common_relationships, total_relationships
$$;

-- Function to find semantic neighbors
CREATE OR REPLACE FUNCTION find_semantic_neighbors(entity_uri VARCHAR, similarity_threshold FLOAT DEFAULT 0.1)
RETURNS TABLE (NEIGHBOR_URI VARCHAR, SIMILARITY_SCORE FLOAT)
LANGUAGE SQL
AS
$$
    WITH candidate_entities AS (
        SELECT DISTINCT SUBJECT_URI as CANDIDATE_URI
        FROM RELATIONSHIPS
        WHERE SUBJECT_URI != entity_uri
    ),
    similarities AS (
        SELECT 
            CANDIDATE_URI,
            calculate_semantic_similarity(entity_uri, CANDIDATE_URI) as SIMILARITY
        FROM candidate_entities
        WHERE calculate_semantic_similarity(entity_uri, CANDIDATE_URI) >= similarity_threshold
    )
    SELECT CANDIDATE_URI, SIMILARITY
    FROM similarities
    ORDER BY SIMILARITY DESC
    LIMIT 10
$$;

-- ================================================================
-- PART 8: DEMONSTRATION OF ADVANCED FEATURES
-- ================================================================

SELECT '=== Demonstrating Advanced Features ===' as DEMO_SECTION;

-- Test materialized view performance
SELECT 'Materialized View Performance Test:' as TEST_TYPE,
       COUNT(*) as TOTAL_PRODUCTS,
       COUNT(DISTINCT PRICE_SEGMENT) as PRICE_SEGMENTS,
       COUNT(DISTINCT STOCK_LEVEL) as STOCK_LEVELS
FROM MV_PRODUCT_ANALYTICS;

-- Test graph analytics
SELECT 'Graph Centrality Analysis:' as TEST_TYPE,
       CENTRALITY_CLASS,
       COUNT(*) as ENTITY_COUNT,
       AVG(TOTAL_DEGREE) as AVG_DEGREE
FROM SV_ENTITY_CENTRALITY
GROUP BY CENTRALITY_CLASS
ORDER BY AVG_DEGREE DESC;

-- Test data quality monitoring
SELECT 'Data Quality Dashboard:' as TEST_TYPE,
       ENTITY_TYPE,
       SUM(CASE WHEN STATUS = 'PASS' THEN 1 ELSE 0 END) as PASSED_RULES,
       SUM(CASE WHEN STATUS = 'FAIL' THEN 1 ELSE 0 END) as FAILED_RULES
FROM SV_DATA_QUALITY_DASHBOARD
GROUP BY ENTITY_TYPE;

-- Test semantic similarity
SELECT 'Semantic Similarity Test:' as TEST_TYPE,
       'product1' as ENTITY1,
       'product3' as ENTITY2,
       calculate_semantic_similarity(
           'http://example.com/instances#product1',
           'http://example.com/instances#product3'
       ) as SIMILARITY_SCORE;

-- Test optimized catalog view
SELECT 'Optimized Catalog Performance:' as TEST_TYPE,
       PRICE_TIER,
       AVAILABILITY_STATUS,
       COUNT(*) as PRODUCT_COUNT,
       AVG(PRICE_WITH_TAX) as AVG_PRICE_WITH_TAX
FROM SV_OPTIMIZED_PRODUCT_CATALOG
GROUP BY PRICE_TIER, AVAILABILITY_STATUS
ORDER BY PRICE_TIER, AVAILABILITY_STATUS;

-- Final summary
SELECT 
    '=== Advanced Features Demo Completed ===' as COMPLETION_STATUS,
    'Clustering, Materialized Views, Graph Analytics, Quality Monitoring, and Semantic Functions demonstrated' as FEATURES_SHOWN,
    CURRENT_TIMESTAMP as COMPLETION_TIME;