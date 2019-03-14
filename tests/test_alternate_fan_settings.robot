*** Settings ***

Documentation  Fan checks.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
#
# Approximate run time:  15 seconds.

Resource         ../lib/state_manager.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/fan_utils.robot
Resource         ../lib/common_utils.robot
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Open Connection And Log In 
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify System is Air Cooled
    [Documentation]  Verify System is Air Cooled.
    [Tags]  Verify_System_Is_Air_Cooled

    # Determine if system is air cooled.
    ${air_cooled}=  Is Air Cooled

    Run Keyword If  ${air_cooled}  Log To Console  System is Air Cooled. Air Cooled=${air_cooled}
    Should Be True  ${air_cooled}  msg=Expecting system to be air cooled.

    ${power_state}=  Get Chassis Power State
    Verify Fan Monitors With State  ${power_state}

Check BMC Version
    [Documentation]  Returns BMC version from /etc/os-release

    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '=' 
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Log To Console  BMC version info = ${output}

OpenBMC Get Request
    [Documentation]  Check System Mode Values.
    [Tags]  Verify_System_Mode_Values
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

    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/control/thermal/0 
    Log To Console  ${resp}

Verify Current Mode
    [Documentation]  Check Current Mode Value.
    [Tags]  Verify_System_Mode_Current
    ${current}=  Read Attribute 
    ...  /xyz/openbmc_project/control/thermal/0  Current
    Log  Current:${current} 
    Log To Console  BMC current mode = ${current}


Verify Supported Mode Available
    [Documentation]  Check Supported Modes Available
    [Tags]  Verify_System_Mode_Available
    ${supported}=  Read Attribute
    ...  /xyz/openbmc_project/control/thermal/0  Supported
    Log  Supported:${supported}
    Log To Console  BMC supported mode = ${supported}
