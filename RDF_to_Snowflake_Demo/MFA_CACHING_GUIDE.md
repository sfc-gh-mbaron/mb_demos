# MFA Token Caching Configuration Guide

This guide shows how to configure MFA token caching to reduce authentication prompts during demo execution.

## Overview

Snowflake's MFA token caching stores your MFA token securely for up to **4 hours**, dramatically reducing the number of MFA prompts you'll receive during demo testing and development.

## Prerequisites

1. **Account Setup**: MFA token caching must be enabled at the account level (run `setup_mfa_caching.sql`)
2. **Client Support**: Your Snowflake client must support MFA token caching
3. **Secure Storage**: The `keyring` package must be installed for Python connections

## Configuration Methods

### 1. SnowSQL (Command Line) - Recommended for Demo

**Environment Variables Method:**
```bash
# Set these environment variables to reduce prompts
export SNOWSQL_ACCOUNT="your-account-identifier"
export SNOWSQL_USER="your-username"  
export SNOWSQL_PWD="your-password"
export SNOWSQL_ROLE="your-role"
export SNOWSQL_DATABASE="RDF_SEMANTIC_DB"
export SNOWSQL_SCHEMA="SEMANTIC_VIEWS"
export SNOWSQL_WAREHOUSE="RDF_DEMO_WH"

# Enable MFA token caching (already done by deployment script)
snowsql -f setup_mfa_caching.sql

# Now run demo commands - you'll only get MFA prompts once per 4-hour session
snowsql -f sql/01_setup_environment.sql
snowsql -f python_udfs/rdf_parser_udf.sql
# ... additional commands will reuse cached MFA token
```

**SnowSQL Config File Method:**
Create/update `~/.snowsql/config`:
```ini
[connections.demo_connection]
accountname = your-account-identifier
username = your-username
password = your-password
dbname = RDF_SEMANTIC_DB
schemaname = SEMANTIC_VIEWS
warehousename = RDF_DEMO_WH

# Use MFA token caching
authenticator = username_password_mfa
```

Then use: `snowsql -c demo_connection -f your_script.sql`

### 2. Python Connections (for Custom Scripts)

**Install Required Package:**
```bash
# Install with secure storage support
pip install "snowflake-connector-python[secure-local-storage]"
```

**Python Connection Code:**
```python
import snowflake.connector

# Create connection with MFA token caching
conn = snowflake.connector.connect(
    account='your-account-identifier',
    user='your-username',
    password='your-password',
    authenticator='username_password_mfa',  # Enable MFA caching
    database='RDF_SEMANTIC_DB',
    schema='SEMANTIC_VIEWS',
    warehouse='RDF_DEMO_WH'
)

# First connection will prompt for MFA
# Subsequent connections within 4 hours will use cached token
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_USER(), CURRENT_ROLE()")
print(cursor.fetchone())
```

### 3. JDBC Connections (for Java Applications)

**Connection String:**
```java
String url = "jdbc:snowflake://your-account.snowflakecomputing.com/?" +
             "user=your-username&" +
             "authenticator=username_password_mfa&" +
             "db=RDF_SEMANTIC_DB&" +
             "schema=SEMANTIC_VIEWS&" +
             "warehouse=RDF_DEMO_WH";

Connection conn = DriverManager.getConnection(url, "your-username", "your-password");
```

## Token Caching Behavior

### Cache Duration
- **Maximum**: 4 hours from initial authentication
- **Automatic Refresh**: Happens transparently during this period
- **Cross-Session**: Works across multiple SnowSQL/Python sessions

### Cache Invalidation
The MFA token cache is cleared when:
- 4 hours have elapsed since initial authentication
- You change authentication credentials (username/password)
- Account-level caching is disabled
- You manually clear the client keystore

### Cache Storage Locations
- **Windows**: Windows Credential Manager
- **macOS**: Keychain Access
- **Linux**: Secret Service API (gnome-keyring, kwallet, etc.)

## Security Considerations

### Benefits
✅ **Reduced Attack Surface**: Fewer manual MFA interactions  
✅ **Improved UX**: Seamless demo execution  
✅ **Maintained Security**: MFA still required, just cached securely  
✅ **Audit Trail**: All authentication events still logged  

### Security Controls
🔒 **Encrypted Storage**: Tokens stored in OS-level secure keystores  
🔒 **Time-Limited**: 4-hour maximum cache duration  
🔒 **Per-Account**: Tokens are account-specific  
🔒 **Revocable**: Account admins can disable caching anytime  

## Troubleshooting

### Common Issues

**Issue**: "MFA token caching not working"
```bash
# Check if caching is enabled at account level
snowsql -q "SHOW PARAMETERS LIKE 'ALLOW_CLIENT_MFA_CACHING' IN ACCOUNT"

# Should show: TRUE
```

**Issue**: "Keyring package errors"
```bash
# Reinstall with secure storage support
pip uninstall snowflake-connector-python
pip install "snowflake-connector-python[secure-local-storage]"
```

**Issue**: "Still getting MFA prompts"
- Verify authenticator is set to `username_password_mfa`
- Check that credentials haven't changed
- Ensure 4-hour window hasn't expired
- Verify keyring is accessible on your OS

### Clear Cached Tokens (if needed)
```bash
# Python method to clear tokens
python -c "
import keyring
import getpass
user = getpass.getuser()
keyring.delete_password('snowflake_token', user)
print('MFA token cache cleared')
"
```

## Demo-Specific Benefits

When running the RDF to Snowflake demo with MFA caching enabled:

1. **Initial Setup**: One MFA prompt when running `setup_mfa_caching.sql`
2. **UDF Deployment**: No additional MFA prompts for Python UDF creation
3. **Data Processing**: Seamless execution of conversion scripts
4. **Testing**: Multiple query executions without interruption
5. **Development**: Iterative testing and refinement without constant MFA

## Best Practices

### For Demo Environments
1. ✅ Enable MFA caching before starting demo deployment
2. ✅ Use environment variables for connection details
3. ✅ Group related operations to maximize cache benefit
4. ✅ Test connection caching before important demos

### For Production Environments
1. 🔍 Review with security team before enabling
2. 🔍 Monitor authentication logs regularly
3. 🔍 Consider shorter cache durations if required
4. 🔍 Implement account-level policies consistently

## Monitoring MFA Token Usage

Query to see MFA token cache usage:
```sql
-- View MFA token authentication events
SELECT 
    EVENT_TIMESTAMP,
    USER_NAME,
    IS_SUCCESS,
    SECOND_AUTHENTICATION_FACTOR,
    CLIENT_IP
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY 
WHERE SECOND_AUTHENTICATION_FACTOR = 'MFA_TOKEN'
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 20;
```

## Additional Resources

- [Snowflake MFA Documentation](https://docs.snowflake.com/en/user-guide/security-mfa.html)
- [SnowSQL Configuration Guide](https://docs.snowflake.com/en/user-guide/snowsql-install-config.html)
- [Python Connector Documentation](https://docs.snowflake.com/en/user-guide/python-connector.html)

---

By following this guide, your demo experience will be much smoother with minimal MFA interruptions while maintaining strong security controls!