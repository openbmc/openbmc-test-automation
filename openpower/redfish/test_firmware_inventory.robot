*** Settings ***
Documentation    Verify that Redfish software inventory can be collected (OpenPower).

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/openpower_utils.robot
Library          ../../lib/gen_robot_valid.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Test Tags        OP_Firmware_Inventory

*** Test Cases ***

Verify Redfish BIOS Version
    [Documentation]  Get host firmware version from system inventory.
    [Tags]  Verify_Redfish_BIOS_Version

    ${bios_version}=  Redfish.Get Attribute  /redfish/v1/Systems/${SYSTEM_ID}/  BiosVersion
    ${pnor_version}=  Get PNOR Version
    Should Be Equal  ${pnor_version}  ${bios_version}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Redfish Power Off  stack_mode=skip


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
