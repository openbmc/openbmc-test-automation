*** Settings ***
Documentation   This suite is to run some test at the end of execution.

Resource        ../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

# Error strings to check from journald.
${ERROR_REGEX}     SEGV|core-dump|FAILURE|Failed to start


*** Test Cases ***

Verify No BMC Dump And Application Failures In BMC
    [Documentation]  Verify no BMC dump and application failure exists in BMC.
    [Tags]  Verify_No_BMC_Dump_And_Application_Failures_In_BMC

    # Check dump entry based on Redfish API availability.
    ${redfish_resp}=  OpenBMC Get Request  /redfish/v1/Systems/system/LogServices/Dump

    ${resp}=  Run Keyword If  '${redfish_resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  OpenBMC Get Request  /xyz/openbmc_project/dump/entry/list
    ...  ELSE  Redfish.Get Properties  /redfish/v1/Managers/bmc/LogServices/Dump/Entries

    Run Keyword If  '${redfish_resp.status_code}' == '${HTTP_NOT_FOUND}'
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  ELSE  Should Be Equal As Strings  ${resp["Members@odata.count"]}  0

    Check For Regex In Journald  ${ERROR_REGEX}  error_check=${0}  boot=-b
