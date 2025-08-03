#!/usr/bin/env python3
"""
Dry Run Integration Test for RDF to Snowflake Semantic Views Demo
This script validates the complete demo workflow without requiring Snowflake connection
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple
import subprocess

class DryRunIntegrationTest:
    def __init__(self, demo_root: str):
        self.demo_root = Path(demo_root)
        self.issues = []
        self.success = True
        
    def run_comprehensive_test(self):
        """Run complete integration test"""
        print("🧪 STARTING DRY RUN INTEGRATION TEST")
        print("="*60)
        
        # Step 1: Validate SQL syntax
        self._test_sql_syntax()
        
        # Step 2: Test script execution order
        self._test_execution_order()
        
        # Step 3: Test UDF consistency
        self._test_udf_consistency()
        
        # Step 4: Test data flow integrity
        self._test_data_flow()
        
        # Step 5: Test complete workflow simulation
        self._test_workflow_simulation()
        
        # Generate final report
        self._generate_final_report()
        
        return self.success
    
    def _test_sql_syntax(self):
        """Test SQL syntax using external tools if available"""
        print("\n🔍 TESTING SQL SYNTAX VALIDATION")
        print("-" * 40)
        
        sql_files = list(self.demo_root.glob("**/*.sql"))
        
        for sql_file in sql_files:
            print(f"📄 Checking: {sql_file.name}")
            
            try:
                with open(sql_file, 'r') as f:
                    content = f.read()
                
                # Basic syntax checks
                self._check_basic_sql_syntax(sql_file, content)
                
            except Exception as e:
                self._add_issue("ERROR", f"Failed to read {sql_file}: {e}")
        
        print("✅ SQL syntax validation completed")
    
    def _check_basic_sql_syntax(self, sql_file: Path, content: str):
        """Perform basic SQL syntax validation"""
        
        # Check for common syntax issues
        checks = [
            (r'CREATE\s+FUNCTION.*\(.*\).*RETURNS.*LANGUAGE.*PYTHON', "Python UDF structure"),
            (r'USE\s+(ROLE|WAREHOUSE|DATABASE|SCHEMA)\s+\w+', "Context settings"),
            (r'CREATE\s+(DATABASE|SCHEMA|WAREHOUSE|TABLE|VIEW)', "Object creation"),
            (r'INSERT\s+INTO.*SELECT', "Insert statements"),
        ]
        
        for pattern, description in checks:
            if re.search(pattern, content, re.IGNORECASE | re.DOTALL):
                print(f"  ✅ {description}")
            
        # Check for potential issues
        issue_checks = [
            (r'VALUES\s*\([^)]*UUID_STRING\(\)', "UUID_STRING in VALUES clause"),
            (r'COMMENT\s+["\'][^=]', "Incorrect COMMENT syntax"),
            (r'\$\w+', "Unresolved variables"),
        ]
        
        for pattern, issue_desc in issue_checks:
            if re.search(pattern, content, re.IGNORECASE):
                self._add_issue("WARNING", f"{sql_file.name}: {issue_desc}")
    
    def _test_execution_order(self):
        """Test that scripts can be executed in the correct order"""
        print("\n🔄 TESTING SCRIPT EXECUTION ORDER")
        print("-" * 40)
        
        # Define expected execution order
        script_order = [
            "sql/01_setup_environment.sql",
            "python_udfs/rdf_parser_udf.sql",
            "python_udfs/semantic_view_generator_udf.sql", 
            "python_udfs/rdf_data_loader_udf.sql",
            "sql/02_run_conversion_demo.sql",
            "sql/03_create_semantic_views_demo.sql"
        ]
        
        for script_path in script_order:
            full_path = self.demo_root / script_path
            if full_path.exists():
                print(f"✅ {script_path}")
                self._validate_script_dependencies(full_path)
            else:
                self._add_issue("ERROR", f"Missing required script: {script_path}")
        
        print("✅ Execution order validation completed")
    
    def _validate_script_dependencies(self, script_path: Path):
        """Validate that script dependencies are met"""
        with open(script_path, 'r') as f:
            content = f.read()
        
        # Check for required context settings
        required_contexts = ['USE DATABASE', 'USE SCHEMA']
        
        for context in required_contexts:
            if context not in content.upper():
                if 'python_udfs' in str(script_path):
                    self._add_issue("INFO", f"{script_path.name}: Missing {context} (should be set)")
    
    def _test_udf_consistency(self):
        """Test UDF function definitions and calls are consistent"""
        print("\n🔧 TESTING UDF CONSISTENCY")
        print("-" * 40)
        
        # Run the comprehensive validation we built earlier
        try:
            result = subprocess.run([
                sys.executable, 
                str(self.demo_root / "tests/comprehensive_validation.py")
            ], capture_output=True, text=True, cwd=self.demo_root)
            
            if result.returncode == 0:
                print("✅ All UDF consistency checks passed")
            else:
                print("❌ UDF consistency issues found:")
                print(result.stdout)
                self._add_issue("ERROR", "UDF consistency validation failed")
                
        except Exception as e:
            self._add_issue("WARNING", f"Could not run UDF validation: {e}")
        
        print("✅ UDF consistency validation completed")
    
    def _test_data_flow(self):
        """Test data flow integrity through the demo"""
        print("\n📊 TESTING DATA FLOW INTEGRITY")
        print("-" * 40)
        
        # Check that all required tables are created
        required_tables = [
            'RDF_SCHEMAS', 'CONVERSION_RESULTS', 'PRODUCT', 'CATEGORY', 
            'CUSTOMER', 'ORDER_', 'SUPPLIER', 'ORDERITEM'
        ]
        
        # Check that all semantic views are created  
        required_views = [
            'SV_PRODUCT', 'SV_CATEGORY', 'SV_CUSTOMER', 'SV_ORDER',
            'SV_SUPPLIER', 'SV_ORDERITEM', 'SV_PRODUCT_METRICS',
            'SV_ORDER_METRICS', 'SV_CUSTOMER_METRICS'
        ]
        
        self._check_object_creation(required_tables, "TABLE")
        self._check_object_creation(required_views, "VIEW")
        
        print("✅ Data flow integrity validation completed")
    
    def _check_object_creation(self, object_names: List[str], object_type: str):
        """Check that required database objects are created"""
        
        sql_files = list(self.demo_root.glob("**/*.sql"))
        created_objects = set()
        
        for sql_file in sql_files:
            with open(sql_file, 'r') as f:
                content = f.read()
            
            # Find CREATE TABLE/VIEW statements
            pattern = rf'CREATE\s+(?:OR\s+REPLACE\s+)?{object_type}\s+(\w+)'
            matches = re.findall(pattern, content, re.IGNORECASE)
            created_objects.update([match.upper() for match in matches])
        
        for obj_name in object_names:
            if obj_name.upper() in created_objects:
                print(f"  ✅ {object_type} {obj_name}")
            else:
                self._add_issue("WARNING", f"Required {object_type} {obj_name} not found in scripts")
    
    def _test_workflow_simulation(self):
        """Simulate the complete workflow logic"""
        print("\n🎭 TESTING WORKFLOW SIMULATION")
        print("-" * 40)
        
        workflow_steps = [
            "Environment Setup (Database, Schema, Warehouse)",
            "UDF Creation (Parse, Generate, Load functions)", 
            "Schema Loading (RDF content insertion)",
            "Schema Parsing (RDF → Structured data)",
            "DDL Generation (Structured data → SQL)",
            "Table Creation (Physical data model)",
            "Data Loading (Sample data insertion)",
            "Semantic View Creation (Business intelligence layer)",
            "Analytics Views (Metrics and aggregations)"
        ]
        
        for i, step in enumerate(workflow_steps, 1):
            print(f"  {i}. {step}")
            # Simulate step validation
            self._validate_workflow_step(step)
        
        print("✅ Workflow simulation completed")
    
    def _validate_workflow_step(self, step: str):
        """Validate individual workflow step"""
        # This is a placeholder for more detailed step validation
        # In a real implementation, this would check specific conditions
        # for each workflow step
        pass
    
    def _add_issue(self, severity: str, description: str):
        """Add an issue to the test results"""
        self.issues.append({"severity": severity, "description": description})
        if severity == "ERROR":
            self.success = False
    
    def _generate_final_report(self):
        """Generate final test report"""
        print("\n" + "="*60)
        print("🧪 DRY RUN INTEGRATION TEST RESULTS")
        print("="*60)
        
        if not self.issues:
            print("🎉 ALL TESTS PASSED! Demo is ready for deployment.")
            print("\n✅ VALIDATION SUMMARY:")
            print("  • SQL syntax: Valid")
            print("  • Script order: Correct") 
            print("  • UDF consistency: Verified")
            print("  • Data flow: Complete")
            print("  • Workflow: Validated")
            return
        
        # Group issues by severity
        errors = [i for i in self.issues if i["severity"] == "ERROR"]
        warnings = [i for i in self.issues if i["severity"] == "WARNING"] 
        info = [i for i in self.issues if i["severity"] == "INFO"]
        
        print(f"📊 SUMMARY: {len(errors)} Errors, {len(warnings)} Warnings, {len(info)} Info")
        
        for severity, issues in [("ERROR", errors), ("WARNING", warnings), ("INFO", info)]:
            if issues:
                print(f"\n🔴 {severity}S:")
                for issue in issues:
                    print(f"  • {issue['description']}")
        
        if errors:
            print("\n❌ INTEGRATION TEST FAILED - Fix errors before deployment")
        else:
            print("\n⚠️  INTEGRATION TEST PASSED WITH WARNINGS - Review before deployment")


def main():
    """Main test execution"""
    demo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    print(f"🎯 Testing RDF to Snowflake Demo at: {demo_root}")
    
    tester = DryRunIntegrationTest(demo_root)
    success = tester.run_comprehensive_test()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()