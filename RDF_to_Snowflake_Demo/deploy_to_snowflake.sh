#!/bin/bash

# RDF to Snowflake Semantic Views Demo - Deployment Script
# This script deploys the complete demo to your Snowflake account

echo "=== RDF to Snowflake Demo Deployment Script ==="
echo "This script will deploy the demo to your Snowflake account"
echo

# Configuration variables - Set via environment variables or update these
SNOWFLAKE_ACCOUNT="${SNOWSQL_ACCOUNT:-your-account-identifier}"  # e.g., abc12345.us-east-1
SNOWFLAKE_USER="${SNOWSQL_USER:-your-username}"                  # Your Snowflake username
SNOWFLAKE_DATABASE="${SNOWSQL_DATABASE:-RDF_SEMANTIC_DB}"        # Database to create/use
SNOWFLAKE_SCHEMA="${SNOWSQL_SCHEMA:-SEMANTIC_VIEWS}"             # Schema to create/use
SNOWFLAKE_WAREHOUSE="${SNOWSQL_WAREHOUSE:-RDF_DEMO_WH}"          # Warehouse to create/use

# Color coding for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Configuration:${NC}"
echo "  Account: $SNOWFLAKE_ACCOUNT"
echo "  User: $SNOWFLAKE_USER"
echo "  Database: $SNOWFLAKE_DATABASE"
echo "  Schema: $SNOWFLAKE_SCHEMA"
echo "  Warehouse: $SNOWFLAKE_WAREHOUSE"
echo

# Function to execute SQL file
execute_sql_file() {
    local file=$1
    local description=$2
    
    echo -e "${BLUE}Executing: $description${NC}"
    echo "File: $file"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File $file not found${NC}"
        return 1
    fi
    
    snowsql -a "$SNOWFLAKE_ACCOUNT" -u "$SNOWFLAKE_USER" -f "$file" --variable database="$SNOWFLAKE_DATABASE" --variable schema="$SNOWFLAKE_SCHEMA" --variable warehouse="$SNOWFLAKE_WAREHOUSE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully executed: $description${NC}"
        echo
    else
        echo -e "${RED}✗ Failed to execute: $description${NC}"
        echo "Please check the error message above and fix any issues."
        read -p "Do you want to continue with the deployment? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Deployment aborted."
            exit 1
        fi
    fi
}

# Check if SnowSQL is available
if ! command -v snowsql &> /dev/null; then
    echo -e "${RED}Error: SnowSQL is not installed or not in PATH${NC}"
    echo "Please install SnowSQL from: https://docs.snowflake.com/en/user-guide/snowsql-install-config.html"
    exit 1
fi

# Verify configuration
echo -e "${YELLOW}Please verify your configuration above is correct.${NC}"
read -p "Do you want to proceed with the deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled. Please update the configuration variables at the top of this script."
    exit 1
fi

echo -e "${GREEN}Starting deployment...${NC}"
echo

# Step 0: Enable MFA Token Caching (reduces authentication prompts)
echo -e "${BLUE}=== STEP 0: Enabling MFA Token Caching ===${NC}"
echo "This step will enable MFA token caching to reduce authentication prompts during deployment."
execute_sql_file "setup_mfa_caching.sql" "MFA Token Caching Setup"

# Step 1: Create Python UDFs
echo -e "${BLUE}=== STEP 1: Creating Python UDFs ===${NC}"
execute_sql_file "python_udfs/rdf_parser_udf.sql" "RDF Parser UDF"
execute_sql_file "python_udfs/semantic_view_generator_udf.sql" "Semantic View Generator UDF"
execute_sql_file "python_udfs/rdf_data_loader_udf.sql" "RDF Data Loader UDF"

# Step 2: Set up environment
echo -e "${BLUE}=== STEP 2: Setting up Environment ===${NC}"
execute_sql_file "sql/01_setup_environment.sql" "Environment Setup"

# Step 3: Run the complete demo
echo -e "${BLUE}=== STEP 3: Running Complete Demo ===${NC}"
execute_sql_file "run_complete_demo.sql" "Complete Demo Execution"

# Step 4: Load advanced features (optional)
echo -e "${BLUE}=== STEP 4: Setting up Advanced Features ===${NC}"
read -p "Do you want to install advanced features (graph analytics, quality monitoring, etc.)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    execute_sql_file "examples/advanced_features.sql" "Advanced Features Setup"
else
    echo "Skipping advanced features installation."
fi

echo
echo -e "${GREEN}=== DEPLOYMENT COMPLETED SUCCESSFULLY! ===${NC}"
echo
echo -e "${BLUE}What's been created in your account:${NC}"
echo "  • Database: $SNOWFLAKE_DATABASE"
echo "  • Schema: $SNOWFLAKE_SCHEMA"
echo "  • Warehouse: $SNOWFLAKE_WAREHOUSE"
echo "  • MFA token caching enabled (reduced authentication prompts)"
echo "  • Python UDFs for RDF processing"
echo "  • Semantic views (SV_*)"
echo "  • Sample data and relationships"
echo "  • Analytics and monitoring tables"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Connect to Snowflake and use database: $SNOWFLAKE_DATABASE"
echo "  2. Explore the semantic views: SHOW VIEWS LIKE 'SV_%'"
echo "  3. Try the sample queries in examples/semantic_queries.sql"
echo "  4. Load your own RDF data using the provided UDFs"
echo
echo -e "${BLUE}Access your demo:${NC}"
echo "  • Snowflake UI: https://app.snowflake.com"
echo "  • Use database: $SNOWFLAKE_DATABASE"
echo "  • Use schema: $SNOWFLAKE_SCHEMA"
echo
echo -e "${GREEN}Demo deployment completed! 🚀${NC}"