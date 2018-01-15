*** Settings ***
Documentation     Energy scale base tests.


# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.


Resource          ../lib/energy_scale_utils.robot
Resource          ../lib/openbmc_ffdc.robot


Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution



*** Variables ****

${over_max_power}       3051
${max_power}            3050
${mid_power}            1950
${min_power}            500
${below_min_power}      499
${zero_power}           0
${power_1450}           1450
${power_1700}           1700
${power_2200}           2200
#  The power limits are documented at
#  open-power/witherspoon-xml/master/witherspoon.xml.



*** Test Cases ***


Escale Base Test Inactive Monitoring
    [Documentation]  Run base power tests with DCMI power montoring off.
    [Tags]  Escale_Base_Test_Deactive_Monitoring

    Deactivate DCMI Power And Verify
    Verify Power Limits


Escale Base Test Active Monitoring
    [Documentation]  Run base power tests with DCMI power montoring on.
    [Tags]  Escale_Base_Test_Active_Monitoring

    Activate DCMI Power And Verify
    Verify Power Limits


Escale Base Test Using REST
    [Documentation]  Exercise Escale settings via REST
    [Tags]  Escale_Base_Test_Using_REST

    Set DCMI Power Limit Via REST  ${power_1700}
    ${power}=  Get DCMI Power Limit Via REST
    Should Be True  ${power} == ${power_1700}
    ...  msg=Readback of powercap via REST failed.

    Set DCMI Power Limit Via REST  ${power_1450}
    # read the power limit using non-REST
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_1450}
    ...  msg=Readback of powercap via DCMI after setting via REST failed.

    # Set DCMI Power via non-REST.
    Set DCMI Power Limit And Verify  ${power_2200}
    # Read the limit via REST.
    ${power_2200}=  Get DCMI Power Limit Via REST
    Should Be True  ${power_2200} == ${power_2200}
    ...  msg=Readback of powercap via REST after setting via DCMI failed.

    # Activate power monitoring via REST and check via REST and DCMI.
    Activate DCMI Power Via REST
    ${rest_activation}=  Get DCMI Power Acivation via REST
    Should Be True  ${rest_activation} == ${1}
    ...  msg=Readback of power monitoring activation failed via REST.
    # Confirm activation state using non-REST.
    Fail If DCMI Power Is Not Activated

    # Deactivate power monitoring via REST and check via REST and DCMI.
    Deactivate DCMI Power Via REST
    ${rest_activation}=  Get DCMI Power Acivation via REST
    Should Be True  ${rest_activation} == ${0}
    ...  msg=Readback of power monitoring activation failed via REST.
    # Confirm and activation state using non-REST.
    Fail If DCMI Power Is Not Deactivated


*** Keywords ***


Verify Power Limits
    [Documentation]  Set power levels and verify limits.

    Set DCMI Power Limit And Verify  ${mid_power}
    Test Power Limit  ${min_power}  ${below_min_power}
    Test Power Limit  ${min_power}  ${zero_power}
    Test Power Limit  ${max_power}  ${over_max_power}


Test Power Limit
    [Documentation]  Set power and check limit.
    [Arguments]  ${good_power}  ${outside_bounds_power}

    # Description of argument(s):
    # good_power              A valid power setting, usually at a limit.
    # outside_bounds_power    A power level that is beyond the limit.

    Set DCMI Power Limit And Verify  ${good_power}

    # Try to set out of bounds.
    ${expected_error}=  Set Variable
    ...  Failed setting dcmi power limit to ${outside_bounds_power} watts.
    Run Keyword and Expect Error  ${expected_error}
    ...  Set DCMI Power Limit And Verify  ${outside_bounds_power}


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    # Save the deactivation/activation setting.
    ${cmd}=  Catenate  dcmi power get_limit | grep State
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    # Response is either "Power Limit Active" or "No Active Power Limit".
    ${initial_deactivation}=  Get Count  ${resp}  No
    # If deactivated: initial_deactivation = 1, 0 otherwise.
    Set Suite Variable  ${initial_deactivation}  children=true

    # Save the power limit setting.
    ${initial_power_setting}=  Get DCMI Power Limit
    Set Suite Variable  ${initial_power_setting}  children=true


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

    # Restore the system's intial power limit setting.
    Run Keyword If  '${initial_power_setting}' != '${0}'
    ...  Set DCMI Power Limit And Verify  ${initial_power_setting}

    # Restore the system's intial deactivation/activation setting.
    Run Keyword If  '${initial_deactivation}' == '${1}'
    ...  Deactivate DCMI Power And Verify  ELSE  Activate DCMI Power And Verify
