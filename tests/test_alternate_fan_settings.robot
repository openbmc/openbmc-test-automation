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
Resource         ../lib/common_utils.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../syslib/utils_os.robot
Library          ../syslib/utils_keywords.py
Library          ../syslib/utils_os.py
Library          ../lib/gen_robot_valid.py

Test Setup       Open Connection And Log In
Suite Setup      REST Power On  stack_mode=skip
Test Teardown    FFDC On Test Case Fail


*** Variables ***

@{VALID_MODE_VALUES}   DEFAULT  CUSTOM


*** Test Cases ***

Verify Thermal Current Mode
    [Documentation]  Check current mode value.
    [Tags]  Verify_Thermal_Current_Mode

    # Example:
    #  /xyz/openbmc_project/control/thermal/0
    #
    # Response code:200, Content: {
    # "data": {
    #         "Current": "DEFAULT",
    #         "Supported": [
    #         "DEFAULT",
    #         "CUSTOM"
    #         },
    #         },
    # "message": "200 OK",
    # "status": "ok"
    # }

    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Rprint Vars  current

    Rvalid Value  current  valid_values=${VALID_MODE_VALUES}


Verify Supported Modes Available
    [Documentation]  Check supported modes available.
    [Tags]  Verify_Supported_Modes_Available

    ${supported}=  Read Attribute  ${CONTROL_URI}thermal/0  supported
    Rprint Vars  supported


Switch To Custom Mode If Available
    [Documentation]  Check if custom mode availabile and switch
    [Tags]  Switch_To_Custom_Mode_If_Available

    ${supported}=  Read Attribute  ${CONTROL_URI}thermal/0  supported

    :FOR  ${mode}  IN  @{supported}
    \  Should Match Regexp   ${mode}  [Custom]*

    ${value_dict}=  Create Dictionary  data=${mode}
    ${resp}=  OpenBMC Put Request
    ...  ${CONTROL_URI}thermal/0/attr/Current  data=${value_dict}

    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Rprint Vars  current

    Smart Power Off

    REST Power On  stack_mode=skip

    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  current
    Should Be Equal As Strings  ${current}  ${mode}
    Log To Console  Supported Mode: ${current} remained set after ReIPL.
