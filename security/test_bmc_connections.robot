*** Settings ***
Documentation       Connections and authentication module stability tests.

Resource            ../lib/bmc_redfish_resource.robot
Resource            ../lib/bmc_network_utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/resource.robot
Resource            ../lib/utils.robot
Resource            ../lib/connection_client.robot
Resource            ../gui/lib/gui_resource.robot
Library             ../lib/bmc_network_utils.py
Library             SSHLibrary
Library             Collections
Library             XvfbRobot
Library             OperatingSystem
Library             SeleniumLibrary    120    120
Library             Telnet    30 Seconds
Library             Screenshot
Variables           ../gui/data/gui_variables.py

Suite Setup         Redfish.Logout

Test Tags           bmc_connections


*** Variables ***
${iterations}           10000
${loop_iteration}       ${1000}
${hostname}             testhostname
${MAX_UNAUTH_PER_IP}    ${5}
${bmc_url}              https://${OPENBMC_HOST}:${HTTPS_PORT}


*** Test Cases ***
Test Patch Without Auth Token Fails
    [Documentation]    Send patch method without auth token and verify it throws an error.
    [Tags]    test_patch_without_auth_token_fails

    ${active_channel_config}=    Get Active Channel Config
    ${ethernet_interface}=    Set Variable    ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    Redfish.Patch    ${REDFISH_NW_ETH_IFACE}${ethernet_interface}    body={'HostName': '${hostname}'}
    ...    valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]

Flood Patch Without Auth Token And Check Stability Of BMC
    [Documentation]    Flood patch method without auth token and check BMC stability.
    [Tags]    flood_patch_without_auth_token_and_check_stability_of_bmc

    @{fail_list}=    Create List

    ${active_channel_config}=    Get Active Channel Config
    ${ethernet_interface}=    Set Variable    ${active_channel_config['${CHANNEL_NUMBER}']['name']}

    FOR    ${iter}    IN RANGE    ${1}    ${iterations} + 1
        Log To Console    ${iter}th iteration Patch Request without valid session token
        # Expected valid fail status response code.
        Redfish.Patch    ${REDFISH_NW_ETH_IFACE}${ethernet_interface}    body={'HostName': '${hostname}'}
        ...    valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]

        # Every 100th iteration, check BMC allows patch with auth token.
        IF    ${iter} % 100 == 0
            ${status}=    Run Keyword And Return Status
            ...    Login And Configure Hostname
            ...    ${REDFISH_NW_ETH_IFACE}${ethernet_interface}
        ELSE
            ${status}=    Set Variable    ${None}
        END
        IF    ${status} == False    Append To List    ${fail_list}    ${iter}
    END
    ${verify_count}=    Evaluate    ${iterations}/100
    ${fail_count}=    Get Length    ${fail_list}

    Should Be Equal As Integers    ${fail_count}    ${0}
    ...    msg=Patch operation failed ${fail_count} times in ${verify_count} attempts; fails at iterations ${fail_list}

Verify User Cannot Login After 5 Non-Logged In Sessions
    [Documentation]    User should not be able to login when there
    ...    are 5 non-logged in sessions.
    [Tags]    verify_user_cannot_login_after_5_non-logged_in_sessions
    [Setup]    Confirm Ability to Connect Then Close All Connections

    FOR    ${iter}    IN RANGE    ${0}    ${MAX_UNAUTH_PER_IP}
        SSHLibrary.Open Connection    ${OPENBMC_HOST}
        Start Process    ssh ${OPENBMC_USERNAME}@${OPENBMC_HOST}    shell=True
    END

    SSHLibrary.Open Connection    ${OPENBMC_HOST}
    ${status}=    Run Keyword And Return Status    SSHLibrary.Login    ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}

    Should Be Equal    ${status}    ${False}
    [Teardown]    Run Keywords    Process.Terminate All Processes    AND
    ...    SSHLibrary.Close All Connections    AND    FFDC On Test Case Fail

Test Post Without Auth Token Fails
    [Documentation]    Send post method without auth token and verify it throws an error.
    [Tags]    test_post_without_auth_token_fails

    ${user_info}=    Create Dictionary
    ...    UserName=test_user    Password=TestPwd123    RoleId=Operator    Enabled=${True}
    Redfish.Post    /redfish/v1/AccountService/Accounts/    body=&{user_info}
    ...    valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]

