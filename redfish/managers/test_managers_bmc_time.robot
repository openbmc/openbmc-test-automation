*** Settings ***
Documentation    Test BMC Manager time functionality.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/boot_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Variables ***
${ALLOWED_TIME_DIFF}  3

*** Test Cases ***

Verify Redfish BMC Time
    [Documentation]  Get BMC time from BMC manager.
    [Tags]  Verify_Redfish_BMC_Time

    ${redfish_date_time}=  Get BMC DateTime Using Redfish
    ${bmcdate}=  Get BMC Time Using Date Command
    ${time_diff}=  Subtract Date From Date  ${bmcdate}  ${redfish_date_time}
    ${time_diff}=  Convert To Number  ${time_diff}
    Should Be True  ${time_diff} < ${ALLOWED_TIME_DIFF}
    ...  Redfish BMC time does not match with BMC date command


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    redfish.Logout


Get BMC Time Using Date Command
    [Documentation]  Returns BMC time from date command

    ${bmc_time_via_date}  ${stderr}  ${rc}=  BMC Execute Command  date "+%m/%d/%Y %H:%M:%S"
    ${resp}=  Convert Date  ${bmc_time_via_date}  date_format=%m/%d/%Y %H:%M:%S
    ...  exclude_millis=yes
    Should Not Be Empty  ${resp}

    [Return]  ${resp}

Get BMC DateTime Using Redfish
    [Documentation]  Returns BMC Datetime value from Redfish

    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    [Return]  ${resp.dict["DateTime"]}
