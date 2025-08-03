-- Python UDF for generating Snowflake semantic view DDL from RDF schema
-- This UDF converts parsed RDF schema information into Snowflake semantic view definitions

CREATE OR REPLACE FUNCTION generate_semantic_view_ddl(
    schema_info VARIANT,
    target_database STRING DEFAULT 'RDF_SEMANTIC_DB',
    target_schema STRING DEFAULT 'SEMANTIC_VIEWS',
    semantic_view_name STRING DEFAULT 'MAIN_SEMANTIC_VIEW'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
HANDLER = 'generate_ddl'
AS
$$
import json
import re

def generate_ddl(schema_info, target_database='RDF_SEMANTIC_DB', target_schema='SEMANTIC_VIEWS', semantic_view_name='MAIN_SEMANTIC_VIEW'):
    """
    Generate Snowflake semantic view DDL from parsed RDF schema information
    
    Args:
        schema_info (dict): Parsed RDF schema information
        target_database (str): Target Snowflake database name
        target_schema (str): Target Snowflake schema name
        semantic_view_name (str): Name for the main semantic view
    
    Returns:
        dict: Generated DDL statements and metadata
    """
    try:
        if isinstance(schema_info, str):
            schema_info = json.loads(schema_info)
        
        result = {
            'ddl_statements': [],
            'semantic_views': [],
            'relationships': [],
            'metadata': {
                'total_views': 0,
                'total_relationships': 0,
                'target_database': target_database,
                'target_schema': target_schema,
                'semantic_view_name': semantic_view_name
            }
        }
        
        # Create database and schema setup
        setup_ddl = [
            f"CREATE DATABASE IF NOT EXISTS {target_database};",
            f"USE DATABASE {target_database};",
            f"CREATE SCHEMA IF NOT EXISTS {target_schema};",
            f"USE SCHEMA {target_schema};"
        ]
        result['ddl_statements'].extend(setup_ddl)
        
        # Generate base tables for each RDF class
        for class_info in schema_info.get('classes', []):
            table_name = sanitize_name(class_info['local_name'])
            
            # Create base table DDL
            table_ddl = generate_base_table_ddl(class_info, schema_info, target_schema)
            result['ddl_statements'].append(table_ddl)
            
            # Generate semantic view DDL
            view_ddl = generate_semantic_view_for_class(class_info, schema_info, target_schema)
            result['ddl_statements'].append(view_ddl)
            
            # Store semantic view metadata
            view_info = {
                'view_name': f"SV_{table_name.upper()}",
                'base_table': table_name.upper(),
                'class_uri': class_info['uri'],
                'properties': get_class_properties(class_info, schema_info)
            }
            result['semantic_views'].append(view_info)
        
        result['metadata']['total_views'] = len(result['semantic_views'])
        
        # Generate relationship views
        relationship_ddl = generate_relationship_views(schema_info, target_schema)
        result['ddl_statements'].extend(relationship_ddl)
        
        # Generate hierarchy views
        hierarchy_ddl = generate_hierarchy_views(schema_info, target_schema)
        result['ddl_statements'].extend(hierarchy_ddl)
        
        # Generate master semantic model view
        master_view_ddl = generate_master_semantic_view(schema_info, target_schema, semantic_view_name)
        result['ddl_statements'].append(master_view_ddl)
        
        return result
        
    except Exception as e:
        return {
            'error': str(e),
            'ddl_statements': [],
            'semantic_views': [],
            'relationships': [],
            'metadata': {}
        }

def sanitize_name(name):
    """Sanitize name for Snowflake identifiers"""
    # Remove special characters and replace with underscore
    sanitized = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    # Ensure it starts with a letter or underscore
    if sanitized and sanitized[0].isdigit():
        sanitized = f"_{sanitized}"
    return sanitized.upper()

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
    return type_mapping.get(xsd_type, 'VARIANT')

def generate_base_table_ddl(class_info, schema_info, target_schema):
    """Generate base table DDL for an RDF class"""
    table_name = sanitize_name(class_info['local_name'])
    
    columns = [
        "ID VARCHAR(255) NOT NULL",
        "URI VARCHAR(1000) NOT NULL",
        "CLASS_URI VARCHAR(1000) NOT NULL"
    ]
    
    # Add columns for data properties
    for prop in schema_info.get('data_properties', []):
        if class_info['uri'] in prop.get('domain', []):
            col_name = sanitize_name(prop['local_name'])
            col_type = 'VARCHAR(16777216)'  # Default type
            
            if prop.get('range'):
                for range_type in prop['range']:
                    col_type = map_xsd_to_snowflake_type(range_type)
                    break
            
            columns.append(f"{col_name} {col_type}")
    
    # Add metadata columns
    columns.extend([
        "CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP",
        "UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP"
    ])
    
    columns_str = ',\n    '.join(columns)
    ddl = f"""
CREATE OR REPLACE TABLE {target_schema}.{table_name} (
    {columns_str},
    PRIMARY KEY (ID)
);
"""
    return ddl.strip()

def generate_semantic_view_for_class(class_info, schema_info, target_schema):
    """Generate semantic view DDL for an RDF class"""
    table_name = sanitize_name(class_info['local_name'])
    view_name = f"SV_{table_name}"
    
    # Base select columns
    select_columns = [
        "ID",
        "URI",
        "CLASS_URI"
    ]
    
    # Add data property columns with semantic metadata
    for prop in schema_info.get('data_properties', []):
        if class_info['uri'] in prop.get('domain', []):
            col_name = sanitize_name(prop['local_name'])
            label = prop.get('label', prop['local_name'])
            select_columns.append(f"{col_name} -- {label}")
    
    select_columns_str = ',\n    '.join(select_columns)
    ddl = f"""
CREATE OR REPLACE VIEW {target_schema}.{view_name} AS
SELECT 
    {select_columns_str},
    CREATED_AT,
    UPDATED_AT
FROM {target_schema}.{table_name}
COMMENT = 'Semantic view for RDF class: {class_info["uri"]}'
;
"""
    return ddl.strip()

def get_class_properties(class_info, schema_info):
    """Get properties associated with a class"""
    properties = []
    
    for prop in schema_info.get('properties', []):
        if class_info['uri'] in prop.get('domain', []):
            properties.append({
                'name': prop['local_name'],
                'type': prop['type'],
                'uri': prop['uri'],
                'label': prop.get('label'),
                'range': prop.get('range', [])
            })
    
    return properties

def generate_relationship_views(schema_info, target_schema):
    """Generate views for object properties (relationships)"""
    ddl_statements = []
    
    # Create relationships table
    rel_table_ddl = f"""
CREATE OR REPLACE TABLE {target_schema}.RELATIONSHIPS (
    ID VARCHAR(255) NOT NULL,
    SUBJECT_URI VARCHAR(1000) NOT NULL,
    PREDICATE_URI VARCHAR(1000) NOT NULL,
    OBJECT_URI VARCHAR(1000) NOT NULL,
    RELATIONSHIP_TYPE VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);
"""
    ddl_statements.append(rel_table_ddl)
    
    # Create semantic view for relationships
    rel_view_ddl = f"""
CREATE OR REPLACE VIEW {target_schema}.SV_RELATIONSHIPS AS
SELECT 
    ID,
    SUBJECT_URI,
    PREDICATE_URI,
    OBJECT_URI,
    RELATIONSHIP_TYPE,
    CREATED_AT
FROM {target_schema}.RELATIONSHIPS
COMMENT = 'Semantic view for RDF object properties and relationships'
;
"""
    ddl_statements.append(rel_view_ddl)
    
    return ddl_statements

def generate_hierarchy_views(schema_info, target_schema):
    """Generate views for class hierarchies"""
    ddl_statements = []
    
    if schema_info.get('hierarchies'):
        hierarchy_ddl = f"""
CREATE OR REPLACE VIEW {target_schema}.SV_CLASS_HIERARCHY AS
WITH RECURSIVE hierarchy_cte AS (
    -- Base case: direct parent-child relationships
    SELECT 
        SUBJECT_URI as CHILD_CLASS,
        OBJECT_URI as PARENT_CLASS,
        1 as LEVEL,
        SUBJECT_URI as ROOT_CLASS
    FROM {target_schema}.RELATIONSHIPS 
    WHERE RELATIONSHIP_TYPE = 'subClassOf'
    
    UNION ALL
    
    -- Recursive case: transitive relationships
    SELECT 
        h.CHILD_CLASS,
        r.OBJECT_URI as PARENT_CLASS,
        h.LEVEL + 1,
        h.ROOT_CLASS
    FROM hierarchy_cte h
    JOIN {target_schema}.RELATIONSHIPS r ON h.PARENT_CLASS = r.SUBJECT_URI
    WHERE r.RELATIONSHIP_TYPE = 'subClassOf' AND h.LEVEL < 10
)
SELECT * FROM hierarchy_cte
COMMENT = 'Hierarchical view of RDF class relationships'
;
"""
        ddl_statements.append(hierarchy_ddl)
    
    return ddl_statements

def generate_master_semantic_view(schema_info, target_schema, semantic_view_name='SV_MASTER_SEMANTIC_MODEL'):
    """Generate a master view that unifies all semantic information"""
    ddl = f"""
CREATE OR REPLACE VIEW {target_schema}.{semantic_view_name} AS
SELECT 
    'CLASS' as ENTITY_TYPE,
    URI as ENTITY_URI,
    CLASS_URI as TYPE_URI,
    NULL as PROPERTY_URI,
    NULL as VALUE_,
    CREATED_AT
FROM (
"""
    
    # Union all class tables
    union_parts = []
    for class_info in schema_info.get('classes', []):
        table_name = sanitize_name(class_info['local_name'])
        union_parts.append(f"    SELECT URI, CLASS_URI, CREATED_AT FROM {target_schema}.{table_name}")
    
    if union_parts:
        ddl += "\n    UNION ALL\n".join(union_parts)
    
    ddl += f"""
) classes

UNION ALL

SELECT 
    'RELATIONSHIP' as ENTITY_TYPE,
    SUBJECT_URI as ENTITY_URI,
    PREDICATE_URI as TYPE_URI,
    PREDICATE_URI as PROPERTY_URI,
    OBJECT_URI as VALUE_,
    CREATED_AT
FROM {target_schema}.RELATIONSHIPS
COMMENT = 'Master semantic model view combining all RDF entities and relationships'
;
"""
    return ddl.strip()
$$;