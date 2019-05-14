*** Settings ***

Documentation  Test Suite for Suppported Fan Modules.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The username to login to the BMC.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
# OS_HOST            The OS host name or IP Address.
# OS_USERNAME        The OS login userid (usually root).
# OS_PASSWORD        The password for the OS login.

Resource         ../lib/state_manager.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/fan_utils.robot
Resource         ../lib/utils.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../syslib/utils_os.robot
Library          ../syslib/utils_keywords.py
Library          ../syslib/utils_os.py
Library          ../lib/gen_robot_valid.py

Test Setup       Open Connection And Log In
Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail
Suite Teardown   Suite Teardown Execution


*** Variables ***

@{VALID_MODE_VALUES}   DEFAULT  CUSTOM


*** Test Cases ***

Switch To Thermal Mode
    [Documentation]  Change thermal modes on the system.
    [Tags]  Switch_To_Thermal_Mode

    ${value_dict}=  Create Dictionary  data=CUSTOM 
    ${expected_value}=  Set Variable If  'CUSTOM' in ${supported}  CUSTOM  DEFAULT
    Write Attribute  ${CONTROL_URI}thermal/0  current  verify=${True} 
    ...  expected_value=${expected_value}  data=${value_dict}

    Pass Execution If  'CUSTOM' not in ${supported}  Custom mode not supported

    REST Power On  stack_mode=normal

    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Rprint Vars  current
    Should Be Equal As Strings  ${current}  CUSTOM
    ...  msg=Thermal mode setting was changed by reboot to the OS. 


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    REST Power On  stack_mode=skip

    ${supported}=  Read Attribute  ${CONTROL_URI}thermal/0  supported
    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Rprint Vars  supported  current

    Set Suite Variable  ${supported}
    Set Suite Variable  ${current}

Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    ${supported}=  Read Attribute  ${CONTROL_URI}thermal/0  supported
    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Rprint Vars  supported  current

    # If CUSTOM mode is not supported, no cleanup needed.
    Return From Keyword If  'CUSTOM' not in ${supported}

    # If DEFAULT mode currently set, no cleanup needed.
    Return From Keyword If  '${current}' == 'DEFAULT'

    # Restore the DEFAULT setting.
    ${value_dict}=  Create Dictionary  data=DEFAULT
    Write Attribute  ${CONTROL_URI}thermal/0  current  verify=${True}
    ...  data=${value_dict}

    # Reboot system required for change take effect.
    REST Power On  stack_mode=normal
