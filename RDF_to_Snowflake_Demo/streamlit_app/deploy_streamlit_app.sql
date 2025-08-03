-- Deploy Streamlit App for RDF Semantic Chat Assistant
-- This script creates and deploys the Streamlit app in Snowflake

-- Set the correct Snowflake context
USE ROLE SYSADMIN;
USE WAREHOUSE RDF_DEMO_WH;
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- ================================================================
-- STEP 1: CREATE STAGE FOR STREAMLIT APP FILES
-- ================================================================

SELECT '=== Creating Streamlit App Stage ===' as DEMO_STATUS;

-- Create stage for Streamlit files
CREATE STAGE IF NOT EXISTS STREAMLIT_STAGE
DIRECTORY = (ENABLE = TRUE)
COMMENT = 'Stage for RDF Semantic Chat Assistant Streamlit application files';

-- ================================================================
-- STEP 2: UPLOAD STREAMLIT APP FILES (Instructions)
-- ================================================================

SELECT '=== Instructions for Uploading Streamlit Files ===' as DEMO_STATUS;

-- Note: These PUT commands should be run from SnowSQL or similar client
-- PUT file://./cortex_analyst_chat.py @STREAMLIT_STAGE/;
-- PUT file://./requirements.txt @STREAMLIT_STAGE/;
-- PUT file://./.streamlit/config.toml @STREAMLIT_STAGE/.streamlit/;

SELECT 
    'Upload Commands (run these from SnowSQL):' as INSTRUCTION_TYPE,
    'PUT file://./cortex_analyst_chat.py @STREAMLIT_STAGE/;' as COMMAND_1,
    'PUT file://./requirements.txt @STREAMLIT_STAGE/;' as COMMAND_2,
    'PUT file://./.streamlit/config.toml @STREAMLIT_STAGE/.streamlit/;' as COMMAND_3;

-- ================================================================
-- STEP 3: CREATE STREAMLIT APPLICATION
-- ================================================================

SELECT '=== Creating Streamlit Application ===' as DEMO_STATUS;

-- Drop existing app if it exists
DROP STREAMLIT IF EXISTS RDF_SEMANTIC_CHAT;

-- Create the Streamlit application
CREATE STREAMLIT RDF_SEMANTIC_CHAT
    ROOT_LOCATION = '@STREAMLIT_STAGE'
    MAIN_FILE = 'cortex_analyst_chat.py'
    QUERY_WAREHOUSE = 'RDF_DEMO_WH'
    COMMENT = 'RDF to Snowflake Semantic Views Chat Assistant powered by Cortex Analyst';

-- ================================================================
-- STEP 4: GRANT PERMISSIONS FOR APP ACCESS
-- ================================================================

SELECT '=== Setting Up Permissions ===' as DEMO_STATUS;

-- Grant usage on warehouse to app
GRANT USAGE ON WAREHOUSE RDF_DEMO_WH TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

-- Grant access to database and schema
GRANT USAGE ON DATABASE RDF_SEMANTIC_DB TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;
GRANT USAGE ON SCHEMA RDF_SEMANTIC_DB.SEMANTIC_VIEWS TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

-- Grant select on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA RDF_SEMANTIC_DB.SEMANTIC_VIEWS TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

-- Grant access to semantic views
GRANT SELECT ON ALL SEMANTIC VIEWS IN SCHEMA RDF_SEMANTIC_DB.SEMANTIC_VIEWS TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

-- Grant future permissions
GRANT SELECT ON FUTURE TABLES IN SCHEMA RDF_SEMANTIC_DB.SEMANTIC_VIEWS TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;
GRANT SELECT ON FUTURE SEMANTIC VIEWS IN SCHEMA RDF_SEMANTIC_DB.SEMANTIC_VIEWS TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

-- ================================================================
-- STEP 5: ENABLE CORTEX ANALYST ACCESS (if needed)
-- ================================================================

SELECT '=== Enabling Cortex Analyst Access ===' as DEMO_STATUS;

-- Note: These privileges may need to be granted by ACCOUNTADMIN
-- GRANT USAGE ON SERVICE CORTEX_ANALYST TO ROLE SYSADMIN;
-- GRANT USAGE ON SERVICE CORTEX_ANALYST TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;

SELECT 
    'Cortex Analyst Permissions (run as ACCOUNTADMIN if needed):' as PERMISSION_TYPE,
    'GRANT USAGE ON SERVICE CORTEX_ANALYST TO ROLE SYSADMIN;' as COMMAND_1,
    'GRANT USAGE ON SERVICE CORTEX_ANALYST TO APPLICATION ROLE RDF_SEMANTIC_CHAT_APP_ROLE;' as COMMAND_2;

-- ================================================================
-- STEP 6: VERIFY DEPLOYMENT
-- ================================================================

SELECT '=== Verifying Streamlit App Deployment ===' as DEMO_STATUS;

-- Show the created Streamlit app
SHOW STREAMLIT APPS;

-- Show stage contents
LIST @STREAMLIT_STAGE;

-- Provide access URL
SELECT 
    'Streamlit App Successfully Deployed!' as STATUS,
    'Access your app through the Snowflake UI -> Apps -> Streamlit' as ACCESS_METHOD,
    'App Name: RDF_SEMANTIC_CHAT' as APP_NAME,
    CURRENT_TIMESTAMP() as DEPLOYMENT_TIME;

-- ================================================================
-- STEP 7: APP FEATURES SUMMARY
-- ================================================================

SELECT '=== Streamlit App Features Summary ===' as DEMO_STATUS;

SELECT 
    'Features Available in the App:' as FEATURE_CATEGORY,
    '🤖 Natural Language Chat Interface' as FEATURE_1,
    '📊 Interactive Semantic View Explorer' as FEATURE_2,
    '📈 Auto-Generated Visualizations' as FEATURE_3,
    '🔍 Semantic SQL Query Builder' as FEATURE_4,
    '💬 Pre-built Sample Questions' as FEATURE_5,
    '📋 Real-time Data Analysis' as FEATURE_6;

SELECT 
    'Sample Questions You Can Ask:' as QUESTION_CATEGORY,
    'What is our total revenue?' as QUESTION_1,
    'Show me the top customers by value' as QUESTION_2,
    'Which products are selling best?' as QUESTION_3,
    'What are our high-value orders?' as QUESTION_4,
    'Show me recent sales trends' as QUESTION_5;

-- ================================================================
-- COMPLETION STATUS
-- ================================================================

SELECT 
    '=== RDF Semantic Chat Assistant Deployed Successfully! ===' as COMPLETION_STATUS,
    'The Streamlit app is now ready for natural language querying' as APP_STATUS,
    'Powered by Snowflake Semantic Views and Cortex Analyst' as TECHNOLOGY,
    CURRENT_TIMESTAMP() as COMPLETION_TIME;