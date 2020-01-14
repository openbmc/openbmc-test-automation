Redfish Coding Guidelines
=========================

-   For robot programs wishing to run Redfish commands, include the following in
    your robot file:

    ```
    *** Settings ***

    Resource                    bmc_redfish_resource.robot
    ```
-   This git repository has some redfish wrapper modules:

    -   [redfish_plus.py](../lib/redfish_plus.py)
    -   [bmc_redfish.py](../lib/bmc_redfish.py)
    -   [bmc_redfish_utils.py](../lib/bmc_redfish_utils.py)
    -   Redfish wrapper module features:

        For all Redfish REST requests (get, head, post, put, patch, delete):

        -   Support for python-like strings for all arguments which allows
            callers to easily specify complex arguments such as lists or
            dictionaries.

            So instead of coding this:

            ```
                ${ldap_type_dict}=  Create Dictionary  ServiceEnabled=${False}
                ${body}=  Create Dictionary  ${LDAP_TYPE}=${ldap_type_dict}
                Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body=${body}
            ```

            You can do it in one fell swoop like this:

            ```
                Redfish.Patch  ${REDFISH_BASE_URI}AccountService  body={'${LDAP_TYPE}': {'ServiceEnabled': ${False}}}
            ```
        -   Support for **valid_status_codes** argument and auto-failure:

            As mentioned above, this argument may be either an actual
            robot/python list or it may be a string value which python can
            translate into a list.

            The default value is [${HTTP_OK}].

            This means that the Redfish REST request will fail
            **automatically** if the resulting status code is not found in the
            valid_status_codes list.

            So instead of having to do this:

            ```
                ${resp}=  Redfish.Get  ${EVENT_LOG_URI}Entries
                Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
            ```

            You can simply do this:

            ```
                ${resp}=  Redfish.Get  ${EVENT_LOG_URI}Entries
            ```

            If, for some reason, you **expect** your command to fail, you can
            specify the expected status code or codes:

            ```
            Redfish.Patch  ${REDFISH_BASE_URI}UpdateService  body={'ApplyTime' : 'Invalid'}  valid_status_codes=[${HTTP_BAD_REQUEST}]
            ```
    -   Login defaults for path, username and password are
        https://${OPENBMC_HOST}, ${OPENBMC_USERNAME}, ${OPENBMC_PASSWORD}.
    -   Many utility functions are available.  Examples:;

        -   get_properties
        -   get_attributes
        -   get_session_info
        -   list_request
        -   enumerate_request

Rules for use of Redfish.Login and Redfish.Logout
=================================================

It is desirable to avoid excessive redfish logins/logouts for the following
reasons:
-	It simplifies the code base.
-	It allows calling keywords and testcases to keep control over login
    parameters like USERNAME, PASSWORD, etc.  Consider the following example:

    ```
    # Login to redfish with non-standard username/password.
    Redfish.Login  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    # Run 'Some Keyword' while logged in as ${LDAP_USER}/${LDAP_USER_PASSWORD}.
    Some Keyword
    ```
    If 'Some Keyword' in the example above does its own Redfish.Login, it will
    thwart the stated purpose of the caller.

**Rules:**

-   Login should be done once in Suite Setup:

    ```
    *** Keywords ***
    Suite Setup Execution
        Redfish.Login
    ```
-   Logout should be done once in Suite Teardown:
    ```
    *** Keywords ***
    Suite Teardown Execution
        Redfish.Logout
    ```
-   As a result of the first two rules, all keywords and testcases that call
    upon redfish functions (e.g. Redfish.Get, Redfish.Patch, etc.) have a right
    to expect that login/logout have already been handled.  Therefore, such
    keywords and testcases should NOT do logins and logouts themselves.
-   There may be exceptions to the above but they require justification (e.g. a
    test whose purpose is to verify that it can login with an **alternate**
    username, etc.).
-   Any keyword or test case which breaks the above rules is responsible for
    setting things right (i.e. back to a logged in state).

Rules for use of data/variables.py
==================================

Avoid defining variables in data/variables.py for Redfish URIs.

There's no obvious benefit to using such variables.  Conversely, with literal values,
it is much easier for the programmer to interpret the code.

Consider the following example.

Here's an excerpt from data/variables.py:

```
# Redfish variables.
REDFISH_BASE_URI = '/redfish/v1/'
...
REDFISH_ACCOUNTS = 'AccountService/Accounts/'
REDFISH_ACCOUNTS_URI = REDFISH_BASE_URI + REDFISH_ACCOUNTS
```

And here is a corresponding Robot code example:

```
    # Rather than coding this:
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}user_user

    # Code this:
    Redfish.Delete  /redfish/v1/AccountService/Accounts/user_user
```
