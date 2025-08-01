# RDF Schema to Snowflake Semantic Views

This repository contains the code for the _RDF Schema to Snowflake Semantic Views_ Snowflake demo.

### ➡️ For overview, prerequisites, and to learn more about Snowflake Semantic Views, visit the [Snowflake Semantic Views documentation](https://docs.snowflake.com/en/user-guide/views-semantic/overview).

---

Here is an overview of what we'll build in this demo:

**Architecture Overview**: See [architecture diagram](images/architecture_overview.md) for detailed data flow visualization.

## Overview

This comprehensive demo showcases how to convert RDF (Resource Description Framework) schemas to **Snowflake Semantic Views** using native Snowflake features including Python UDFs and the complete semantic layer capabilities.

The demo includes:
- **RDF schema parsing** and semantic information extraction
- **Python UDFs** for automated conversion workflows
- **Snowflake Semantic Views** with full semantic layer features:
  - Tables with primary keys, synonyms, and business comments
  - Relationships between entities for complex data modeling
  - Facts for raw numerical data aggregation
  - Dimensions for categorical analysis and filtering
  - Metrics with comprehensive business calculations
  - Rich synonyms for natural language understanding
- **Cortex Analyst integration** for natural language querying
- **Sample data and queries** demonstrating business intelligence capabilities

## Prerequisites

Before running this demo, you will need:

### Snowflake Account Requirements
- A Snowflake account with **ACCOUNTADMIN** privileges or equivalent
- **Semantic Views** support enabled (available in most Snowflake accounts)
- **Python UDF** capabilities enabled
- **Cortex Analyst** access (optional, for natural language queries)

### Local Development Environment
- **Python 3.9+** installed
- **Git** for cloning the repository
- **SnowSQL** command-line client (optional but recommended)

### Snowflake Permissions
- `CREATE DATABASE` and `CREATE SCHEMA` privileges
- `CREATE FUNCTION` privileges for Python UDFs
- `CREATE VIEW` privileges for semantic views
- `USAGE` privilege on a warehouse

## Setup

### Step 1: Create Conda Environment

Clone this repository and create the conda environment:

```bash
git clone <repository-url>
cd RDF_to_Snowflake_Demo
conda env create -f environment.yml
conda activate rdf_semantic_snowflake
```

### Step 2: Configure Snowflake Connection

Update your Snowflake connection details. You can either:

**Option A: Use SnowSQL configuration**
```bash
# Configure SnowSQL with your credentials
snowsql --config-file config.ini
```

**Option B: Set environment variables (Recommended for MFA users)**
```bash
export SNOWSQL_ACCOUNT=<your-account>
export SNOWSQL_USER=<your-username>
export SNOWSQL_PWD=<your-password>
export SNOWSQL_ROLE=<your-role>
export SNOWSQL_DATABASE=<your-database>
export SNOWSQL_SCHEMA=<your-schema>
export SNOWSQL_WAREHOUSE=<your-warehouse>
```

**🔐 For MFA Users**: If you have MFA enabled, see the [MFA Caching Guide](MFA_CACHING_GUIDE.md) to enable token caching and reduce authentication prompts during demo execution.

### Step 3: Set Up Snowflake Environment

Run the setup script to create the necessary database, schema, and supporting objects:

```bash
snowsql -f sql/01_setup_environment.sql
```

## Demo Steps

### Step 0: Enable MFA Token Caching (Optional but Recommended)

For users with MFA enabled, reduce authentication prompts by enabling token caching:

```bash
snowsql -f setup_mfa_caching.sql
```

This enables MFA token caching for up to 4 hours, significantly reducing MFA prompts during demo execution.

### Step 1: Deploy Python UDFs

Deploy the RDF processing Python UDFs to Snowflake:

```bash
# Deploy RDF parser UDF
snowsql -f python_udfs/rdf_parser_udf.sql

# Deploy semantic view generator UDF  
snowsql -f python_udfs/semantic_view_ddl_generator.sql

# Deploy data loader UDF
snowsql -f python_udfs/rdf_data_loader_udf.sql
```

### Step 2: Run Conversion Demo

Execute the RDF to Snowflake conversion workflow:

```bash
snowsql -f sql/02_run_conversion_demo.sql
```

### Step 3: Create Comprehensive Semantic Views

Create the full Snowflake semantic views with all semantic layer features:

```bash
snowsql -f sql/03_create_semantic_views_demo.sql
```

### Step 4: Explore Sample Queries

Run example semantic queries to explore the data:

```bash
snowsql -f examples/semantic_queries.sql
```

### Step 5: Test Advanced Features

Explore advanced semantic view capabilities:

```bash
snowsql -f examples/advanced_features.sql
```

## Key Features Demonstrated

### 🌐 **RDF Integration**
- Multiple RDF serialization format support (Turtle, JSON-LD, RDF/XML)
- RDFS and OWL construct handling
- Semantic relationship preservation
- Automated ontology-to-database mapping

