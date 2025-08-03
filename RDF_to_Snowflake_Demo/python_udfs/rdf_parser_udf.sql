-- Python UDF for parsing RDF schemas and extracting semantic information
-- This UDF handles multiple RDF serialization formats (Turtle, JSON-LD, N-Triples)

-- Set the correct Snowflake context
USE ROLE SYSADMIN;
USE WAREHOUSE RDF_DEMO_WH;
USE DATABASE RDF_SEMANTIC_DB;
USE SCHEMA SEMANTIC_VIEWS;

CREATE OR REPLACE FUNCTION parse_rdf_schema(rdf_content STRING, format STRING DEFAULT 'turtle')
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
-- Using only standard Python libraries
HANDLER = 'parse_rdf'
AS
$$
import json
import re

def parse_rdf(rdf_content, format_type='turtle'):
    """
    Simplified RDF parser using standard Python libraries
    Extracts basic schema information from RDF content
    """
    try:
        schema_info = {
            'classes': [],
            'properties': [],
            'data_properties': [],
            'object_properties': [],
            'hierarchies': [],
            'namespaces': {},
            'statistics': {
                'total_triples': 0,
                'total_classes': 0,
                'total_properties': 0
            }
        }
        
        if format_type.lower() in ['json-ld', 'jsonld']:
            return parse_jsonld_simple(rdf_content)
        else:
            return parse_turtle_simple(rdf_content)
            
    except Exception as e:
        return {
            'error': str(e),
            'classes': [],
            'properties': [],
            'data_properties': [],
            'object_properties': [],
            'hierarchies': [],
            'namespaces': {},
            'statistics': {'total_triples': 0, 'total_classes': 0, 'total_properties': 0}
        }

def parse_turtle_simple(rdf_content):
    """Simple Turtle RDF parser using regex"""
    schema_info = {
        'classes': [],
        'properties': [],
        'data_properties': [],
        'object_properties': [],
        'hierarchies': [],
        'namespaces': {},
        'statistics': {'total_triples': 0, 'total_classes': 0, 'total_properties': 0}
    }
    
    lines = rdf_content.split('\n')
    current_subject = None
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        # Extract prefixes
        if line.startswith('@prefix'):
            prefix_match = re.match(r'@prefix\s+(\w+):\s+<([^>]+)>', line)
            if prefix_match:
                prefix, namespace = prefix_match.groups()
                schema_info['namespaces'][prefix] = namespace
        
        # Extract classes (simplified)
        elif 'rdfs:Class' in line or 'rdf:type rdfs:Class' in line:
            class_match = re.search(r'(\w+:\w+|\w+)\s+.*rdfs:Class', line)
            if class_match:
                class_uri = expand_uri(class_match.group(1), schema_info['namespaces'])
                class_info = {
                    'uri': class_uri,
                    'local_name': get_local_name(class_uri),
                    'label': extract_label(line),
                    'comment': extract_comment(line),
                    'super_classes': [],
                    'properties': []
                }
                schema_info['classes'].append(class_info)
        
        # Extract properties
        elif 'rdf:Property' in line:
            prop_match = re.search(r'(\w+:\w+|\w+)\s+.*rdf:Property', line)
            if prop_match:
                prop_uri = expand_uri(prop_match.group(1), schema_info['namespaces'])
                prop_info = {
                    'uri': prop_uri,
                    'local_name': get_local_name(prop_uri),
                    'label': extract_label(line),
                    'comment': extract_comment(line),
                    'domain': [],
                    'range': [],
                    'type': 'property'
                }
                schema_info['properties'].append(prop_info)
    
    schema_info['statistics']['total_classes'] = len(schema_info['classes'])
    schema_info['statistics']['total_properties'] = len(schema_info['properties'])
    
    return schema_info

def parse_jsonld_simple(rdf_content):
    """Simple JSON-LD parser"""
    try:
        data = json.loads(rdf_content)
        schema_info = {
            'classes': [],
            'properties': [],
            'data_properties': [],
            'object_properties': [],
            'hierarchies': [],
            'namespaces': {},
            'statistics': {'total_triples': 0, 'total_classes': 0, 'total_properties': 0}
        }
        
        # Extract context (namespaces)
        if '@context' in data:
            schema_info['namespaces'] = data['@context']
        
        # Extract from @graph if present
        items = data.get('@graph', [data] if isinstance(data, dict) else data)
        
        for item in items:
            if isinstance(item, dict):
                if item.get('@type') == 'rdfs:Class':
                    class_info = {
                        'uri': item.get('@id', ''),
                        'local_name': get_local_name(item.get('@id', '')),
                        'label': item.get('rdfs:label', ''),
                        'comment': item.get('rdfs:comment', ''),
                        'super_classes': [],
                        'properties': []
                    }
                    schema_info['classes'].append(class_info)
                elif item.get('@type') == 'rdf:Property':
                    prop_info = {
                        'uri': item.get('@id', ''),
                        'local_name': get_local_name(item.get('@id', '')),
                        'label': item.get('rdfs:label', ''),
                        'comment': item.get('rdfs:comment', ''),
                        'domain': [item.get('rdfs:domain', {}).get('@id', '')] if item.get('rdfs:domain') else [],
                        'range': [item.get('rdfs:range', {}).get('@id', '')] if item.get('rdfs:range') else [],
                        'type': 'property'
                    }
                    schema_info['properties'].append(prop_info)
        
        schema_info['statistics']['total_classes'] = len(schema_info['classes'])
        schema_info['statistics']['total_properties'] = len(schema_info['properties'])
        
        return schema_info
        
    except Exception as e:
        return {'error': f'JSON-LD parsing error: {str(e)}'}

def expand_uri(short_uri, namespaces):
    """Expand a shortened URI using namespaces"""
    if ':' in short_uri:
        prefix, local = short_uri.split(':', 1)
        if prefix in namespaces:
            return namespaces[prefix] + local
    return short_uri

def extract_label(line):
    """Extract rdfs:label from a line"""
    label_match = re.search(r'rdfs:label\s+"([^"]+)"', line)
    return label_match.group(1) if label_match else ''

def extract_comment(line):
    """Extract rdfs:comment from a line"""
    comment_match = re.search(r'rdfs:comment\s+"([^"]+)"', line)
    return comment_match.group(1) if comment_match else ''

def get_local_name(uri):
    """Extract local name from URI"""
    if '#' in uri:
        return uri.split('#')[-1]
    elif '/' in uri:
        return uri.split('/')[-1]
    return uri

def get_literal_value(graph, subject, predicate):
    """Get literal value for a given subject and predicate"""
    for obj in graph.objects(subject, predicate):
        return str(obj)
    return None
$$;