Flood Post Without Auth Token And Check Stability Of BMC
    [Documentation]    Flood post method without auth token and check BMC stability.
    [Tags]    flood_post_without_auth_token_and_check_stability_of_bmc

    @{fail_list}=    Create List

    ${user_info}=    Create Dictionary
    ...    UserName=test_user    Password=TestPwd123    RoleId=Operator    Enabled=${True}

    FOR    ${iter}    IN RANGE    ${1}    ${iterations} + 1
        Log To Console    ${iter}th iteration Post Request without valid session token
        # Expected valid fail status response code.
        Redfish.Post    /redfish/v1/AccountService/Accounts/    body=&{user_info}
        ...    valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]

        # Every 100th iteration, check BMC allows post with auth token.
        IF    ${iter} % 100 == 0
            ${status}=    Run Keyword And Return Status    Login And Create User
        ELSE
            ${status}=    Set Variable    ${None}
        END
        IF    ${status} == False    Append To List    ${fail_list}    ${iter}
    END
    ${verify_count}=    Evaluate    ${iterations}/100
    ${fail_count}=    Get Length    ${fail_list}

    Should Be Equal As Integers    ${fail_count}    ${0}
    ...    msg=Post operation failed ${fail_count} times in ${verify_count} attempts; fails at iterations ${fail_list}

Make Large Number Of Wrong SSH Login Attempts And Check Stability
    [Documentation]    Check BMC stability with large number of SSH wrong login requests.
    [Tags]    make_large_number_of_wrong_ssh_login_attempts_and_check_stability
    [Setup]    Set Account Lockout Threshold

    SSHLibrary.Open Connection    ${OPENBMC_HOST}
    @{ssh_status_list}=    Create List
    FOR    ${iter}    IN RANGE    ${1}    ${loop_iteration} + 1
        Log To Console    ${iter}th iteration
        ${invalid_password}=    Catenate    ${OPENBMC_PASSWORD}${iter}
        Run Keyword and Ignore Error
        ...    Open Connection And Log In    ${OPENBMC_USERNAME}    ${invalid_password}

        # Every 100th iteration Login with correct credentials
        IF    ${iter} % ${100} == ${0}
            ${status}=    Run Keyword And Return Status
            ...    Open Connection And Log In
            ...    ${OPENBMC_USERNAME}
            ...    ${OPENBMC_PASSWORD}
        ELSE
            ${status}=    Set Variable    ${None}
        END
        IF    ${status} == ${False}
            Append To List    ${ssh_status_list}    ${status}
        END
        SSHLibrary.Close Connection
    END

    ${valid_login_count}=    Evaluate    ${iterations}/100
    ${fail_count}=    Get Length    ${ssh_status_list}
    Should Be Equal    ${fail_count}    ${0}
    ...    msg= Login Failed ${fail_count} times in ${valid_login_count} attempts.
    [Teardown]    FFDC On Test Case Fail

Test Stability On Large Number Of Wrong Login Attempts To GUI
    [Documentation]    Test stability on large number of wrong login attempts to GUI.
    [Tags]    test_stability_on_large_number_of_wrong_login_attempts_to_gui

    @{status_list}=    Create List

    # Open headless browser.
    Start Virtual Display
    ${browser_ID}=    Open Browser    ${bmc_url}    alias=browser1
    Set Window Size    1920    1080

    Go To    ${bmc_url}

    FOR    ${iter}    IN RANGE    ${1}    ${iterations} + 1
        Log To Console    ${iter}th login
        Run Keyword And Ignore Error    Login to GUI With Incorrect Credentials

        # Every 100th iteration, check BMC GUI is responsive.
        IF    ${iter} % 100 == 0
            ${status}=    Run Keyword And Return Status    Open Browser    ${bmc_url}
        ELSE
            ${status}=    Set Variable    ${None}
        END
        Append To List    ${status_list}    ${status}
        IF    '${status}' == 'True'
            Close Browser
            Switch Browser    browser1
        END
    END

    ${fail_count}=    Count Values In List    ${status_list}    False
    IF    ${fail_count} > ${0}
        FAIL    Could not open BMC GUI ${fail_count} times
    END

Test BMC GUI Stability On Continuous Refresh Of GUI Home Page
    [Documentation]    Login to BMC GUI and keep refreshing home page and verify stability
    ...    by login at times in another browser.
    [Tags]    test_bmc_gui_stability_on_continuous_refresh_of_gui_home_page

    @{failed_list}=    Create List

    # Open headless browser.
    Start Virtual Display
    ${browser_ID}=    Open Browser    ${bmc_url}    alias=browser1
    Set Window Size    1920    1080
    Login GUI

    FOR    ${iter}    IN RANGE    ${iterations}
        Log To Console    ${iter}th Refresh of home page

        Refresh GUI
        IF    ${iter}%100 != 0    CONTINUE

        # Every 100th iteration, check BMC GUI is responsive.
        ${status}=    Run Keyword And Return Status
        ...    Run Keywords    Launch Browser And Login GUI    AND    Logout GUI
        IF    '${status}' == 'False'
            Append To List    ${failed_list}    ${iter}
        ELSE IF    '${status}' == 'True'
            Close Browser
            Switch Browser    browser1
        END
    END
    Log    ${failed_list}
    ${fail_count}=    Get Length    ${failed_list}
    IF    ${fail_count} > ${0}
        FAIL    Could not open BMC GUI ${fail_count} times
    END
    [Teardown]    Close All Browsers

