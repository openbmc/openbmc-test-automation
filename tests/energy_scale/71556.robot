*** Settings ***
Documentation     Power management test module.

Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/ipmi_client.robot

Suite Setup      Setup The Suite
Test Teardown    Post Test Case Execution

*** Test Cases ***

Set And Activate Power Limit With System Power Off
    [Documentation]  Check power activitation and limit with system off.
    [Tags]  Set_And_Activate_Power_Limit_With_System_Power_Off

    # Check initial conditions.
    Is Power Off
    Is BMC Ready

    # Check that DCMI power limiting is deactivated and that the initial
    # power limit setting = 0.
    Is DCMI Power Deactivated
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${0}
    ...  msg=Initial dcmi power limit should be zero.

    Activate DCMI power
    Set DCMI Power Limit  500

    # Power-on the OS after setting the limit.
    # Wait for OS ready.
    REST Power On

    Is DCMI Power Activated

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${500}
    ...  msg=Power limit setting not reatined at Runtime.


*** Keywords ***

Get DCMI Power Limit
    [Documentation]  Get the current system DCMI power limit setting.
    # This keyword fetches the Power Limit out of the get_limit response.
    # For example, it returns 500 from the following:
    #  Current Limit State: No Active Power Limit
    #  Exception actions:   Hard Power Off & Log Event to SEL
    #  Power Limit:         500   Watts
    #  Correction time:     0 milliseconds
    #  Sampling period:     0 seconds
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Power Limit:
    ${resp_len}=  Get Length  ${resp}
    Should Be True  ${resp_len} > 0
    ...  msg=The power limit value was not returned by "dcmi power get_limit"
    ${watt_str}=  Remove String  ${resp}  Power Limit:  Watts
    ${pwr_limit}=  Convert To Integer  ${watt_str}
    [Return]  ${pwr_limit}


Set DCMI Power Limit
    [Documentation]  Set system power limit via DCMI.
    [Arguments]  ${limit}
    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${limit}
    ...  msg=Command failed: dcmi power set_limit limit ${limit}


Activate DCMI Power
    [Documentation]  Activate DCMI power power limiting.
    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    ${good_response}  Set Variable  successfully activated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power activate


Is DCMI Power Activated
    [Documentation]  Determins if DCMI power limiting is activated.
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  Power Limit Active
    Should Contain  ${resp}  ${good_response}  msg=DCMI power is not active


Is DCMI Power Deactivated
    [Documentation]  Determins if DCMI power limiting is deactivated.
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  No Active Power Limit
    Should Contain  ${resp}  ${good_response}
    ...  msg=DCMI power is not deactivated


Deactivate DCMI Power
    [Documentation]  Deactivate DCMI power power limiting.
    ${resp}=  Run External IPMI Standard Command  dcmi power deactivate
    ${good_response}  Set Variable  successfully deactivated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power deactivate


Setup The Suite
    [Documentation]  Do test setup initialization.
    #  Power Off if system is not already off.

    #REST Power Off  stack_mode=skip
    Smart Power Off


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # FFDC on test case fail.
    # Power off the OS and wait for power off state.
    # Set default deactivated DCMI power enablement.
    # Set default power limit = 0.

    ####FFDC On Test Case Fail
    Rest Power Off  stack_mode=skip
    Deactivate DCMI Power
    Set DCMI Power limit  0
