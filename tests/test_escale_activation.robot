*** Settings ***
Documentation   Test the default value of power management enablement.

Resource        ../lib/openbmc_ffdc.robot

Test Teardown   Test Teardown Execution


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

    ${powercap}=  Read Attribute  ${CONTROL_HOST_URI}power_cap  PowerCapEnable
    Should Be True  ${powercap} == ${0}
    ...  msg=Default PowerCapEnable should be off.


*** Keywords ***


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
