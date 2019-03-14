*** Settings ***

Documentation  Test Suite for Suppported Fan Modules.

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
Resource        ../syslib/utils_os.robot
Library         ../syslib/utils_keywords.py
Library         ../syslib/utils_os.py

Test Setup       Open Connection And Log In
Suite Setup      Run Keyword  Start SOL Console Logging
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify System Is Powered On
    [Documentation]  Check System is Powered On.
    [Tags]  Verify_System_Is_Powered_On

    REST Power On  stack_mode=skip

    # Print output after Power On:
    ${resp}=  OpenBMC Get Request
    ...  ${CONTROL_URI}thermal/0
    Log To Console  ${resp}


Verify Thermal Current Mode
    [Documentation]  Check Current Mode Value.
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

    # Check Current Mode Here
    ${current}=  Read Attribute  ${CONTROL_URI}thermal/0  Current 
    Rprint Vars  Current

    Run Keyword If  '${current}' == 'DEFAULT'  Log To Console  System is set to '${current}' mode.

Verify Supported Mode Available
    [Documentation]  Check Supported Modes Available
    [Tags]  Verify_System_Mode_Available
    ${supported}=  Read Attribute
    ...  ${CONTROL_URI}thermal/0  Supported
    Rprint Vars  Supported

    # Checking for Default Supported Mode
    ${default}=  Get Variable Value  ${Supported[0]}  DEFAULT
    Run Keyword If  '${default}' == 'DEFAULT'  Log to Console  Default is available on this system.
    
    # Checking for Custom Supported Mode
    ${custom}=  Get Variable Value  ${Supported[1]}  CUSTOM
    Run Keyword If  '${custom}' == 'CUSTOM'  Log to Console  Custom is available on this system.