Test BMCweb Stability On Continuous Redfish Login Attempts With Invalid Credentials
    [Documentation]    Make invalid credentials Redfish login attempts continuously and
    ...    verify bmcweb stability by login to Redfish with valid credentials.
    [Tags]    test_bmcweb_stability_on_continuous_redfish_login_attempts_with_invalid_credentials

    Invalid Credentials Redfish Login Attempts

Test User Delete Operation Without Session Token And Expect Failure
    [Documentation]    Try to delete an object without valid session token and verifies it throws
    ...    an unauthorised error.
    [Tags]    test_user_delete_operation_without_session_token_and_expect_failure
    [Setup]    Redfish.Logout

    Redfish.Delete    /redfish/v1/AccountService/Accounts/test_user
    ...    valid_status_codes=[${HTTP_UNAUTHORIZED}]

Test Bmcweb Stability On Continuous Redfish Delete Operation Request Without Session Token
    [Documentation]    Send delete object request without valid session token continuously and
    ...    verify bmcweb stability by sending delete request with valid session token.
    [Tags]    test_bmcweb_stability_on_continuous_redfish_delete_operation_request_without_session_token

    @{failed_iter_list}=    Create List

    FOR    ${iter}    IN RANGE    ${iterations}
        Log To Console    ${iter}th Redfish Delete Object Request without valid session token

        Run Keyword And Ignore Error
        ...    Redfish.Delete    /redfish/v1/AccountService/Accounts/test_user
        IF    ${iter}%100 != 0    CONTINUE

        # Every 100th iteration, check delete operation with valid session token.
        ${status}=    Run Keyword And Return Status
        ...    Login And Delete User
        IF    '${status}' == 'False'
            Append To List    ${failed_iter_list}    ${iter}
        END
    END
    Log    ${failed_iter_list}
    ${fail_count}=    Get Length    ${failed_iter_list}
    IF    ${fail_count} > ${0}
        FAIL    Could not do Redfish delete operation ${fail_count} times
    END

Verify Flood Put Method Without Auth Token
    [Documentation]    Flood put method without auth token and check BMC stability.
    [Tags]    verify_flood_put_method_without_auth_token

    @{status_list}=    Create List

    FOR    ${iter}    IN RANGE    ${1}    ${iterations}
        Log To Console    ${iter}th iteration
        Run Keyword And Ignore Error
        ...    Redfish.Put    ${LED_LAMP_TEST_ASSERTED_URI}attr/Asserted    body={"data":1}
        # Every 100th iteration, check BMC allows put with auth token.
        IF    ${iter} % 100 == 0
            ${status}=    Run Keyword And Return Status    Login And Upload Partition File To BMC
        ELSE
            ${status}=    Set Variable    ${None}
        END
        IF    ${status} == ${False}
            Append To List    ${status_list}    ${status}
        END
    END

    # Note the count for every 100 iterations.
    ${verify_count}=    Evaluate    ${iterations}/100
    ${fail_count}=    Get Length    ${status_list}

    Should Be Equal    ${fail_count}    ${0}
    ...    msg=Put operation failed ${fail_count} times in ${verify_count} attempts.
    [Teardown]    Delete All BMC Partition File


*** Keywords ***
Login And Configure Hostname
    [Documentation]    Login and configure hostname
    [Arguments]    ${ethernet_interface_uri}

    # Description of argument(s):
    # ethernet_interface_uri    Network interface URI path.

    Redfish.Login

    Redfish.Patch    ${ethernet_interface_uri}    body={'HostName': '${hostname}'}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    [Teardown]    Redfish.Logout

Login And Create User
    [Documentation]    Login and create user

    Redfish.Login

    ${user_info}=    Create Dictionary
    ...    UserName=test_user    Password=TestPwd123    RoleId=ReadOnly    Enabled=${True}
    Redfish.Post    /redfish/v1/AccountService/Accounts/    body=&{user_info}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_CREATED}]
    [Teardown]    Run Keywords    Redfish.Delete    /redfish/v1/AccountService/Accounts/test_user
    ...    AND    Redfish.Logout

