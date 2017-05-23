*** Settings ***
Documentation  Update BMC MAC address with input MAC.

Resource  ../lib/utils.robot

*** Test Cases ***

Check And Reset MAC on BMC
    [Documentation]  Verify and Update BMC MAC address.
    
    Check And Reset MAC
