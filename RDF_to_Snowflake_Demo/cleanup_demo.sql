-- Cleanup script for RDF to Snowflake Semantic Views Demo
-- This script removes all demo objects and data

-- ================================================================
-- CLEANUP WARNING AND CONFIRMATION
-- ================================================================

SELECT '=== RDF to Snowflake Demo Cleanup Script ===' as WARNING_MESSAGE;
SELECT 'This script will remove ALL demo objects and data!' as WARNING_MESSAGE;
SELECT 'Make sure you want to proceed before executing.' as WARNING_MESSAGE;

-- Set the database and schema context
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- STEP 1: DROP VIEWS (in dependency order)
-- ================================================================

SELECT '=== Dropping Semantic Views ===' as CLEANUP_STEP;

-- Drop semantic views first
DROP VIEW IF EXISTS SV_MASTER_SEMANTIC_MODEL;
DROP VIEW IF EXISTS SV_CLASS_HIERARCHY;
DROP VIEW IF EXISTS SV_ENTITY_GRAPH;
DROP VIEW IF EXISTS SV_ENTITY_CENTRALITY;
DROP VIEW IF EXISTS SV_DATA_QUALITY_DASHBOARD;
DROP VIEW IF EXISTS SV_PRODUCT_TEMPORAL;
DROP VIEW IF EXISTS SV_OPTIMIZED_PRODUCT_CATALOG;

-- Drop materialized views
DROP MATERIALIZED VIEW IF EXISTS MV_PRODUCT_ANALYTICS;

-- Drop core semantic views
DROP VIEW IF EXISTS SV_RELATIONSHIPS;
DROP VIEW IF EXISTS SV_SUPPLIER;
DROP VIEW IF EXISTS SV_ORDERITEM;
DROP VIEW IF EXISTS SV_ORDER;
DROP VIEW IF EXISTS SV_CUSTOMER;
DROP VIEW IF EXISTS SV_CATEGORY;
DROP VIEW IF EXISTS SV_PRODUCT;

-- Drop utility views
DROP VIEW IF EXISTS VW_CONVERSION_SUMMARY;
DROP VIEW IF EXISTS VW_SEMANTIC_MODEL_OVERVIEW;

SELECT 'Semantic views dropped successfully' as STATUS;

-- ================================================================
-- STEP 2: DROP FUNCTIONS AND UDFS
-- ================================================================

SELECT '=== Dropping Functions and UDFs ===' as CLEANUP_STEP;

-- Drop semantic analysis functions
DROP FUNCTION IF EXISTS find_semantic_neighbors(VARCHAR, FLOAT);
DROP FUNCTION IF EXISTS calculate_semantic_similarity(VARCHAR, VARCHAR);

-- Drop utility functions
DROP FUNCTION IF EXISTS GENERATE_ID(VARCHAR);

-- Drop RDF processing UDFs
DROP FUNCTION IF EXISTS LOAD_RDF_DATA(STRING, STRING, STRING, STRING);
DROP FUNCTION IF EXISTS GENERATE_SEMANTIC_VIEW_DDL(VARIANT, STRING, STRING);
DROP FUNCTION IF EXISTS PARSE_RDF_SCHEMA(STRING, STRING);

-- Drop embedding function
DROP FUNCTION IF EXISTS generate_semantic_embedding(VARCHAR);

SELECT 'Functions and UDFs dropped successfully' as STATUS;

-- ================================================================
-- STEP 3: DROP TABLES (in dependency order)
-- ================================================================

SELECT '=== Dropping Tables ===' as CLEANUP_STEP;

-- Drop tracking and metadata tables first
DROP TABLE IF EXISTS DATA_LOAD_STATS;
DROP TABLE IF EXISTS SEMANTIC_VIEW_METADATA;
DROP TABLE IF EXISTS CONVERSION_RESULTS;
DROP TABLE IF EXISTS SEMANTIC_CHANGE_LOG;
DROP TABLE IF EXISTS SEMANTIC_QUALITY_RULES;
DROP TABLE IF EXISTS SEMANTIC_EMBEDDINGS;

-- Drop relationship table
DROP TABLE IF EXISTS RELATIONSHIPS;

-- Drop entity tables
DROP TABLE IF EXISTS ORDERITEM;
DROP TABLE IF EXISTS ORDER_;
DROP TABLE IF EXISTS CUSTOMER;
DROP TABLE IF EXISTS SUPPLIER;
DROP TABLE IF EXISTS PRODUCT;
DROP TABLE IF EXISTS CATEGORY;

