*** Settings ***
Documentation   This suite is to perform sanity check for BMC.

Resource        ../lib/resource.robot
Resource        ../lib/bmc_redfish_resource.robot
Resource        ../lib/openbmc_ffdc.robot

Test Teardown   Test Teardown Execution

*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE|Failed to start|Found ordering cycle
${SKIP_ERROR}      ${EMPTY}


*** Test Cases ***

Verify No BMC Dump And Application Failures In BMC
    [Documentation]  Verify no BMC dump and application failure exists in BMC.
    [Tags]  Verify_No_BMC_Dump_And_Application_Failures_In_BMC

    # Check dump entry based on Redfish API availability.
    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/${MANAGER_ID}/LogServices/Dump/Entries
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    Log To Console  ${resp}

    Run Keyword If  '${resp.status}' == '${HTTP_OK}'
    ...  Should Be Equal As Strings  ${resp.dict["Members@odata.count"]}  0
    ...  msg=${resp.dict["Members@odata.count"]} dumps exist.

    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b  filter_string=${SKIP_ERROR}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Redfish Delete All BMC Dumps
    Redfish Delete All System Dumps
