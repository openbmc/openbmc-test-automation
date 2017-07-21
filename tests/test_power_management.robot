*** Settings ***
Documentation     Power management test module.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
#Resource          ../lib/resource.txt

Suite Setup      Setup The Suite
Test Teardown    Post Test Case Execution

*** Variables ***


*** Test Cases ***

Verify Powercap Disabled By Default
    [Documentation]  Powercap is disabled by default.
    [Tags]  Verify_Powercap_Disabled_By_Default

    # Example:
    # /xyz/openbmc_project/control/host0/power_cap:
    # {
    #    "PowerCap": 0,
    #    "PowerCapEnable": 0
    # },

    ${powercap}=  Read Attribute  ${CONTROL_HOST_URI}power_cap  PowerCap
    Should Be Equal  ${powercap}  ${0}


***Keywords***

Setup The Suite
    [Documentation]  Do test setup initialization.

    # Reboot host to re-power on clean if host is not "off".
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot
    ...  ELSE  Initiate Host Reboot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting

    Delete Error Logs


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.

    FFDC On Test Case Fail
