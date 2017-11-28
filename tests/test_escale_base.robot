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



*** Test Cases ***


Escale Base Test Inactive Monitoring
    [Documentation]  Run base power tests with DCMI power montoring off.
    [Tags]  Escale_Base_Test_Deactive_Monitoring

    Deactivate DCMI Power And Verify
    Run Power Setting Tests


Escale Base Test Active Monitoring
    [Documentation]  Run base power tests with DCMI power montoring on.
    [Tags]  Escale_Base_Test_Active_Monitoring

    Activate DCMI Power And Verify
    Run Power Setting Tests



*** Keywords ***


Run Power Setting Tests
    [Documentation]  Set power levels and verify limits.

    Set DCMI Power Limit And Verify  ${mid_power}
    Test Minimum Power  ${min_power}  ${below_min_power}
    Test Minimum Power  ${min_power}  ${zero_power}
    Test Maximum Power  ${max_power}  ${over_max_power}


Test Minimum Power
    [Documentation]  Set minimum power and check lower limit.
    [Arguments]  ${min_power}  ${below_min_power}

    # Description of argument(s):
    # min_power         The system's minimum allowable power setting.
    # below_min_power   A power level below min power.

    Set DCMI Power Limit And Verify  ${min_power}

    # Try to set lower.
    ${expected_error}=  Set Variable
    ...  Failed setting dcmi power limit to ${below_min_power} watts.
    Run Keyword and Expect Error  ${expected_error}
    ...  Set DCMI Power Limit And Verify  ${below_min_power}



Test Maximum Power
    [Documentation]  Set maximum power and check upper limit.
    [Arguments]  ${max_power}  ${over_max_power}

    # Description of argument(s):
    # max_power        The system's maximum allowable power setting.
    # over_max_power   A power level above max power.

    Set DCMI Power Limit And Verify  ${max_power}

    # Try to set higher.
    ${expected_error}=  Set Variable
    ...  Failed setting dcmi power limit to ${over_max_power} watts.
    Run Keyword and Expect Error  ${expected_error}
    ...  Set DCMI Power Limit And Verify  ${over_max_power}


Suite Setup Execution
    [Documentation]  Save the initial escale settings.

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
