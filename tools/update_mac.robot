*** Settings ***
Documentation  Update BMC MAC address with input MAC.

Resource  ../lib/bmc_network_utils.robot

*** Test Cases ***

Check And Reset MAC on BMC
    [Documentation]  Verify and Update BMC MAC address.
    [Tags]  Check_And_Reset_MAC_on_BMC

    Check And Reset MAC
