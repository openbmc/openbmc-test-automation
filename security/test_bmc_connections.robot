*** Settings ***
Documentation  Connections and authentication module stability tests.

Resource  ../lib/bmc_redfish_resource.robot
Resource  ../lib/bmc_network_utils.robot
Resource  ../lib/openbmc_ffdc.robot
Resource  ../lib/resource.robot
Resource  ../lib/utils.robot
Resource  ../lib/connection_client.robot
Library   ../lib/bmc_network_utils.py

Library   SSHLibrary
Library   OperatingSystem
Library   Collections

*** Variables ***

${iterations}         10000
${hostname}           test_hostname
${MAX_UNAUTH_PER_IP}  ${5}

*** Test Cases ***

Test Patch Without Auth Token Fails
    [Documentation]  Send patch method without auth token and verify it throws an error.
    [Tags]   Test Patch Without Auth Token Fails

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}, ${HTTP_FORBIDDEN}]


Flood Patch Without Auth Token And Check Stability Of BMC
    [Documentation]  Flood patch method without auth token and check BMC stability.
    [Tags]  Flood_Patch_Without_Auth_Token_And_Check_Stability_Of_BMC
    @{status_list}=  Create List

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th iteration
        Run Keyword And Ignore Error
        ...  Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}

        # Every 100th iteration, check BMC allows patch with auth token.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Login And Configure Hostname
        Run Keyword If  ${status} == False  Append To List  ${status_list}  ${status}
    END
    ${verify_count}=  Evaluate  ${iterations}/100
    ${fail_count}=  Get Length  ${status_list}

    Should Be Equal  ${fail_count}  0  msg=Patch operation failed ${fail_count} times in ${verify_count} attempts


Verify Uer Cannot Login After 5 Non-Logged In Sessions
    [Documentation]  User should not be able to login when there
    ...  are 5 non-logged in sessions.
    [Tags]  Verify_User_Cannot_Login_After_5_Non-Logged_In_Sessions

    FOR  ${i}  IN RANGE  ${0}  ${MAX_UNAUTH_PER_IP}
       SSHLibrary.Open Connection  ${OPENBMC_HOST}
       Start Process  ssh ${OPENBMC_USERNAME}@${OPENBMC_HOST}  shell=True
    END

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Should Be Equal  ${status}  ${False}


*** Keywords ***

Login And Configure Hostname
    [Documentation]  Login and configure hostname

    [Teardown]  Redfish.Logout

    Redfish.Login

    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body={'HostName': '${hostname}'}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