Login And Delete User
    [Documentation]    Login create and delete user

    Redfish.Login

    ${user_info}=    Create Dictionary
    ...    UserName=test_user    Password=TestPwd123    RoleId=ReadOnly    Enabled=${True}
    Redfish.Post    /redfish/v1/AccountService/Accounts/    body=&{user_info}
    ...    valid_status_codes=[${HTTP_OK}, ${HTTP_CREATED}]
    Redfish.Delete    /redfish/v1/AccountService/Accounts/test_user
    [Teardown]    Redfish.Logout

Set Account Lockout Threshold
    [Documentation]    Set user account lockout threshold.

    Redfish.Login
    Redfish.Patch    /redfish/v1/AccountService    body=[('AccountLockoutThreshold', 0)]
    [Teardown]    Redfish.Logout

Login to GUI With Incorrect Credentials
    [Documentation]    Attempt to login to GUI as root, providing incorrect password argument.

    Input Text    ${xpath_login_username_input}    root
    Input Password    ${xpath_login_password_input}    incorrect_password
    Click Button    ${xpath_login_button}

Invalid Credentials Redfish Login Attempts
    [Documentation]    Continuous invalid credentials login attempts to Redfish and
    ...    login to Redfish with valid credentials at times and get failed login attempts.
    [Arguments]    ${login_username}=${OPENBMC_USERNAME}    ${login_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # login_username    username for login user.
    # login_password    password for login user.

    @{failed_iter_list}=    Create List

    FOR    ${iter}    IN RANGE    ${iterations}
        Log To Console    ${iter}th Redfish login with invalid credentials
        Run Keyword And Ignore Error    Redfish.Login    ${login_username}    incorrect_password
        IF    ${iter}%100 != 0    CONTINUE

        # Every 100th iteration, check Redfish is responsive.
        ${status}=    Run Keyword And Return Status
        ...    Redfish.Login    ${login_username}    ${login_password}
        IF    '${status}' == 'False'
            Append To List    ${failed_iter_list}    ${iter}
        END
        Redfish.Logout
    END
    Log    ${failed_iter_list}
    ${fail_count}=    Get Length    ${failed_iter_list}
    IF    ${fail_count} > ${0}
        FAIL    Could not Login to Redfish ${fail_count} times
    END

Confirm Ability to Connect Then Close All Connections
    [Documentation]    Confirm that SSH login works, otherwise, skip this test.
    ...    If login succeeds, close all SSH connections to BMC to prepare for test.

    SSHLibrary.Close All Connections
    SSHLibrary.Open Connection    ${OPENBMC_HOST}
    ${status}=    Run Keyword And Return Status
    ...    SSHLibrary.Login    ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Skip If    ${status} == ${False}    msg= SSH Login failed: test will be skipped
    SSHLibrary.Close All Connections

Login And Upload Partition File To BMC
    [Documentation]    Upload partition file to BMC.

    Create Partition File
    Initialize OpenBMC

    # Get the content of the file and upload to BMC.
    ${image_data}=    OperatingSystem.Get Binary File    100-file
    ${headers}=    Create Dictionary    X-Auth-Token=${XAUTH_TOKEN}    Content-Type=application/octet-stream

    ${kwargs}=    Create Dictionary    data=${image_data}
    Set To Dictionary    ${kwargs}    headers    ${headers}
    ${resp}=    PUT On Session    openbmc    ${OEM_HOST_CONFIG_URI}/100-file    &{kwargs}    timeout=10
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    Delete Local Partition File

Delete Local Partition File
    [Documentation]    Delete local partition file.

    ${file_exist}=    Run Keyword And Return Status    OperatingSystem.File Should Exist    100-file
    IF    'True' == '${file_exist}'    Remove File    100-file

Create Partition File
    [Documentation]    Create Partition file.

    Delete Local Partition File

    @{words}=    Split String    100-file    -
    Run    dd if=/dev/zero of=100-file bs=${words}[-0] count=1
    OperatingSystem.File Should Exist    100-file

Delete All BMC Partition File
    [Documentation]    Delete multiple partition file on BMC via Redfish.

    Initialize OpenBMC
    ${data}=    Create Dictionary
    ${headers}=    Create Dictionary    X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary    ${data}    headers    ${headers}

    ${resp}=    POST On Session    openbmc    ${OEM_HOST_CONFIG_ACTIONS_URI}.DeleteAll    &{data}
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}

    Delete All Sessions
