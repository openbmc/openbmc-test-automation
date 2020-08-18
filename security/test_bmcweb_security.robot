*** Settings ***
Documentation    Test bmc web vulnerability.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ***

${LOOP_COUNT}   4

*** Test Cases ***

Check BMCWeb Service After Attempted GET With Invalid URL
    [Documentation]  Request BMC GET with invalid URL.
    [Tags]  Check_BMCWeb_Service_After_Attempted_GET_With_Invalid_URL

    ${invalid_url}=  Set Variable   https://${OPENBMC_HOST}/'redfish\\['

    # Exhaust bmcweb restart policy by crashing 4 times in succession.
    Repeat Keyword  ${LOOP_COUNT} times  Run  ${curl_tool} -k ${invalid_url}

    # This should fail, if bmcweb is crashed.
    Redfish.Login

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test setup execution.

    ${cmd_tool}=  Run  which curl
    Should Contain  ${cmd_tool}  curl
    Set Test Variable  ${curl_tool}  ${cmd_tool}
