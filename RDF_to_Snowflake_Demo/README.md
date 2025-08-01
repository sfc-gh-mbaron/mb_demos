# RDF Schema to Snowflake Semantic Views Demo

This demo showcases how to convert RDF (Resource Description Framework) schemas to Snowflake semantic views using native Snowflake features like Python UDFs.

## Overview

The demo includes:
- Sample RDF schemas in different formats (Turtle, JSON-LD)
- Python UDFs for parsing RDF and generating Snowflake semantic view DDL
- SQL scripts to create and use semantic views
- Example queries demonstrating semantic view capabilities

## Architecture

```
RDF Schema → Python UDF → Semantic View DDL → Snowflake Semantic Views
```

## Components

1. **`sample_data/`** - Sample RDF schemas representing a simple e-commerce domain
2. **`python_udfs/`** - Python UDFs for RDF parsing and conversion
3. **`sql/`** - Snowflake SQL scripts for creating semantic views
4. **`examples/`** - Example queries and usage scenarios

## Prerequisites

- Snowflake account with Python UDF support
- Database with appropriate permissions
- Understanding of RDF concepts and Snowflake semantic views

## Usage

1. Execute the setup scripts to create Python UDFs
2. Load sample RDF data
3. Run conversion scripts to generate semantic views
4. Execute example queries to explore the semantic model

## Key Features

- Supports multiple RDF serialization formats
- Handles RDF Schema (RDFS) and basic OWL constructs
- Generates optimized Snowflake semantic view definitions
- Preserves semantic relationships and hierarchies
- Provides query examples for common semantic patterns