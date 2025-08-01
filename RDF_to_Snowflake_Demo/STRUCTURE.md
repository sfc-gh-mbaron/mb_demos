# Repository Structure

This document outlines the organized file structure of the RDF to Snowflake Semantic Views demo, following Snowflake-Labs standards.

## Directory Organization

```
RDF_to_Snowflake_Demo/
├── README.md                          # Main documentation and setup guide
├── LICENSE                            # Apache 2.0 license
├── LEGAL.md                          # Legal notices and third-party acknowledgments
├── environment.yml                    # Conda environment configuration
├── requirements.txt                   # Python pip dependencies
│
├── docs/                             # Additional documentation
│   ├── DEPLOYMENT_GUIDE.md           # Detailed deployment instructions
│   └── QUICK_START_GUIDE.md          # 5-minute quick start guide
│
├── scripts/                          # Deployment and utility scripts
│   ├── deploy_to_snowflake.sh        # Automated deployment script
│   ├── deploy_via_snowsight.sql      # Manual deployment for Snowsight
│   ├── cleanup_demo.sql              # Demo cleanup and teardown
│   └── run_complete_demo.sql         # One-click complete demo execution
│
├── sql/                              # Core SQL setup and demo scripts
│   ├── 01_setup_environment.sql      # Environment and MFA setup
│   ├── 02_run_conversion_demo.sql    # RDF conversion workflow
│   └── 03_create_semantic_views_demo.sql # Semantic views creation
│
├── python_udfs/                      # Python UDF definitions
│   ├── rdf_parser_udf.sql           # RDF schema parser UDF
│   ├── semantic_view_generator_udf.sql # Basic semantic view generator
│   ├── semantic_view_ddl_generator.sql # Advanced DDL generator
│   └── rdf_data_loader_udf.sql      # RDF data loading UDF
│
├── examples/                         # Example queries and demonstrations
│   ├── semantic_queries.sql          # Semantic view example queries
│   ├── advanced_features.sql         # Advanced capabilities demo
│   ├── data_loading_example.sql      # Data loading examples
│   └── cortex_analyst_semantic_queries.md # Natural language query examples
│
├── sample_data/                      # Sample RDF schemas and data
│   ├── ecommerce_schema.ttl          # E-commerce schema (Turtle format)
│   ├── ecommerce_schema.jsonld       # E-commerce schema (JSON-LD format)
│   └── sample_instances.ttl          # Sample RDF instance data
│
└── images/                           # Documentation assets
    └── architecture_overview.md      # Architecture diagram documentation
```

## Structure Benefits

### Clean Root Directory
- Only essential files (README, LICENSE, environment config) in root
- No loose scripts or documentation cluttering the main view
- Professional appearance matching Snowflake-Labs standards

### Logical Grouping
- **`scripts/`**: All deployment and utility scripts in one place
- **`docs/`**: Supplementary documentation separate from main README
- **`sql/`**: Core SQL files organized sequentially (01_, 02_, 03_)
- **`python_udfs/`**: All UDF definitions grouped together
- **`examples/`**: Demo queries and usage examples
- **`sample_data/`**: Sample schemas and test data

### Deployment-Friendly
- Scripts directory contains all deployment options
- Clear separation between setup SQL and utility scripts
- Documentation guides easily accessible but not cluttering

### Development-Friendly
- Related files grouped by function
- Sequential numbering for ordered execution
- Clear naming conventions throughout

This structure follows Snowflake-Labs best practices for demo repositories while maintaining clarity and ease of navigation.