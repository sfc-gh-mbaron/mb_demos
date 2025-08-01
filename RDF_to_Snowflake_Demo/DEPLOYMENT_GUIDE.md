# RDF to Snowflake Demo - Deployment Guide

This guide helps you deploy the RDF to Snowflake Semantic Views demo to your Snowflake account.

## 🚀 Quick Deployment Options

### Option 1: Automated Script (Recommended)
Use the automated deployment script for a one-click setup.

### Option 2: Manual Snowsight Deployment  
Copy and paste SQL commands directly in the Snowflake web interface.

### Option 3: SnowSQL Command Line
Execute scripts individually using SnowSQL.

---

## 📋 Prerequisites

- **Snowflake Account** with appropriate privileges
- **Warehouse** with ability to create databases/schemas
- **Python UDF Support** enabled (most accounts have this)

### Required Privileges
```sql
-- Your user needs these privileges:
GRANT CREATE DATABASE ON ACCOUNT TO USER your_username;
GRANT CREATE WAREHOUSE ON ACCOUNT TO USER your_username;
GRANT USAGE ON WAREHOUSE your_warehouse TO USER your_username;
```

---

## 🎯 Option 1: Automated Script Deployment

### Step 1: Configure Your Account Details

Edit the deployment script with your Snowflake details:

```bash
cd RDF_to_Snowflake_Demo
nano deploy_to_snowflake.sh  # or use your preferred editor
```

Update these variables:
```bash
SNOWFLAKE_ACCOUNT="your-account-identifier"  # e.g., abc12345.us-east-1
SNOWFLAKE_USER="your-username"               # Your Snowflake username
SNOWFLAKE_DATABASE="RDF_SEMANTIC_DB"        # Database to create
SNOWFLAKE_SCHEMA="SEMANTIC_VIEWS"           # Schema to create
SNOWFLAKE_WAREHOUSE="RDF_DEMO_WH"           # Warehouse to create
```

### Step 2: Run the Deployment Script

```bash
./deploy_to_snowflake.sh
```

The script will:
- ✅ Create Python UDFs for RDF processing
- ✅ Set up database, schema, and warehouse
- ✅ Create semantic tables and views
- ✅ Load sample RDF data
- ✅ Verify the deployment

### Step 3: Verify Deployment

After successful deployment, connect to Snowflake and run:
```sql
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;
SHOW VIEWS LIKE 'SV_%';
SELECT COUNT(*) FROM SV_PRODUCT;
```

---

## 🖥️ Option 2: Manual Snowsight Deployment

### Step 1: Open Snowflake Web Interface

Navigate to: https://app.snowflake.com

### Step 2: Execute Deployment Script

1. Open a new worksheet in Snowsight
2. Copy the contents of `deploy_via_snowsight.sql`
3. Update the configuration variables at the top:
   ```sql
   SET database_name = 'RDF_SEMANTIC_DB';
   SET schema_name = 'SEMANTIC_VIEWS';  
   SET warehouse_name = 'RDF_DEMO_WH';
   ```
4. Execute the script section by section

### Step 3: Create Python UDFs

Copy and paste the contents of each UDF file:

1. **RDF Parser UDF**: Copy from `python_udfs/rdf_parser_udf.sql`
2. **View Generator UDF**: Copy from `python_udfs/semantic_view_generator_udf.sql`
3. **Data Loader UDF**: Copy from `python_udfs/rdf_data_loader_udf.sql`

### Step 4: Complete the Deployment

Continue executing the remaining sections of `deploy_via_snowsight.sql`

---

## ⌨️ Option 3: SnowSQL Command Line

### Step 1: Configure SnowSQL Connection

Create or update your SnowSQL config:
```bash
snowsql --configure-connection demo
```

### Step 2: Execute Scripts Individually

```bash
# Set up environment
snowsql -c demo -f sql/01_setup_environment.sql

# Create Python UDFs
snowsql -c demo -f python_udfs/rdf_parser_udf.sql
snowsql -c demo -f python_udfs/semantic_view_generator_udf.sql
snowsql -c demo -f python_udfs/rdf_data_loader_udf.sql

# Run complete demo
snowsql -c demo -f run_complete_demo.sql
```

---

## 🔧 Configuration Details

### Account Identifier Formats

Your Snowflake account identifier can be in several formats:

- **Legacy**: `abc12345.us-east-1`
- **New Format**: `orgname-accountname`
- **URL-based**: Extract from your Snowflake URL

### Finding Your Account Identifier

1. **From Snowflake URL**: 
   - URL: `https://abc12345.snowflakecomputing.com`
   - Account: `abc12345`

