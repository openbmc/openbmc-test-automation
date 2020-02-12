*** Settings ***

Documentation    Module to test IPMI SEL functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${CREATE_SEL_RAW_COMMAND}  0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x01 0x17 0x00 0xa0 0x04 0x07


*** Test Cases ***

Verify IPMI SEL Version
    [Documentation]  Verify IPMI SEL's version info.
    [Tags]  Verify_IPMI_SEL_Version
    ${version_info}=  Get IPMI SEL Setting  Version
    ${setting_status}=  Fetch From Left  ${version_info}  (
    ${setting_status}=  Evaluate  $setting_status.replace(' ','')

    Should Be True  ${setting_status} >= 1.5
    Should Contain  ${version_info}  v2 compliant  case_insensitive=True


Verify Empty SEL
    [Documentation]  Verify empty SEL list.
    [Tags]  Verify_Empty_SEL
    Run IPMI Standard Command  sel clear

    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify Add SEL Entry
    [Documentation]  Verify add SEL entry.
    [Tags]  Verify_add_SEL_entry

    Run IPMI Standard Command  sel clear
    Sleep  5s

    Create SEL
    #Get last SEL entry
    ${resp}=  Run IPMI Standard Command  sel elist last 1
    Should Not Contain Any  ${resp}  SEL has no entries  error
    ...  msg=Get SEL Entry failed.


*** Keywords ***

Create SEL
    [Documentation]  Create a SEL.

    #Create a SEL
    Run IPMI command  ${CREATE_SEL_RAW_COMMAND}
