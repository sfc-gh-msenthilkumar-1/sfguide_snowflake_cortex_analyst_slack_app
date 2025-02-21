--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Create a secret with credentials for authenticating
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- To create a secret, you must use a role that has been granted the following privileges:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * CREATE SECRET on the schema where you’ll store the secret
-- * For more information, see CREATE SECRET access control requirements
-- * USAGE on the database and schema that will contain the integration


USE ROLE SECURITYADMIN;
CREATE ROLE <ROLE_SECRETS_ADMIN>;
GRANT CREATE SECRET ON SCHEMA <DB_NAME>.<SCHEMA_NAME> TO ROLE <ROLE_SECRETS_ADMIN>;

USE ROLE <CORTEX_USER_ROLE>;
GRANT USAGE ON DATABASE <DB_NAME> TO ROLE <ROLE_SECRETS_ADMIN>;
GRANT USAGE ON SCHEMA <DB_NAME>.<SCHEMA_NAME> TO ROLE <ROLE_SECRETS_ADMIN>;

GRANT ROLE ROLE_SECRETS_ADMIN TO USER <SF_USERNAME>;

USE ROLE <ROLE_SECRETS_ADMIN>;
USE DATABASE <DB_NAME>;
USE SCHEMA <DB_NAME>.<SCHEMA_NAME>;

CREATE OR REPLACE SECRET SF_GIT_SECRET
  TYPE = password
  USERNAME = '<my-account>'
  PASSWORD = 'ghp_xxx<token>';


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Create an API integration for interacting with the repository API
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- To create an API integration, you must use a role that has been granted the following privileges:
-- * CREATE INTEGRATION on the account
-- * USAGE on the database and schema that contain the secret
-- * USAGE on the secret that the integration references

-- When creating an API integration for a Git repository API, you must:
-- * Specify git_https_api as the value of the API_PROVIDER parameter.
-- * Specify, if authentication is required, a secret that contains the repository’s credentials as a value of the ALLOWED_AUTHENTICATION_SECRETS parameter. 
-- You can specify one of the following:
-- * One or more Snowflake secrets (in a comma-separated list) that Snowflake can use when authenticating with the repository
-- * The string 'all' (case insensitive) to specify that any secret may be used
-- * The string 'none' (case insensitive) to specify that no secrets may be used


USE ROLE SECURITYADMIN;
CREATE ROLE <ROLE_GIT_ADMIN>;
--USE ROLE ACCOUNTADMIN;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE <ROLE_GIT_ADMIN>;

USE ROLE <CORTEX_USER_ROLE>;
GRANT USAGE ON DATABASE CORTEX_ANALYST_DEMO TO ROLE <ROLE_GIT_ADMIN>;
GRANT USAGE ON SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES TO ROLE <ROLE_GIT_ADMIN>;

USE ROLE <ROLE_SECRETS_ADMIN>;
GRANT USAGE ON SECRET SF_GIT_SECRET TO ROLE <ROLE_GIT_ADMIN>;

GRANT ROLE <ROLE_GIT_ADMIN> TO USER <SF_USERNAME>;

USE ROLE <ROLE_GIT_ADMIN>;
USE DATABASE <DB_NAME>;
USE SCHEMA <SCHEMA_NAME>;

--USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE API INTEGRATION GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<my-account>')
  ALLOWED_AUTHENTICATION_SECRETS = (sf_git_secret)
  ENABLED = TRUE;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Create a Git repository stage and clone the repository
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- The Git repository stage specifies the following:
-- * The repository’s origin
    -- In Git, origin is shorthand for the remote repository’s URL. Use that URL when setting up Snowflake to use a Git repository. The URL must use HTTPS. You can retrieve the origin URL in the following ways:
    -- In the GitHub user interface, to get the origin URL from the repository home page, select the Code button, and then copy the HTTPS URL from the box displayed beneath the button.
    -- From the command line, use the git config command from within your local repository, as in the following example:
        -- $ git config --get remote.origin.url
        -- https://github.com/my-account/snowflake-extensions.git
        -- For reference information about git config, see the git documentation.

-- * Credentials, if needed, for Snowflake to use when authenticating with the repository
-- * An API integration specifying details for Snowflake interaction with the repository API

-- To create a Git repository stage, you must use a role that has been granted the following privileges:
    -- * CREATE GIT REPOSITORY on the schema that contains the repository
    -- * For more information, see CREATE GIT REPOSITORY access control requirements.
    -- * USAGE on the secret that contains credentials for authenticating with Git
    -- * USAGE on the API integration that the Git repository stage references

USE ROLE securityadmin;
GRANT CREATE GIT REPOSITORY ON SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES TO ROLE sf_git_admin;

USE ROLE sf_git_admin;

CREATE OR REPLACE GIT REPOSITORY <GIT_REPO_NAME>
  API_INTEGRATION = GIT_API_INTEGRATION
  GIT_CREDENTIALS = SF_GIT_SECRET
  ORIGIN = 'https://github.com/<my-account>/<repo-name>';
  
