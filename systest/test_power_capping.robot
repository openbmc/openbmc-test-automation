*** Settings ***
Documentation     Energy scale power capping tests.


# Acronyms
#  PL  Power Limit
#  OCC  On Chip Controller


Resource          ../lib/energy_scale_utils.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


*** Test Cases ***


Escale System On And PL Enabled
    [Documentation]  Change active power limit with system power on and
    ...  Power limit active.
    [Tags]  Escale_System_On_And_PL_Enabled

    REST Power On  stack_mode=skip

    OCC Tool Upload Setup

    # Get OCC data from OS.
    ${cmd}=  Set Variable  /tmp/occtoolp9 -p | grep -e State: -e Sensor:
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}

    # Check for expected responses.
    Should Contain  ${output}  ACTIVE
    Should Contain  ${output}  Sensor: TEMP
    Should Contain  ${output}  Sensor: FREQ
    Should Contain  ${output}  Sensor: POWR

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${0}
    ...  msg=Initial dcmi power limit should be zero.

    Activate DCMI Power And Verify

    Set DCMI Power Limit And Verify  300


Escale System On And PL Disabled
    [Documentation] Change active power limit with system power on and
    ...  deactivate power limit prior to change.
    [Tags]  Escale_System_On_And_PL_Disabled

    ${power_setting}=  Set Variable  ${600}

    REST Power On  stack_mode=skip

    Activate DCMI Power And Verify

    Set DCMI Power Limit And Verify  ${power_setting}

    # Deactivate and check limit
    Deactivate DCMI Power And Verify

    ${cmd}=  Catenate  dcmi power set_limit limit 500
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit

    Should Be True  ${power} == ${power_setting}
    ...  msg=Could set power limit when power limiting deactivated.


Escale Check Settings System On Then Off
    [Documentation]  Set power limit and activate power limit before
    ...  BMC state is power on.
    [Tags]  Escale_Check_Settings_System_On_Then_Off

    ${power_setting}=  Set Variable  ${800}

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

    Set DCMI Power Limit And Verify  0
    Deactivate DCMI Power And Verify


Escale Check Settings System Off Then On
    [Documentation]  Set and activate power limit with system power off.
    [Tags]  Escale_Check_Settings_System_Off_Then_On

    ${power_setting}=  Set Variable  ${500}

    Smart Power Off

    # Check that DCMI power limiting is deactivated and that the initial
    # power limit setting = 0.
    Fail If DCMI Power Is Not Deactivated
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${0}
    ...  msg=Initial dcmi power limit should be zero.

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

    ${power_setting}=  Set Variable  ${600}

    Smart Power Off

    Set DCMI Power Limit And Verify  ${power_setting}
    Activate DCMI Power And Verify

    REST Power On  stack_mode=skip

    # Check that DCMI power limit setting = ${power_setting}.
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_setting}
    ...  msg=DCMI power limit not set to ${power_setting} watts as expected.

    Set DCMI Power Limit And Verify  800


Escale Disable And Enable At Runtime
    [Documentation]  Disable/enable power limit at runtime.
    [Tags]  Escale_Disable_And_Enable_At_Runtime

    ${power_setting}=  Set Variable  ${500}

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
    #  Deactivate power and set limit = 0.
    Smart Power Off
    Deactivate DCMI Power And Verify
    Set DCMI Power Limit And Verify  0


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # FFDC on test case fail.
    # Power off the OS and wait for power off state.
    # Set deactivated DCMI power enablement and power limit = 0.

    FFDC On Test Case Fail
    Smart Power Off
    Deactivate DCMI Power And Verify
    Set DCMI Power Limit And Verify  0
