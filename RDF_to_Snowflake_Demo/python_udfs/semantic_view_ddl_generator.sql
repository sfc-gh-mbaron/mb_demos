-- Enhanced Python UDF for generating Snowflake SEMANTIC VIEW DDL from RDF schemas
-- This UDF creates proper Snowflake semantic views with dimensions, facts, metrics, relationships

CREATE OR REPLACE FUNCTION generate_snowflake_semantic_view(
    schema_info VARIANT,
    target_database STRING DEFAULT 'RDF_SEMANTIC_DB',
    target_schema STRING DEFAULT 'SEMANTIC_VIEWS',
    semantic_view_name STRING DEFAULT 'RDF_SEMANTIC_MODEL'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
HANDLER = 'generate_semantic_ddl'
AS
$$
import json
import re

def generate_semantic_ddl(schema_info, target_database='RDF_SEMANTIC_DB', target_schema='SEMANTIC_VIEWS', semantic_view_name='RDF_SEMANTIC_MODEL'):
    """
    Generate Snowflake CREATE SEMANTIC VIEW DDL from parsed RDF schema information
    
    Returns:
        dict: Generated semantic view DDL and metadata
    """
    try:
        if isinstance(schema_info, str):
            schema_info = json.loads(schema_info)
        
        result = {
            'semantic_view_ddl': '',
            'supporting_tables_ddl': [],
            'sample_queries': [],
            'metadata': {
                'view_name': semantic_view_name,
                'target_database': target_database,
                'target_schema': target_schema,
                'total_tables': 0,
                'total_relationships': 0,
                'total_dimensions': 0,
                'total_metrics': 0,
                'total_facts': 0
            }
        }
        
        # Generate supporting table DDL first
        tables_ddl = generate_supporting_tables(schema_info, target_schema)
        result['supporting_tables_ddl'] = tables_ddl
        
        # Generate the main semantic view DDL
        semantic_ddl = generate_semantic_view_ddl(schema_info, target_database, target_schema, semantic_view_name)
        result['semantic_view_ddl'] = semantic_ddl
        
        # Generate sample queries
        sample_queries = generate_sample_semantic_queries(semantic_view_name, target_database, target_schema)
        result['sample_queries'] = sample_queries
        
        # Update metadata
        result['metadata'].update(calculate_semantic_metadata(schema_info))
        
        return result
        
    except Exception as e:
        return {
            'error': str(e),
            'semantic_view_ddl': '',
            'supporting_tables_ddl': [],
            'sample_queries': [],
            'metadata': {}
        }

def generate_supporting_tables(schema_info, target_schema):
    """Generate DDL for supporting tables that will be used in the semantic view"""
    tables_ddl = []
    
    for class_info in schema_info.get('classes', []):
        table_name = sanitize_name(class_info['local_name'])
        
        # Base columns for all tables
        columns = [
            "ID VARCHAR(255) NOT NULL",
            "URI VARCHAR(1000) NOT NULL", 
            "CLASS_URI VARCHAR(1000) NOT NULL"
        ]
        
        # Add columns for data properties
        for prop in schema_info.get('data_properties', []):
            if class_info['uri'] in prop.get('domain', []):
                col_name = sanitize_name(prop['local_name'])
                col_type = map_xsd_to_snowflake_type(prop.get('range', ['http://www.w3.org/2001/XMLSchema#string'])[0])
                col_comment = prop.get('comment', prop.get('label', ''))
                
                column_def = f"{col_name} {col_type}"
                if col_comment:
                    column_def += f" COMMENT '{escape_sql_string(col_comment)}'"
                columns.append(column_def)
        
        # Add metadata columns
        columns.extend([
            "CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP",
            "UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP"
        ])
        
        columns_str = ',\n    '.join(columns)
        table_comment = class_info.get('comment', f"Table for RDF class: {class_info['uri']}")
        
        ddl = f"""
CREATE OR REPLACE TABLE {target_schema}.{table_name} (
    {columns_str},
    PRIMARY KEY (ID)
)
COMMENT = '{escape_sql_string(table_comment)}';
"""
        tables_ddl.append(ddl.strip())
    
    # Create relationships table
    relationships_ddl = f"""
CREATE OR REPLACE TABLE {target_schema}.RELATIONSHIPS (
    ID VARCHAR(255) NOT NULL,
    SUBJECT_URI VARCHAR(1000) NOT NULL,
    PREDICATE_URI VARCHAR(1000) NOT NULL,
    OBJECT_URI VARCHAR(1000) NOT NULL,
    RELATIONSHIP_TYPE VARCHAR(100) NOT NULL,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
)
COMMENT = 'Table storing all RDF object property relationships';
"""
    tables_ddl.append(relationships_ddl.strip())
    
    return tables_ddl

def generate_semantic_view_ddl(schema_info, target_database, target_schema, semantic_view_name):
    """Generate the main CREATE SEMANTIC VIEW DDL"""
    
    # Build TABLES section
    tables_section = generate_tables_section(schema_info, target_schema)
    
    # Build RELATIONSHIPS section
    relationships_section = generate_relationships_section(schema_info)
    
    # Build FACTS section
    facts_section = generate_facts_section(schema_info)
    
    # Build DIMENSIONS section
    dimensions_section = generate_dimensions_section(schema_info)
    
    # Build METRICS section
    metrics_section = generate_metrics_section(schema_info)
    
    # Combine all sections
    semantic_ddl = f"""
CREATE OR REPLACE SEMANTIC VIEW {target_database}.{target_schema}.{semantic_view_name}
{tables_section}
{relationships_section}
{facts_section}
{dimensions_section}
{metrics_section}
COMMENT = 'Comprehensive semantic view for RDF data model with full semantic capabilities including dimensions, facts, metrics, and relationships for natural language querying with Cortex Analyst';
"""
    
    return semantic_ddl.strip()

def generate_tables_section(schema_info, target_schema):
    """Generate the TABLES section of the semantic view"""
    tables = []
    
    for class_info in schema_info.get('classes', []):
        table_name = sanitize_name(class_info['local_name'])
        class_label = class_info.get('label', class_info['local_name'])
        class_comment = class_info.get('comment', f"Represents {class_label} entities")
        
        # Create synonyms list
        synonyms = [class_label, class_info['local_name']]
        if class_label.lower() != class_info['local_name'].lower():
            synonyms.append(class_info['local_name'].lower())
        synonyms_str = "', '".join(set(synonyms))
        
        table_def = f"""    {table_name.lower()} AS {target_schema}.{table_name}
      PRIMARY KEY (ID)
      WITH SYNONYMS ('{synonyms_str}')
      COMMENT = '{escape_sql_string(class_comment)}'"""
        
        tables.append(table_def)
    
    # Add relationships table
    relationships_def = f"""    relationships AS {target_schema}.RELATIONSHIPS
      PRIMARY KEY (ID)
      WITH SYNONYMS ('relationships', 'connections', 'links', 'associations')
      COMMENT = 'Table containing all semantic relationships between entities'"""
    
    tables.append(relationships_def)
    
    tables_str = ',\n'.join(tables)
    return f"""
  TABLES (
{tables_str}
  )"""

def generate_relationships_section(schema_info):
    """Generate the RELATIONSHIPS section"""
    relationships = []
    
    # Generate relationships based on object properties
    for prop in schema_info.get('object_properties', []):
        if prop.get('domain') and prop.get('range'):
            for domain_class in prop['domain']:
                for range_class in prop['range']:
                    domain_table = sanitize_name(get_local_name(domain_class)).lower()
                    range_table = sanitize_name(get_local_name(range_class)).lower()
                    
                    # Create relationship through the relationships table
                    rel_name = f"{domain_table}_to_{range_table}_{sanitize_name(prop['local_name']).lower()}"
                    relationships.append(f"""    {rel_name} AS
      {domain_table} (URI) REFERENCES {range_table} (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = '{prop['local_name']}'""")
    
    if not relationships:
        # Add some default relationships for the demo
        relationships = [
            """    product_categories AS
      product (URI) REFERENCES category (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'belongsToCategory'""",
            """    order_customers AS  
      order_ (URI) REFERENCES customer (URI)
      THROUGH relationships (SUBJECT_URI, OBJECT_URI)
      WHERE relationships.RELATIONSHIP_TYPE = 'placedBy'"""
        ]
    
    relationships_str = ',\n'.join(relationships)
    return f"""
  RELATIONSHIPS (
{relationships_str}
  )"""

def generate_facts_section(schema_info):
    """Generate the FACTS section"""
    facts = []
    
    # Generate facts from data properties
    for class_info in schema_info.get('classes', []):
        table_name = sanitize_name(class_info['local_name']).lower()
        
        for prop in schema_info.get('data_properties', []):
            if class_info['uri'] in prop.get('domain', []):
                prop_name = sanitize_name(prop['local_name']).lower()
                prop_comment = prop.get('comment', f"Raw {prop['local_name']} data")
                
                # Generate different types of facts based on data type
                range_type = prop.get('range', ['http://www.w3.org/2001/XMLSchema#string'])[0]
                
                if 'decimal' in range_type or 'float' in range_type or 'double' in range_type:
                    # Numerical fact
                    facts.append(f"""    {table_name}.{prop_name} AS {prop_name.upper()}
      COMMENT = '{escape_sql_string(prop_comment)}'""")
                elif 'integer' in range_type:
                    # Count-based fact  
                    facts.append(f"""    {table_name}.{prop_name} AS {prop_name.upper()}
      COMMENT = '{escape_sql_string(prop_comment)}'""")
    
    # Add some computed facts
    facts.extend([
        """    product.price AS PRODUCT_PRICE
      COMMENT = 'Individual product price for calculating revenue metrics'""",
        """    product.stockquantity AS STOCK_LEVEL  
      COMMENT = 'Current inventory level for availability analysis'""",
        """    order_.ordertotal AS ORDER_VALUE
      COMMENT = 'Total monetary value of each order'"""
    ])
    
    facts_str = ',\n'.join(facts)
    return f"""
  FACTS (
{facts_str}
  )"""

def generate_dimensions_section(schema_info):
    """Generate the DIMENSIONS section"""
    dimensions = []
    
    # Generate dimensions from classes and their properties
    for class_info in schema_info.get('classes', []):
        table_name = sanitize_name(class_info['local_name']).lower()
        class_label = class_info.get('label', class_info['local_name'])
        
        # Primary dimension - the entity name/identifier
        for prop in schema_info.get('data_properties', []):
            if class_info['uri'] in prop.get('domain', []):
                prop_name = sanitize_name(prop['local_name']).lower()
                prop_label = prop.get('label', prop['local_name'])
                prop_comment = prop.get('comment', f"{prop_label} for {class_label}")
                
                # Create synonyms for better natural language understanding
                synonyms = [prop_label, prop['local_name']]
                if 'name' in prop_name.lower():
                    synonyms.extend([f"{class_label} name", f"{class_label} title"])
                elif 'date' in prop_name.lower():
                    synonyms.extend(['date', 'time', 'when'])
                elif 'category' in prop_name.lower():
                    synonyms.extend(['type', 'kind', 'classification'])
                
                synonyms_str = "', '".join(set(synonyms))
                
                dimensions.append(f"""    {table_name}.{prop_name} AS {table_name.upper()}_{prop_name.upper()}
      WITH SYNONYMS ('{synonyms_str}')
      COMMENT = '{escape_sql_string(prop_comment)}'""")
    
    # Add time-based dimensions for temporal analysis
    dimensions.extend([
        """    order_.orderdate AS ORDER_DATE
      WITH SYNONYMS ('order date', 'purchase date', 'transaction date', 'when ordered')
      COMMENT = 'Date when the order was placed'""",
        """    YEAR(order_.orderdate) AS ORDER_YEAR
      WITH SYNONYMS ('year', 'order year', 'purchase year')  
      COMMENT = 'Year when the order was placed'""",
        """    MONTH(order_.orderdate) AS ORDER_MONTH
      WITH SYNONYMS ('month', 'order month', 'purchase month')
      COMMENT = 'Month when the order was placed'"""
    ])
    
    dimensions_str = ',\n'.join(dimensions)
    return f"""
  DIMENSIONS (
{dimensions_str}
  )"""

def generate_metrics_section(schema_info):
    """Generate the METRICS section with comprehensive business metrics"""
    metrics = [
        # Revenue metrics
        """    total_revenue AS SUM(order_.ordertotal)
      WITH SYNONYMS ('total sales', 'revenue', 'total income', 'gross sales')
      COMMENT = 'Total revenue across all orders'""",
        
        """    average_order_value AS AVG(order_.ordertotal)
      WITH SYNONYMS ('average order value', 'AOV', 'mean order value', 'avg order size')
      COMMENT = 'Average monetary value per order'""",
        
        # Count metrics
        """    total_orders AS COUNT(order_.id)
      WITH SYNONYMS ('order count', 'number of orders', 'total transactions')
      COMMENT = 'Total number of orders placed'""",
        
        """    total_customers AS COUNT(DISTINCT customer.id)
      WITH SYNONYMS ('customer count', 'number of customers', 'unique customers')
      COMMENT = 'Total number of unique customers'""",
        
        """    total_products AS COUNT(DISTINCT product.id)
      WITH SYNONYMS ('product count', 'number of products', 'inventory items')
      COMMENT = 'Total number of unique products in catalog'""",
        
        # Product metrics  
        """    average_product_price AS AVG(product.price)
      WITH SYNONYMS ('average price', 'mean price', 'typical price')
      COMMENT = 'Average price across all products'""",
        
        """    total_inventory_value AS SUM(product.price * product.stockquantity)
      WITH SYNONYMS ('inventory value', 'stock value', 'total inventory worth')
      COMMENT = 'Total monetary value of current inventory'""",
        
        # Performance metrics
        """    orders_per_customer AS COUNT(order_.id) / COUNT(DISTINCT customer.id)
      WITH SYNONYMS ('orders per customer', 'average orders per customer', 'customer order frequency')
      COMMENT = 'Average number of orders per customer'""",
        
        """    revenue_per_customer AS SUM(order_.ordertotal) / COUNT(DISTINCT customer.id)
      WITH SYNONYMS ('revenue per customer', 'customer lifetime value', 'CLV', 'average customer value')
      COMMENT = 'Average revenue generated per customer'"""
    ]
    
    metrics_str = ',\n'.join(metrics)
    return f"""
  METRICS (
{metrics_str}
  )"""

def generate_sample_semantic_queries(semantic_view_name, target_database, target_schema):
    """Generate sample queries for the semantic view"""
    queries = [
        f"""-- Query 1: Basic semantic view exploration
SELECT * FROM {target_database}.{target_schema}.{semantic_view_name};""",
        
        f"""-- Query 2: Revenue analysis by year  
SELECT 
    ORDER_YEAR,
    total_revenue,
    total_orders,
    average_order_value
FROM {target_database}.{target_schema}.{semantic_view_name}
GROUP BY ORDER_YEAR
ORDER BY ORDER_YEAR;""",
        
        f"""-- Query 3: Customer performance metrics
SELECT 
    CUSTOMER_CUSTOMERNAME,
    orders_per_customer,
    revenue_per_customer,
    total_orders
FROM {target_database}.{target_schema}.{semantic_view_name}
GROUP BY CUSTOMER_CUSTOMERNAME
ORDER BY revenue_per_customer DESC;""",
        
        f"""-- Query 4: Product catalog analysis
SELECT 
    PRODUCT_PRODUCTNAME,
    PRODUCT_PRICE,
    PRODUCT_STOCKQUANTITY,
    CATEGORY_CATEGORYNAME
FROM {target_database}.{target_schema}.{semantic_view_name}
ORDER BY PRODUCT_PRICE DESC;""",
        
        f"""-- Query 5: Monthly revenue trends
SELECT 
    ORDER_YEAR,
    ORDER_MONTH,
    total_revenue,
    total_orders,
    average_order_value
FROM {target_database}.{target_schema}.{semantic_view_name}
GROUP BY ORDER_YEAR, ORDER_MONTH
ORDER BY ORDER_YEAR, ORDER_MONTH;"""
    ]
    
    return queries

def calculate_semantic_metadata(schema_info):
    """Calculate metadata about the semantic model"""
    return {
        'total_tables': len(schema_info.get('classes', [])) + 1,  # +1 for relationships table
        'total_relationships': len(schema_info.get('object_properties', [])),
        'total_dimensions': len(schema_info.get('data_properties', [])) + 3,  # +3 for time dimensions
        'total_metrics': 9,  # Fixed number of business metrics
        'total_facts': len(schema_info.get('data_properties', [])) + 3  # +3 for computed facts
    }

def sanitize_name(name):
    """Sanitize name for Snowflake identifiers"""
    sanitized = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    if sanitized and sanitized[0].isdigit():
        sanitized = f"_{sanitized}"
    return sanitized.upper()

def get_local_name(uri):
    """Extract local name from URI"""
    if '#' in uri:
        return uri.split('#')[-1]
    elif '/' in uri:
        return uri.split('/')[-1]
    return uri

def map_xsd_to_snowflake_type(xsd_type):
    """Map XSD data types to Snowflake data types"""
    type_mapping = {
        'http://www.w3.org/2001/XMLSchema#string': 'VARCHAR(16777216)',
        'http://www.w3.org/2001/XMLSchema#integer': 'NUMBER(38,0)',
        'http://www.w3.org/2001/XMLSchema#decimal': 'NUMBER(38,2)',
        'http://www.w3.org/2001/XMLSchema#float': 'FLOAT',
        'http://www.w3.org/2001/XMLSchema#double': 'DOUBLE',
        'http://www.w3.org/2001/XMLSchema#boolean': 'BOOLEAN',
        'http://www.w3.org/2001/XMLSchema#date': 'DATE',
        'http://www.w3.org/2001/XMLSchema#dateTime': 'TIMESTAMP_NTZ',
        'http://www.w3.org/2001/XMLSchema#time': 'TIME'
    }
    return type_mapping.get(xsd_type, 'VARCHAR(16777216)')

def escape_sql_string(s):
    """Escape single quotes in SQL strings"""
    if s is None:
        return ''
    return str(s).replace("'", "''")
$$;