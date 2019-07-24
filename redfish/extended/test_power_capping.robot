*** Settings ***
Documentation     Energy scale power capping tests.


# Acronyms
#  PL     Power Limit
#  OCC    On Chip Controller


Resource          ../../lib/energy_scale_utils.robot
Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/ipmi_client.robot
Resource          ../../syslib/utils_os.robot


Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution



*** Variables ****

${max_power}            3050
${near_max_power_50}    3000
${near_max_power_100}   2950



*** Test Cases ***


Escale System On And PL Enabled
    [Documentation]  Change active power limit with system power on and
    ...  Power limit active.
    [Tags]  Escale_System_On_And_PL_Enabled

    Set DCMI Power Limit And Verify  ${max_power}

    REST Power On  stack_mode=skip

    Tool Exist  opal-prd
    OCC Tool Upload Setup

    # Get OCC data from OS.
    ${cmd}=  Set Variable  /tmp/occtoolp9 -p | grep -e State: -e Sensor:
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}

    # Check for expected responses.
    Should Contain  ${output}  ACTIVE
    Should Contain  ${output}  Sensor: TEMP
    Should Contain  ${output}  Sensor: FREQ
    Should Contain  ${output}  Sensor: POWR

    # Disable OCC.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  opal-prd occ disable
    # With OCC disabled we should have OBSERVATION in output.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Should Contain  ${output}  OBSERVATION

    # Re-enable OCC for remaining tests.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  opal-prd occ enable
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
    Should Contain  ${output}  ACTIVE

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${max_power}
    ...  msg=DCMI power limit should be ${max_power}.

    Activate DCMI Power And Verify

    Set DCMI Power Limit And Verify  ${near_max_power_50}


Escale System On And PL Disabled
    [Documentation]  Change active power limit with system power on and
    ...  deactivate power limit prior to change.
    [Tags]  Escale_System_On_And_PL_Disabled

    ${power_setting}=  Set Variable  ${near_max_power_100}

    REST Power On  stack_mode=skip

    Set DCMI Power Limit And Verify  ${power_setting}

    # Deactivate and check limit
    Deactivate DCMI Power And Verify

    ${cmd}=  Catenate  dcmi power set_limit limit ${near_max_power_50}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit

    Should Be True  ${power} == ${near_max_power_50}
    ...  msg=Could not set power limit when power limiting deactivated.


Escale Check Settings System On Then Off
    [Documentation]  Set power limit and activate power limit before
    ...  BMC state is power on.
    [Tags]  Escale_Check_Settings_System_On_Then_Off

    ${power_setting}=  Set Variable  ${near_max_power_100}

    REST Power On  stack_mode=skip

    Set DCMI Power Limit And Verify  ${power_setting}
    Deactivate DCMI Power And Verify

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=dcmi power limit not set to ${power_setting} as expected.

    Smart Power Off

    Activate DCMI Power And Verify

    REST Power On

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=Power limit setting of watts not retained at Runtime.

    Deactivate DCMI Power And Verify


Escale Check Settings System Off Then On
    [Documentation]  Set and activate power limit with system power off.
    [Tags]  Escale_Check_Settings_System_Off_Then_On

    ${power_setting}=  Set Variable  ${near_max_power_50}

    Set DCMI Power Limit And Verify  ${power_setting}
    Deactivate DCMI Power and Verify

    Smart Power Off

    # Check deactivated and the power limit.
    Fail If DCMI Power Is Not Deactivated
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=DCMI power not set at ${power_setting} as expected

    Activate DCMI Power And Verify
    Set DCMI Power Limit And Verify  ${power_setting}

    REST Power On

    Fail If DCMI Power Is Not Activated

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=Power limit setting not retained at Runtime.


Escale Change Limit At Runtime
    [Documentation]  Change power limit at runtime.
    [Tags]  Escale_Change_Limit_At_Runtime

    ${power_setting}=  Set Variable  ${near_max_power_100}

    Set DCMI Power Limit And Verify  ${near_max_power_50}

    Smart Power Off

    REST Power On  stack_mode=skip

    Set DCMI Power Limit And Verify  ${power_setting}

    # Check that DCMI power limit setting = ${power_setting}.
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=DCMI power limit not set to ${power_setting} watts as expected.

    Set DCMI Power Limit And Verify  ${max_power}


Escale Disable And Enable At Runtime
    [Documentation]  Disable/enable power limit at runtime.
    [Tags]  Escale_Disable_And_Enable_At_Runtime

    ${power_setting}=  Set Variable  ${near_max_power_50}

    Smart Power Off

    Set DCMI Power Limit And Verify  ${power_setting}
    Activate DCMI Power And Verify

    # Power on the system.
    REST Power On

    # Check that DCMI power limit setting = ${power_setting}.
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=DCMI power limit not set to ${power_setting} watts as expected.

    Deactivate DCMI Power And Verify

    Activate DCMI Power And Verify

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=DCMI power limit not set to ${power_setting} watts as expected.


*** Keywords ***


Suite Setup Execution
    [Documentation]  Do test setup initialization.
    #  Power Off if system if not already off.
    #  Save initial settings.
    #  Deactivate power and set limit.

    Smart Power Off

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

    # Set power limiting deactivated.
    Deactivate DCMI Power And Verify

    # Set initial power setting value.
    Set DCMI Power Limit And Verify  ${max_power}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # FFDC on test case fail.
    # Power off the OS and wait for power off state.
    # Return the system's initial deactivation/activation setting.
    # Return the system's initial power limit setting.

    FFDC On Test Case Fail

    Smart Power Off

    Run Keyword If  '${initial_power_setting}' != '${0}'
    ...  Set DCMI Power Limit And Verify  ${initial_power_setting}

    Run Keyword If  '${initial_deactivation}' == '${1}'
    ...  Deactivate DCMI Power And Verify  ELSE  Activate DCMI Power And Verify