### 🧠 **Snowflake Semantic Views**
- **Tables**: Primary key definitions, rich synonyms, detailed business comments
- **Relationships**: Foreign key relationships, complex many-to-many relationships
- **Facts**: Raw numerical data for aggregation (prices, quantities, totals)
- **Dimensions**: Categorical attributes, time-based dimensions, derived dimensions
- **Metrics**: Revenue metrics, customer metrics, product metrics, operational metrics

### 💬 **Cortex Analyst Ready**
- Natural language query support
- Business-friendly synonyms and terminology
- Comprehensive metric calculations
- Rich contextual comments

### ⚡ **Production Ready**
- Optimized semantic view definitions
- Scalable Python UDF architecture
- Performance-optimized table structures
- Enterprise-grade security and governance

## Sample Natural Language Queries

With the semantic views, users can ask business questions in natural language using Cortex Analyst:

- **Revenue Analysis**: "What was our total revenue last year?"
- **Customer Insights**: "Who are our top customers by lifetime value?"
- **Inventory Management**: "Which products are out of stock?"
- **Performance Metrics**: "Show me our best-selling categories"
- **Operational Analysis**: "What's our average order value by month?"

## Architecture

The demo follows this architectural flow:

```
RDF Schema → Python UDFs → Snowflake Semantic Views → Cortex Analyst
     ↓            ↓              ↓                       ↓
  Turtle      RDF Parser    Tables, Facts,         Natural Language
 JSON-LD      Schema        Dimensions,               Queries
 RDF/XML      Analysis      Metrics,
                           Relationships
```

## Files and Structure

```
RDF_to_Snowflake_Demo/
├── README.md                          # This file
├── LICENSE                            # Apache 2.0 license
├── LEGAL.md                          # Legal notices
├── MFA_CACHING_GUIDE.md              # MFA token caching configuration
├── environment.yml                    # Conda environment
├── requirements.txt                   # Python requirements
├── setup_mfa_caching.sql             # MFA caching setup script
├── images/                           # Documentation assets
├── sample_data/                      # Sample RDF schemas and data
│   ├── ecommerce_schema.ttl         # E-commerce schema in Turtle
│   ├── ecommerce_schema.jsonld      # E-commerce schema in JSON-LD
│   └── sample_instances.ttl         # Sample RDF instance data
├── python_udfs/                     # Python UDF definitions
│   ├── rdf_parser_udf.sql          # RDF schema parser
│   ├── semantic_view_ddl_generator.sql # Semantic view generator
│   └── rdf_data_loader_udf.sql     # RDF data loader
├── sql/                             # SQL scripts
│   ├── 01_setup_environment.sql     # Environment setup
│   ├── 02_run_conversion_demo.sql   # Conversion workflow
│   └── 03_create_semantic_views_demo.sql # Semantic views creation
├── examples/                        # Example queries and guides
│   ├── semantic_queries.sql         # Semantic view queries
│   ├── advanced_features.sql        # Advanced capabilities
│   ├── data_loading_example.sql     # Data loading examples
│   └── cortex_analyst_semantic_queries.md # Natural language queries
├── deploy_to_snowflake.sh          # Automated deployment script
├── deploy_via_snowsight.sql        # Manual deployment for Snowsight
├── cleanup_demo.sql                # Cleanup script
└── run_complete_demo.sql           # One-click complete demo
```

## Deployment Options

### Option 1: Automated Deployment
```bash
./deploy_to_snowflake.sh
```

### Option 2: Manual Deployment via Snowsight
Follow the instructions in `deploy_via_snowsight.sql`

### Option 3: Step-by-step Deployment
Follow the individual steps in this README

## Cleanup

To remove all demo objects from your Snowflake account:

```bash
snowsql -f cleanup_demo.sql
```

## What Makes This Demo Special

1. **Complete Semantic Layer**: Full implementation of Snowflake's semantic view capabilities
2. **RDF Integration**: Bridges semantic web technologies with modern data warehousing
3. **Natural Language Ready**: Optimized for Cortex Analyst and business user queries
4. **Production Architecture**: Scalable, maintainable, and enterprise-ready
5. **Comprehensive Metrics**: Rich business intelligence layer with pre-calculated KPIs
6. **Rich Context**: Extensive synonyms, comments, and business-friendly terminology

This demo represents a complete implementation of semantic data processing, from RDF ingestion through to natural language business intelligence, showcasing the full power of Snowflake's semantic layer for modern data applications.

## Additional Resources

- [Snowflake Semantic Views Documentation](https://docs.snowflake.com/en/user-guide/views-semantic/overview)
- [Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Snowpark Python Developer Guide](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)
- [RDF and Semantic Web Primer](https://www.w3.org/RDF/)

---

For questions or issues with this demo, please refer to the [Snowflake Community](https://community.snowflake.com/) or [Snowflake Documentation](https://docs.snowflake.com/).