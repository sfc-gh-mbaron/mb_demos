-- Python UDF for loading RDF instance data into Snowflake semantic tables
-- This UDF converts RDF triples into structured data for the semantic views

CREATE OR REPLACE FUNCTION load_rdf_data(
    rdf_content STRING,
    format STRING DEFAULT 'turtle',
    target_database STRING DEFAULT 'RDF_SEMANTIC_DB',
    target_schema STRING DEFAULT 'SEMANTIC_VIEWS'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('rdflib==6.3.2', 'urllib3==1.26.18')
HANDLER = 'load_data'
AS
$$
import json
import uuid
from rdflib import Graph, Namespace, RDF, RDFS, OWL
from rdflib.namespace import XSD
from urllib.parse import urlparse

def load_data(rdf_content, format_type='turtle', target_database='RDF_SEMANTIC_DB', target_schema='SEMANTIC_VIEWS'):
    """
    Parse RDF instance data and generate INSERT statements for Snowflake tables
    
    Args:
        rdf_content (str): RDF content as string
        format_type (str): RDF serialization format
        target_database (str): Target Snowflake database
        target_schema (str): Target Snowflake schema
    
    Returns:
        dict: Generated INSERT statements and data summary
    """
    try:
        # Create RDF graph
        g = Graph()
        
        # Parse the RDF content
        if format_type.lower() in ['turtle', 'ttl']:
            g.parse(data=rdf_content, format='turtle')
        elif format_type.lower() in ['json-ld', 'jsonld']:
            g.parse(data=rdf_content, format='json-ld')
        elif format_type.lower() in ['xml', 'rdf/xml']:
            g.parse(data=rdf_content, format='xml')
        elif format_type.lower() in ['n3', 'n-triples']:
            g.parse(data=rdf_content, format='n3')
        else:
            g.parse(data=rdf_content, format='turtle')
        
        result = {
            'insert_statements': [],
            'data_summary': {
                'total_triples': len(g),
                'entities_by_type': {},
                'relationships': 0,
                'data_properties': 0
            },
            'entities': {},
            'relationships': []
        }
        
        # Group entities by type
        entities_by_type = {}
        
        # Find all typed entities
        for subject in g.subjects(RDF.type):
            subject_uri = str(subject)
            
            for rdf_type in g.objects(subject, RDF.type):
                type_uri = str(rdf_type)
                
                # Skip RDF/RDFS/OWL system types
                if type_uri.startswith(('http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                                      'http://www.w3.org/2000/01/rdf-schema#',
                                      'http://www.w3.org/2002/07/owl#')):
                    continue
                
                if type_uri not in entities_by_type:
                    entities_by_type[type_uri] = []
                
                entities_by_type[type_uri].append(subject_uri)
        
        result['data_summary']['entities_by_type'] = {k: len(v) for k, v in entities_by_type.items()}
        
        # Generate INSERT statements for each entity type
        for type_uri, entity_uris in entities_by_type.items():
            table_name = get_table_name_from_type(type_uri)
            
            # Process each entity of this type
            entity_data = []
            
            for entity_uri in entity_uris:
                entity_id = generate_entity_id(entity_uri)
                entity_record = {
                    'ID': entity_id,
                    'URI': entity_uri,
                    'CLASS_URI': type_uri
                }
                
                # Extract data properties for this entity
                for predicate, obj in g.predicate_objects(subject=entity_uri):
                    predicate_uri = str(predicate)
                    
                    # Skip type declarations and system properties
                    if predicate_uri in ['http://www.w3.org/1999/02/22-rdf-syntax-ns#type']:
                        continue
                    
                    # Check if this is a data property (literal value)
                    if hasattr(obj, 'datatype') or isinstance(obj, str):
                        property_name = get_local_name(predicate_uri).upper()
                        entity_record[property_name] = str(obj)
                        result['data_summary']['data_properties'] += 1
                    
                    # Check if this is an object property (relationship)
                    else:
                        relationship = {
                            'ID': str(uuid.uuid4()),
                            'SUBJECT_URI': entity_uri,
                            'PREDICATE_URI': predicate_uri,
                            'OBJECT_URI': str(obj),
                            'RELATIONSHIP_TYPE': get_local_name(predicate_uri)
                        }
                        result['relationships'].append(relationship)
                        result['data_summary']['relationships'] += 1
                
                entity_data.append(entity_record)
            
            # Generate INSERT statement for this entity type
            if entity_data:
                insert_sql = generate_insert_statement(table_name, entity_data, target_schema)
                result['insert_statements'].append(insert_sql)
                result['entities'][type_uri] = entity_data
        
        # Generate INSERT statement for relationships
        if result['relationships']:
            rel_insert_sql = generate_relationship_insert_statement(result['relationships'], target_schema)
            result['insert_statements'].append(rel_insert_sql)
        
        return result
        
    except Exception as e:
        return {
            'error': str(e),
            'insert_statements': [],
            'data_summary': {},
            'entities': {},
            'relationships': []
        }

def get_local_name(uri):
    """Extract local name from URI"""
    if '#' in uri:
        return uri.split('#')[-1]
    elif '/' in uri:
        return uri.split('/')[-1]
    return uri

def get_table_name_from_type(type_uri):
    """Convert RDF type URI to Snowflake table name"""
    local_name = get_local_name(type_uri)
    return sanitize_name(local_name)

def sanitize_name(name):
    """Sanitize name for Snowflake identifiers"""
    import re
    sanitized = re.sub(r'[^a-zA-Z0-9_]', '_', name)
    if sanitized and sanitized[0].isdigit():
        sanitized = f"_{sanitized}"
    return sanitized.upper()

def generate_entity_id(uri):
    """Generate a unique ID for an entity"""
    return get_local_name(uri).upper() or str(uuid.uuid4())[:8].upper()

def generate_insert_statement(table_name, entity_data, target_schema):
    """Generate INSERT statement for entity data"""
    if not entity_data:
        return ""
    
    # Get all columns from the first record
    columns = list(entity_data[0].keys())
    
    # Generate VALUES clauses
    values_clauses = []
    for record in entity_data:
        values = []
        for col in columns:
            value = record.get(col, 'NULL')
            if value == 'NULL':
                values.append('NULL')
            else:
                # Escape single quotes and wrap in quotes
                escaped_value = str(value).replace("'", "''")
                values.append(f"'{escaped_value}'")
        values_clauses.append(f"    ({', '.join(values)})")
    
    insert_sql = f"""
INSERT INTO {target_schema}.{table_name} ({', '.join(columns)})
VALUES
{',\\n'.join(values_clauses)};
"""
    return insert_sql.strip()

def generate_relationship_insert_statement(relationships, target_schema):
    """Generate INSERT statement for relationships"""
    if not relationships:
        return ""
    
    columns = ['ID', 'SUBJECT_URI', 'PREDICATE_URI', 'OBJECT_URI', 'RELATIONSHIP_TYPE']
    
    values_clauses = []
    for rel in relationships:
        values = []
        for col in columns:
            value = rel.get(col, 'NULL')
            if value == 'NULL':
                values.append('NULL')
            else:
                escaped_value = str(value).replace("'", "''")
                values.append(f"'{escaped_value}'")
        values_clauses.append(f"    ({', '.join(values)})")
    
    insert_sql = f"""
INSERT INTO {target_schema}.RELATIONSHIPS ({', '.join(columns)})
VALUES
{',\\n'.join(values_clauses)};
"""
    return insert_sql.strip()
$$;