*** Settings ***
Documentation   OEM IPMI inband factory reset.

Resource        ../lib/resource.txt
Resource        ../lib/ipmi_client.robot
Resource        ../lib/boot_utils.robot
Library         ../lib/ipmi_utils.py


Test Teardown   FFDC On Test Case Fail
Test Setup      Delete All Error Logs

*** Test Cases ***

Test Inband IPMI Factory Reset
    [Documentation]  Trigger inband factory reset and verify.
    [Tags]  Test_Inband_IPMI_Factory_Reset

    REST Power On

    ${nw_info}=  Get Lan Print Dict
    Should Not Be Empty  ${nw_info}

    # Call reset method.
    Run Inband IPMI Raw Command  0x32 0x20

    # Reboot BMC.
    Run Inband IPMI Raw Command  0x06 0x03

    # Allow BMC to shutdown.
    Sleep  1 min

    # Check if BMC comes back online and IPMI host services are responding.
    Wait Until Keyword Succeeds  10 min  30 sec
    ...  Run Inband IPMI Raw Command  lan print

    Set BMC Netowrk From Host  ${nw_info}
