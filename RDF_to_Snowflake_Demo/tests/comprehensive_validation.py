#!/usr/bin/env python3
"""
Comprehensive Validation Script for RDF to Snowflake Semantic Views Demo
This script validates all SQL scripts for consistency, syntax, and integration issues.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set
from dataclasses import dataclass

@dataclass
class FunctionDefinition:
    name: str
    parameters: List[str]
    file_path: str
    line_number: int
    full_signature: str

@dataclass
class FunctionCall:
    name: str
    parameters: List[str]
    file_path: str
    line_number: int
    full_call: str

@dataclass
class ValidationIssue:
    severity: str  # 'ERROR', 'WARNING', 'INFO'
    category: str
    file_path: str
    line_number: int
    description: str
    suggestion: str = ""

class SQLValidator:
    def __init__(self, demo_root: str):
        self.demo_root = Path(demo_root)
        self.issues: List[ValidationIssue] = []
        self.function_definitions: Dict[str, FunctionDefinition] = {}
        self.function_calls: List[FunctionCall] = []
        self.context_settings: Dict[str, Dict[str, str]] = {}
        
    def validate_all(self) -> List[ValidationIssue]:
        """Run all validation checks"""
        print("🔍 Starting Comprehensive Validation...")
        
        # Find all SQL files
        sql_files = self._find_sql_files()
        print(f"📁 Found {len(sql_files)} SQL files to validate")
        
        # Step 1: Parse all files
        for sql_file in sql_files:
            self._parse_sql_file(sql_file)
        
        # Step 2: Run validation checks
        self._validate_function_signatures()
        self._validate_context_consistency()
        self._validate_dependency_order()
        self._validate_syntax_patterns()
        self._validate_warehouse_usage()
        
        # Step 3: Generate report
        self._generate_report()
        
        return self.issues
    
    def _find_sql_files(self) -> List[Path]:
        """Find all SQL files in the demo"""
        sql_files = []
        for pattern in ['**/*.sql']:
            sql_files.extend(self.demo_root.glob(pattern))
        return sorted(sql_files)
    
    def _parse_sql_file(self, sql_file: Path):
        """Parse a SQL file to extract functions, calls, and context"""
        try:
            with open(sql_file, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
            
            # Extract function definitions
            self._extract_function_definitions(sql_file, content, lines)
            
            # Extract function calls
            self._extract_function_calls(sql_file, content, lines)
            
            # Extract context settings
            self._extract_context_settings(sql_file, content, lines)
            
        except Exception as e:
            self.issues.append(ValidationIssue(
                severity='ERROR',
                category='FILE_PARSING',
                file_path=str(sql_file),
                line_number=0,
                description=f"Failed to parse file: {e}"
            ))
    
    def _extract_function_definitions(self, sql_file: Path, content: str, lines: List[str]):
        """Extract CREATE FUNCTION definitions"""
        # Pattern for function definitions
        function_pattern = r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(\w+)\s*\((.*?)\)'
        
        for match in re.finditer(function_pattern, content, re.IGNORECASE | re.DOTALL):
            func_name = match.group(1).upper()
            params_str = match.group(2)
            
            # Find line number
            line_num = content[:match.start()].count('\n') + 1
            
            # Parse parameters
            parameters = self._parse_parameters(params_str)
            
            func_def = FunctionDefinition(
                name=func_name,
                parameters=parameters,
                file_path=str(sql_file),
                line_number=line_num,
                full_signature=match.group(0)
            )
            
            self.function_definitions[func_name] = func_def
    
    def _extract_function_calls(self, sql_file: Path, content: str, lines: List[str]):
        """Extract function calls"""
        # Known UDF functions to look for
        udf_functions = [
            'PARSE_RDF_SCHEMA', 'GENERATE_SEMANTIC_VIEW_DDL', 
            'LOAD_RDF_DATA', 'GENERATE_SNOWFLAKE_SEMANTIC_VIEW',
            'GENERATE_ID'
        ]
        
        for func_name in udf_functions:
            # Pattern for function calls
            call_pattern = rf'{func_name}\s*\((.*?)\)'
            
            for match in re.finditer(call_pattern, content, re.IGNORECASE | re.DOTALL):
                params_str = match.group(1)
                line_num = content[:match.start()].count('\n') + 1
                
                # Parse parameters (simplified)
                parameters = self._parse_call_parameters(params_str)
                
                func_call = FunctionCall(
                    name=func_name.upper(),
                    parameters=parameters,
                    file_path=str(sql_file),
                    line_number=line_num,
                    full_call=match.group(0)
                )
                
                self.function_calls.append(func_call)
    
    def _extract_context_settings(self, sql_file: Path, content: str, lines: List[str]):
        """Extract USE statements for context"""
        context = {}
        
        # Extract USE statements
        use_patterns = {
            'ROLE': r'USE\s+ROLE\s+(\w+)',
            'WAREHOUSE': r'USE\s+WAREHOUSE\s+(\w+)',
            'DATABASE': r'USE\s+DATABASE\s+(\w+)',
            'SCHEMA': r'USE\s+SCHEMA\s+(\w+)'
        }
        
        for context_type, pattern in use_patterns.items():
            matches = re.findall(pattern, content, re.IGNORECASE)
            if matches:
                context[context_type] = matches[-1]  # Take the last one
        
        self.context_settings[str(sql_file)] = context
    
    def _parse_parameters(self, params_str: str) -> List[str]:
        """Parse function definition parameters"""
        if not params_str.strip():
            return []
        
        # Simple parameter parsing (ignores DEFAULT values for counting)
        params = []
        current_param = ""
        paren_depth = 0
        
        for char in params_str:
            if char == '(':
                paren_depth += 1
            elif char == ')':
                paren_depth -= 1
            elif char == ',' and paren_depth == 0:
                params.append(current_param.strip())
                current_param = ""
                continue
            
            current_param += char
        
        if current_param.strip():
            params.append(current_param.strip())
        
        return [p.split()[0] for p in params if p.strip()]  # Extract parameter names
    
    def _parse_call_parameters(self, params_str: str) -> List[str]:
        """Parse function call parameters (simplified)"""
        if not params_str.strip():
            return []
        
        # Count parameters by commas (ignoring nested calls)
        params = []
        current_param = ""
        paren_depth = 0
        quote_char = None
        
        for char in params_str:
            if quote_char:
                if char == quote_char:
                    quote_char = None
            elif char in ['"', "'"]:
                quote_char = char
            elif char == '(':
                paren_depth += 1
            elif char == ')':
                paren_depth -= 1
            elif char == ',' and paren_depth == 0 and not quote_char:
                params.append(current_param.strip())
                current_param = ""
                continue
            
            current_param += char
        
        if current_param.strip():
            params.append(current_param.strip())
        
        return [p for p in params if p.strip()]
    
    def _validate_function_signatures(self):
        """Validate function calls match definitions"""
        print("🔍 Validating function signatures...")
        
        for call in self.function_calls:
            if call.name not in self.function_definitions:
                self.issues.append(ValidationIssue(
                    severity='ERROR',
                    category='UNDEFINED_FUNCTION',
                    file_path=call.file_path,
                    line_number=call.line_number,
                    description=f"Function '{call.name}' is called but not defined",
                    suggestion="Ensure the function is created before calling it"
                ))
                continue
            
            definition = self.function_definitions[call.name]
            expected_params = len(definition.parameters)
            actual_params = len(call.parameters)
            
            if actual_params != expected_params:
                self.issues.append(ValidationIssue(
                    severity='ERROR',
                    category='PARAMETER_MISMATCH',
                    file_path=call.file_path,
                    line_number=call.line_number,
                    description=f"Function '{call.name}' expects {expected_params} parameters but got {actual_params}",
                    suggestion=f"Expected parameters: {', '.join(definition.parameters)}"
                ))
    
    def _validate_context_consistency(self):
        """Validate context settings are consistent"""
        print("🔍 Validating context consistency...")
        
        expected_context = {
            'ROLE': 'SYSADMIN',
            'WAREHOUSE': 'RDF_DEMO_WH',
            'DATABASE': 'RDF_SEMANTIC_DB',
            'SCHEMA': 'SEMANTIC_VIEWS'
        }
        
        for file_path, context in self.context_settings.items():
            # Skip parameterized scripts that use variables
            if 'deploy_via_snowsight.sql' in file_path:
                continue
            for context_type, expected_value in expected_context.items():
                if context_type in context and context[context_type] != expected_value:
                    self.issues.append(ValidationIssue(
                        severity='WARNING',
                        category='CONTEXT_INCONSISTENCY',
                        file_path=file_path,
                        line_number=0,
                        description=f"Inconsistent {context_type}: expected '{expected_value}', found '{context[context_type]}'",
                        suggestion=f"Use 'USE {context_type} {expected_value};'"
                    ))
                elif context_type not in context and 'python_udfs' in file_path:
                    self.issues.append(ValidationIssue(
                        severity='ERROR',
                        category='MISSING_CONTEXT',
                        file_path=file_path,
                        line_number=0,
                        description=f"Missing {context_type} context setting",
                        suggestion=f"Add 'USE {context_type} {expected_value};'"
                    ))
    
    def _validate_dependency_order(self):
        """Validate dependencies are in correct order"""
        print("🔍 Validating dependency order...")
        
        # Check if setup scripts run before UDF scripts
        setup_files = [f for f in self.context_settings.keys() if 'setup' in f.lower()]
        udf_files = [f for f in self.context_settings.keys() if 'python_udfs' in f]
        
        for udf_file in udf_files:
            udf_context = self.context_settings[udf_file]
            if 'WAREHOUSE' not in udf_context:
                self.issues.append(ValidationIssue(
                    severity='ERROR',
                    category='DEPENDENCY_ORDER',
                    file_path=udf_file,
                    line_number=0,
                    description="UDF script doesn't set warehouse context",
                    suggestion="Ensure setup script runs first or add warehouse context"
                ))
    
    def _validate_syntax_patterns(self):
        """Validate common SQL syntax patterns"""
        print("🔍 Validating syntax patterns...")
        
        # Check for common syntax issues
        syntax_checks = {
            'COMMENT_SYNTAX': r'(?:CREATE|ALTER).*COMMENT\s+["\'][^=]',  # Should be COMMENT = 'text'
            'UUID_IN_VALUES': r'VALUES\s*\([^)]*UUID_STRING\(\)',  # Should use SELECT
        }
        
        for sql_file in self._find_sql_files():
            try:
                with open(sql_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                for check_name, pattern in syntax_checks.items():
                    for match in re.finditer(pattern, content, re.IGNORECASE):
                        line_num = content[:match.start()].count('\n') + 1
                        
                        if check_name == 'COMMENT_SYNTAX':
                            self.issues.append(ValidationIssue(
                                severity='ERROR',
                                category='SYNTAX_ERROR',
                                file_path=str(sql_file),
                                line_number=line_num,
                                description="Incorrect COMMENT syntax",
                                suggestion="Use 'COMMENT = \"text\"' instead of 'COMMENT \"text\"'"
                            ))
                        elif check_name == 'UUID_IN_VALUES':
                            self.issues.append(ValidationIssue(
                                severity='ERROR',
                                category='SYNTAX_ERROR',
                                file_path=str(sql_file),
                                line_number=line_num,
                                description="UUID_STRING() function call in VALUES clause",
                                suggestion="Use SELECT statement instead of VALUES for function calls"
                            ))
            except Exception as e:
                continue
    
    def _validate_warehouse_usage(self):
        """Validate warehouse creation and usage"""
        print("🔍 Validating warehouse usage...")
        
        # Check if warehouse is created before being used
        warehouse_created = False
        warehouse_used = False
        
        for file_path, context in self.context_settings.items():
            with open(file_path, 'r') as f:
                content = f.read()
            
            if 'CREATE WAREHOUSE' in content.upper():
                warehouse_created = True
            
            if 'USE WAREHOUSE' in content.upper():
                warehouse_used = True
        
        if warehouse_used and not warehouse_created:
            self.issues.append(ValidationIssue(
                severity='WARNING',
                category='WAREHOUSE_DEPENDENCY',
                file_path='',
                line_number=0,
                description="Warehouse is used but creation not found in scripts",
                suggestion="Ensure warehouse is created in setup script"
            ))
    
    def _generate_report(self):
        """Generate validation report"""
        print("\n" + "="*80)
        print("🔍 COMPREHENSIVE VALIDATION REPORT")
        print("="*80)
        
        if not self.issues:
            print("✅ ALL VALIDATIONS PASSED - NO ISSUES FOUND!")
            return
        
        # Group issues by severity
        errors = [i for i in self.issues if i.severity == 'ERROR']
        warnings = [i for i in self.issues if i.severity == 'WARNING']
        info = [i for i in self.issues if i.severity == 'INFO']
        
        print(f"📊 SUMMARY: {len(errors)} Errors, {len(warnings)} Warnings, {len(info)} Info")
        
        for severity, issues in [('ERROR', errors), ('WARNING', warnings), ('INFO', info)]:
            if not issues:
                continue
                
            print(f"\n🔴 {severity}S ({len(issues)}):")
            print("-" * 50)
            
            for issue in issues:
                print(f"📁 File: {issue.file_path}")
                print(f"📍 Line: {issue.line_number}")
                print(f"🏷️  Category: {issue.category}")
                print(f"📝 Description: {issue.description}")
                if issue.suggestion:
                    print(f"💡 Suggestion: {issue.suggestion}")
                print()
        
        print("="*80)
        
        # Print function definitions summary
        print(f"\n📋 FUNCTION DEFINITIONS FOUND ({len(self.function_definitions)}):")
        for name, func_def in self.function_definitions.items():
            print(f"  {name}: {len(func_def.parameters)} parameters")
        
        # Print function calls summary
        print(f"\n📞 FUNCTION CALLS FOUND ({len(self.function_calls)}):")
        call_counts = {}
        for call in self.function_calls:
            call_counts[call.name] = call_counts.get(call.name, 0) + 1
        for name, count in call_counts.items():
            print(f"  {name}: {count} calls")


def main():
    """Main function to run validation"""
    # Get the demo root directory
    demo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    print(f"🎯 Validating RDF to Snowflake Demo at: {demo_root}")
    
    # Run validation
    validator = SQLValidator(demo_root)
    issues = validator.validate_all()
    
    # Return exit code based on issues
    error_count = len([i for i in issues if i.severity == 'ERROR'])
    sys.exit(error_count)

if __name__ == "__main__":
    main()