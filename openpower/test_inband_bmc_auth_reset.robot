*** Settings ***
Documentation   OEM IPMI in-band BMC authentication reset.

# This resets the bmc authentication, specifically:
# 1. Enable local users if they were disabled.
# 2. Delete the LDAP configuration if there was one.
# 3. Reset the root password back to the default one.

Resource        ../lib/resource.txt
Resource        ../lib/ipmi_client.robot
Resource        ../lib/boot_utils.robot
Library         ../lib/ipmi_utils.py


Test Teardown   FFDC On Test Case Fail
Test Setup      Delete All Error Logs

*** Test Cases ***

Test Inband IPMI Auth Reset
    [Documentation]  Trigger inband BMC authentication reset and verify.
    [Tags]  Test_Inband_IPMI_Auth_Reset

    REST Power On  stack_mode=skip

    Run Keyword And Expect Error  *ConnectionError*  Initialize OpenBMC

    # Call reset method.
    Run Inband IPMI Raw Command  0x3a 0x11

    Initialize OpenBMC