2. **From Snowsight**: 
   - Look at the URL: `https://app.snowflake.com/abc12345/`
   - Account: `abc12345`

3. **Ask your admin** for the organization and account names

### Authentication Methods

The demo supports multiple authentication methods:

- **Username/Password**: Default method
- **Key Pair Authentication**: More secure for automation
- **SSO**: If configured in your organization

---

## ✅ Verification Steps

After deployment, verify everything is working:

### 1. Check Database Objects
```sql
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

-- Show created tables
SHOW TABLES;

-- Show semantic views
SHOW VIEWS LIKE 'SV_%';

-- Show functions
SHOW FUNCTIONS LIKE '%RDF%';
```

### 2. Test Semantic Views
```sql
-- Test product data
SELECT * FROM SV_PRODUCT LIMIT 5;

-- Test relationships
SELECT * FROM SV_RELATIONSHIPS LIMIT 5;

-- Test semantic query
SELECT 
    p."Product Name",
    p."Price",
    c."Category Name"
FROM SV_PRODUCT p
JOIN SV_RELATIONSHIPS r ON p.URI = r.SUBJECT_URI 
JOIN SV_CATEGORY c ON r.OBJECT_URI = c.URI
WHERE r.RELATIONSHIP_TYPE = 'belongsToCategory';
```

### 3. Test RDF Processing UDFs
```sql
-- Test RDF parsing
SELECT PARSE_RDF_SCHEMA('
@prefix ex: <http://example.com/test#> .
ex:TestClass a rdfs:Class .
', 'turtle');
```

---

## 🎯 Next Steps After Deployment

### 1. Explore Sample Queries
```sql
-- Execute sample queries
@examples/semantic_queries.sql
```

### 2. Try Advanced Features
```sql
-- Set up advanced analytics
@examples/advanced_features.sql
```

### 3. Load Your Own RDF Data

Use the provided UDFs to load your own RDF schemas:

```sql
-- Load your RDF schema
INSERT INTO RDF_SCHEMAS (SCHEMA_ID, SCHEMA_NAME, RDF_FORMAT, RDF_CONTENT)
VALUES ('MY_SCHEMA', 'My Domain Model', 'turtle', '... your RDF content ...');

-- Parse and generate views
SELECT PARSE_RDF_SCHEMA(RDF_CONTENT, RDF_FORMAT) FROM RDF_SCHEMAS WHERE SCHEMA_ID = 'MY_SCHEMA';
```

---

## 🚨 Troubleshooting

### Common Issues

1. **Permission Errors**
   ```sql
   -- Grant required permissions
   GRANT CREATE DATABASE ON ACCOUNT TO USER your_username;
   ```

2. **UDF Creation Failures**
   - Ensure Python UDFs are enabled in your account
   - Check package dependencies are available

3. **Connection Issues**
   - Verify account identifier format
   - Check username and password
   - Ensure network connectivity

### Getting Help

- Check Snowflake documentation: https://docs.snowflake.com
- Review error messages in the deployment output
- Test individual components step by step

---

## 📊 What Gets Created

After successful deployment, you'll have:

### Databases and Schemas
- **Database**: `RDF_SEMANTIC_DB`
- **Schema**: `SEMANTIC_VIEWS`
- **Warehouse**: `RDF_DEMO_WH`

### Python UDFs
- `PARSE_RDF_SCHEMA()` - Parse RDF schemas
- `GENERATE_SEMANTIC_VIEW_DDL()` - Generate DDL
- `LOAD_RDF_DATA()` - Load RDF instance data

### Tables
- `PRODUCT`, `CATEGORY`, `CUSTOMER`, `ORDER_`, `RELATIONSHIPS`
- `RDF_SCHEMAS`, `CONVERSION_RESULTS`, `SEMANTIC_VIEW_METADATA`

### Semantic Views
- `SV_PRODUCT`, `SV_CUSTOMER`, `SV_ORDER`, `SV_CATEGORY`
- `SV_RELATIONSHIPS`, `SV_MASTER_SEMANTIC_MODEL`

### Sample Data
- Complete e-commerce dataset with products, customers, orders
- RDF relationships and semantic annotations
- Ready-to-query semantic views

---

## 🎉 Success!

Once deployed, you have a complete RDF-to-Snowflake semantic processing environment ready for:

- Loading and parsing RDF schemas
- Converting RDF to optimized Snowflake structures  
- Running semantic queries and analytics
- Exploring graph relationships and patterns
- Building semantic applications

Enjoy exploring your semantic data in Snowflake! 🚀