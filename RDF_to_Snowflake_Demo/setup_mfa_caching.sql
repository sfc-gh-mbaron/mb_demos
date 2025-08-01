-- ============================================================================
-- SNOWFLAKE MFA TOKEN CACHING SETUP
-- ============================================================================
-- This script enables MFA token caching to reduce authentication prompts
-- during demo execution. Tokens are cached for up to 4 hours.
-- 
-- IMPORTANT: Run this as ACCOUNTADMIN or equivalent privileged role
-- ============================================================================

-- Enable MFA token caching at the account level
-- This allows clients to cache MFA tokens for up to 4 hours
ALTER ACCOUNT SET ALLOW_CLIENT_MFA_CACHING = TRUE;

-- Verify the setting is enabled
SHOW PARAMETERS LIKE 'ALLOW_CLIENT_MFA_CACHING' IN ACCOUNT;

-- Optional: Also enable ID token caching for federated authentication
-- (only if you also use federated SSO)
-- ALTER ACCOUNT SET ALLOW_ID_TOKEN = TRUE;

-- Display current MFA-related account parameters
SELECT 
    'MFA Token Caching Status' AS setting_type,
    CURRENT_TIMESTAMP() AS checked_at,
    'ALLOW_CLIENT_MFA_CACHING' AS parameter_name,
    "value" AS current_value,
    "default" AS default_value,
    "description" AS description
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "key" = 'ALLOW_CLIENT_MFA_CACHING';

-- Instructions for disabling (if needed later):
-- ALTER ACCOUNT UNSET ALLOW_CLIENT_MFA_CACHING;