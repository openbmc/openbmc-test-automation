*** Settings ***
Documentation  User management keywords.


*** Variables ***
${SETTING_WAIT_TIMEOUT}  30s


*** Keywords ***

Ensure User Exists
    [Documentation]  Create user if it doesn't exist.
    [Arguments]  ${username}  ${role}

    # Description of argument(s):
    # username  Username for the account.
    # role      User role (e.g. Administrator, ReadOnly).

    ${user_exists}=  Run Keyword And Return Status
    ...  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}

    IF  not ${user_exists}
        Redfish Create User  ${username}  ${OPENBMC_PASSWORD}  ${role}  ${True}
        # Verify creation succeeded.
        ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}
        Should Be Equal As Strings  ${resp.dict['Enabled']}  ${True}
        # Mark for cleanup.
        Set Test Variable  ${USER_CREATED_BY_TEST}  ${username}
    END


Set User Account State
    [Documentation]  Enable or disable a user account.
    [Arguments]  ${username}  ${enabled}

    # Description of argument(s):
    # username  Username for the account.
    # enabled   Boolean state to set (True=enabled, False=disabled).

    Redfish.Patch  /redfish/v1/AccountService/Accounts/${username}
    ...  body={'Enabled': ${enabled}}  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]
    Sleep  ${SETTING_WAIT_TIMEOUT}


Verify User State Via Redfish
    [Arguments]  ${username}  ${expected_enabled}

    # Description of argument(s):
    # username           Username for the account.
    # expected_enabled   Expected enabled state (True or False).

    ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}
    Should Be Equal As Strings  ${resp.dict['Enabled']}  ${expected_enabled}
