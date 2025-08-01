-- Python UDF for parsing RDF schemas and extracting semantic information
-- This UDF handles multiple RDF serialization formats (Turtle, JSON-LD, N-Triples)

CREATE OR REPLACE FUNCTION parse_rdf_schema(rdf_content STRING, format STRING DEFAULT 'turtle')
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('rdflib==6.3.2', 'urllib3==1.26.18')
HANDLER = 'parse_rdf'
AS
$$
import json
from rdflib import Graph, Namespace, RDF, RDFS, OWL
from rdflib.namespace import XSD
from urllib.parse import urlparse

def parse_rdf(rdf_content, format_type='turtle'):
    """
    Parse RDF content and extract schema information for Snowflake semantic views
    
    Args:
        rdf_content (str): RDF content as string
        format_type (str): RDF serialization format ('turtle', 'json-ld', 'n3', 'xml')
    
    Returns:
        dict: Structured schema information
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
            # Default to turtle
            g.parse(data=rdf_content, format='turtle')
        
        # Extract schema information
        schema_info = {
            'classes': [],
            'properties': [],
            'data_properties': [],
            'object_properties': [],
            'hierarchies': [],
            'namespaces': {},
            'statistics': {
                'total_triples': len(g),
                'total_classes': 0,
                'total_properties': 0
            }
        }
        
        # Extract namespaces
        for prefix, namespace in g.namespaces():
            if prefix:
                schema_info['namespaces'][prefix] = str(namespace)
        
        # Extract classes
        for class_uri in g.subjects(RDF.type, RDFS.Class):
            class_info = {
                'uri': str(class_uri),
                'local_name': get_local_name(str(class_uri)),
                'label': get_literal_value(g, class_uri, RDFS.label),
                'comment': get_literal_value(g, class_uri, RDFS.comment),
                'super_classes': [],
                'properties': []
            }
            
            # Get superclasses
            for super_class in g.objects(class_uri, RDFS.subClassOf):
                class_info['super_classes'].append(str(super_class))
            
            schema_info['classes'].append(class_info)
        
        schema_info['statistics']['total_classes'] = len(schema_info['classes'])
        
        # Extract properties
        for prop_uri in g.subjects(RDF.type, RDF.Property):
            prop_info = {
                'uri': str(prop_uri),
                'local_name': get_local_name(str(prop_uri)),
                'label': get_literal_value(g, prop_uri, RDFS.label),
                'comment': get_literal_value(g, prop_uri, RDFS.comment),
                'domain': [],
                'range': [],
                'type': 'property'
            }
            
            # Get domain and range
            for domain in g.objects(prop_uri, RDFS.domain):
                prop_info['domain'].append(str(domain))
            
            for range_val in g.objects(prop_uri, RDFS.range):
                range_str = str(range_val)
                prop_info['range'].append(range_str)
                
                # Determine if it's a data property or object property
                if range_str.startswith('http://www.w3.org/2001/XMLSchema#'):
                    prop_info['type'] = 'data_property'
                    schema_info['data_properties'].append(prop_info)
                else:
                    # Check if range is a class
                    if (range_val, RDF.type, RDFS.Class) in g:
                        prop_info['type'] = 'object_property'
                        schema_info['object_properties'].append(prop_info)
            
            schema_info['properties'].append(prop_info)
        
        schema_info['statistics']['total_properties'] = len(schema_info['properties'])
        
        # Extract hierarchical relationships
        for subject in g.subjects(RDFS.subClassOf):
            for obj in g.objects(subject, RDFS.subClassOf):
                hierarchy = {
                    'child': str(subject),
                    'parent': str(obj),
                    'relationship_type': 'subClassOf'
                }
                schema_info['hierarchies'].append(hierarchy)
        
        return schema_info
        
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