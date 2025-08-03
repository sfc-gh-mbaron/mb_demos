#!/usr/bin/env python3
"""
Local Launcher for RDF Semantic Chat Assistant
This script sets up the environment and runs the Streamlit app locally
"""

import subprocess
import sys
import os
from pathlib import Path

def check_requirements():
    """Check if required packages are installed"""
    required_packages = [
        'streamlit',
        'snowflake-snowpark-python',
        'snowflake-connector-python',
        'pandas',
        'plotly'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print("❌ Missing required packages:")
        for package in missing_packages:
            print(f"   • {package}")
        print("\n🔧 Install missing packages with:")
        print(f"   pip install {' '.join(missing_packages)}")
        print("\nOr install all requirements with:")
        print("   pip install -r requirements.txt")
        return False
    
    print("✅ All required packages are installed")
    return True

def setup_environment():
    """Set up environment variables for local development"""
    
    # Check for Snowflake connection configuration
    config_paths = [
        Path.home() / '.snowflake' / 'connections.toml',
        Path.home() / '.snowflake' / 'config.toml',
        Path('config.toml'),
        Path('.streamlit') / 'secrets.toml'
    ]
    
    config_found = False
    for config_path in config_paths:
        if config_path.exists():
            print(f"✅ Found Snowflake config: {config_path}")
            config_found = True
            break
    
    if not config_found:
        print("⚠️  No Snowflake configuration found.")
        print("📝 Create one of these configuration files:")
        print("   • ~/.snowflake/connections.toml")
        print("   • .streamlit/secrets.toml")
        print()
        print("Example configuration:")
        print("""
[default]
account = "your-account-identifier"
user = "your-username"
password = "your-password"
role = "SYSADMIN"
warehouse = "RDF_DEMO_WH"
database = "RDF_SEMANTIC_DB"
schema = "SEMANTIC_VIEWS"
        """)
        
        response = input("\nContinue anyway? (y/N): ").strip().lower()
        if response != 'y':
            return False
    
    return True

def run_streamlit():
    """Run the Streamlit application"""
    
    app_file = Path(__file__).parent / 'cortex_analyst_chat.py'
    
    if not app_file.exists():
        print(f"❌ Streamlit app not found: {app_file}")
        return False
    
    print(f"🚀 Starting Streamlit app: {app_file}")
    print("🌐 The app will open in your browser at: http://localhost:8501")
    print("⏹️  Press Ctrl+C to stop the application")
    print()
    
    try:
        # Run streamlit
        cmd = [sys.executable, '-m', 'streamlit', 'run', str(app_file)]
        subprocess.run(cmd, check=True)
        
    except KeyboardInterrupt:
        print("\n👋 Streamlit app stopped")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running Streamlit: {e}")
        return False
    
    except FileNotFoundError:
        print("❌ Streamlit not found. Install it with:")
        print("   pip install streamlit")
        return False

def main():
    """Main function"""
    
    print("🤖 RDF Semantic Chat Assistant - Local Launcher")
    print("=" * 50)
    
    # Check requirements
    if not check_requirements():
        sys.exit(1)
    
    # Setup environment
    if not setup_environment():
        sys.exit(1)
    
    print()
    print("🎯 Starting application...")
    print()
    
    # Run Streamlit
    if not run_streamlit():
        sys.exit(1)

if __name__ == "__main__":
    main()