-- Drop schema storage table
DROP TABLE IF EXISTS RDF_SCHEMAS;

SELECT 'Tables dropped successfully' as STATUS;

-- ================================================================
-- STEP 4: VERIFICATION
-- ================================================================

SELECT '=== Verifying Cleanup ===' as CLEANUP_STEP;

-- Check remaining objects in the schema
SELECT 'Remaining Tables:' as OBJECT_TYPE, COUNT(*) as COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'
  AND TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT 'Remaining Views:', COUNT(*)
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'

UNION ALL

SELECT 'Remaining Functions:', COUNT(*)
FROM INFORMATION_SCHEMA.FUNCTIONS
WHERE FUNCTION_SCHEMA = 'SEMANTIC_VIEWS'

UNION ALL

SELECT 'Remaining Procedures:', COUNT(*)
FROM INFORMATION_SCHEMA.PROCEDURES
WHERE PROCEDURE_SCHEMA = 'SEMANTIC_VIEWS';

-- List any remaining objects
SELECT 'Remaining Objects Check:' as INFO;

-- Show remaining tables
SELECT 'Remaining Tables:' as OBJECT_TYPE, TABLE_NAME as OBJECT_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'
  AND TABLE_TYPE = 'BASE TABLE'

UNION ALL

-- Show remaining views
SELECT 'Remaining Views:', VIEW_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS'

UNION ALL

-- Show remaining functions
SELECT 'Remaining Functions:', FUNCTION_NAME
FROM INFORMATION_SCHEMA.FUNCTIONS
WHERE FUNCTION_SCHEMA = 'SEMANTIC_VIEWS';

-- ================================================================
-- STEP 5: OPTIONAL SCHEMA AND DATABASE CLEANUP
-- ================================================================

SELECT '=== Optional Schema and Database Cleanup ===' as CLEANUP_STEP;

-- Note: Uncomment the following lines if you want to remove the entire schema and database
-- WARNING: This will remove everything, including any other objects you may have created

/*
-- Drop the schema (this will remove any remaining objects)
DROP SCHEMA IF EXISTS SEMANTIC_VIEWS;

-- Drop the database (this will remove the entire database)
DROP DATABASE IF EXISTS RDF_SEMANTIC_DB;
*/

SELECT 'Schema and database cleanup commands are commented out for safety' as SAFETY_NOTE;
SELECT 'Uncomment the DROP SCHEMA and DROP DATABASE commands if you want complete removal' as INSTRUCTIONS;

-- ================================================================
-- STEP 6: CLEANUP COMPLETION
-- ================================================================

SELECT '=== Cleanup Summary ===' as COMPLETION_STATUS;

-- Provide cleanup summary
SELECT 
    'RDF to Snowflake Demo cleanup completed' as CLEANUP_STATUS,
    CURRENT_DATABASE() as CURRENT_DATABASE_NAME,
    CURRENT_SCHEMA() as CURRENT_SCHEMA_NAME,
    CURRENT_TIMESTAMP() as CLEANUP_TIME;

-- Recommendations for next steps
SELECT '=== Post-Cleanup Recommendations ===' as RECOMMENDATIONS;

SELECT 'If you want to run the demo again:' as STEP_1;
SELECT '1. Execute @RDF_to_Snowflake_Demo/run_complete_demo.sql' as INSTRUCTION_1;

SELECT 'If you want to start with a clean environment:' as STEP_2; 
SELECT '2. Uncomment and run the DROP SCHEMA/DATABASE commands above' as INSTRUCTION_2;

SELECT 'If you encountered any issues:' as STEP_3;
SELECT '3. Check for dependencies or permissions that may prevent cleanup' as INSTRUCTION_3;

-- Final verification message
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS') = 0
         AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'SEMANTIC_VIEWS') = 0
         AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.FUNCTIONS WHERE FUNCTION_SCHEMA = 'SEMANTIC_VIEWS') = 0
        THEN 'SUCCESS: All demo objects have been cleaned up!'
        ELSE 'WARNING: Some objects may still remain. Check the verification results above.'
    END as FINAL_STATUS;

-- Display current context
SELECT 
    'Current context after cleanup:' as INFO,
    CURRENT_DATABASE() as DATABASE_,
    CURRENT_SCHEMA() as SCHEMA_,
    CURRENT_USER() as USER_,
    CURRENT_ROLE() as ROLE_;