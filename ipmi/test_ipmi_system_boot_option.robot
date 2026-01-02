*** Settings ***

Documentation    Module to test IPMI System Boot Option functionality.
Resource         ../lib/ipmi_client.robot
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Teardown    Test Teardown Execution

Test Tags       IPMI_System_Boot_Options

*** Variables ***
&{BYTE_DESCRIPTION}    set_complete=0    set_in_progress=1

*** Test Cases ***

Verify Chassis System Boot Option To Set In Progress Status
    [Documentation]    Verify Chassis System Boot Option To Set In Progress Status
    [Tags]    Chassis_System_Boot_Options
    [Setup]    Get Default Chassis System Boot Options
    [Teardown]    Set Chassis System Boot Options

    FOR    ${status}    ${progress}    IN    &{BYTE_DESCRIPTION}
        ${data_hex}=    Convert To Hex    ${progress}    length=2

        # Set Chassis System Boot Options for set_complete and set_in_progress
        Set Chassis System Boot Options    set_argument= 0x${data_hex}

        # Check Chassis System Boot Option
        Check Chassis System Boot Option    expect= 01 00 ${data_hex}
    END


*** Keywords ***

Get Default Chassis System Boot Options
    [Documentation]    Get Default Chassis System Boot Options Value
    [Arguments]    ${default}=True

     ${resp}=  Run IPMI Command
     ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Options'][0]}

    IF    ${default}
        Set Suite Variable    ${DEFAULT_SET_IN_PROGRESS}    ${resp}
    ELSE
        RETURN    ${resp}
    END

Set Chassis System Boot Options
    [Documentation]    Set Chassis System Boot Options
    [Arguments]    ${set_argument}=${DEFAULT_SET_IN_PROGRESS}[1]

    ${ipmi_cmd}=  Catenate  ${IPMI_RAW_CMD['system_boot_options']['Set_Boot_Options'][0]}  ${set_argument}
    ${resp}=  Run IPMI Command  ${ipmi_cmd}

Check Chassis System Boot Option
    [Documentation]    Check Chassis System Boot Option Values
    [Arguments]    ${expect}

    ${resp}=  Run IPMI Command
     ...  ${IPMI_RAW_CMD['system_boot_options']['Get_Boot_Options'][0]}
    Should Be Equal As Strings    ${resp}    ${expect}