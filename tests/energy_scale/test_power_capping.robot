*** Settings ***
Documentation     Energy scale power capping tests.

Resource          ../../lib/energy_scale_utils.robot
Resource          ../../lib/rest_client.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/boot_utils.robot
Resource          ../../lib/ipmi_client.robot

Suite Setup      Suite Setup Execution
Test Teardown    Test Teardown Execution


*** Test Cases ***

Energy Scale Power Capping Tests
    [Documentation]  Run the power capping energy scale tests.
    [Tags]  Energy_Scale_Power_Capping_Tests

    Check OCC Data From OS

    Check Power Settings System On Then Off

    Check Power Settings System Off Then On

    Change Power Limit At Runtime

    Disable And Enable Power At Runtime



*** Keywords ***


Check OCC Data From OS
    [Documentation]  With system power on, check values with occtoolp9.
    ...  This test case is also known as RQM 71557 and RQM 71558.

    REST Power On  stack_mode=skip

    # Confirm power on.
    Is Power On

    OCC Tool Upload Setup

    # Get OCC data from OS.
    ${cmd}=  Set Variable  /tmp/occtoolp9 -p | grep -e State: -e Sensor:
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  print_out=${1}

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

    # 71558 - Deactivate and check limit with power on.
    Deactivate DCMI Power And Verify

    Set DCMI Power Limit And Verify  500


Check Power Settings System On Then Off
    [Documentation]  Set power activitation and limit when system
    ...  on, then check at power off.  This test case is also known
    ...  as RQM 71559.

    # Power on the system.
    REST Power On  stack_mode=skip

    Set DCMI Power Limit And Verify  800
    Deactivate DCMI Power And Verify

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${800}
    ...  msg=dcmi power limit not set to 800 as expected.

    # Power-off the OS
    Smart Power Off

    Activate DCMI Power And Verify

    REST Power On

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${800}
    ...  msg=Power limit setting of 800 watts not reatined at Runtime.

    Set DCMI Power Limit And Verify  0
    Deactivate DCMI Power And Verify


Check Power Settings System Off Then On
    [Documentation]  Set power activitation and limit when system
    ...  off, then check at power on.  This test case is also
    ...  known as RQM 71556.

    # Set power off.
    Smart Power Off

    # Check that DCMI power limiting is deactivated and that the initial
    # power limit setting = 0.
    Fail If DCMI Power Is Not Deactivated
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${0}
    ...  msg=Initial dcmi power limit should be zero.

    Activate DCMI Power And Verify
    Set DCMI Power Limit And Verify  500

    # Power-on the OS after setting the limit, and wait for OS ready.
    REST Power On

    Fail If DCMI Power Is Not Activated

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${500}
    ...  msg=Power limit setting not reatined at Runtime.


Change Power Limit At Runtime
    [Documentation]  Change power setting while at runtime.  This
    ...  test case is also known as RQM 71560.

    # System should be off for this test.
    Smart Power Off

    Set DCMI Power Limit And Verify  600
    Activate DCMI Power And Verify

    # Power on the system.
    REST Power On  stack_mode=skip

    # Check that DCMI power limit setting = 600.
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${600}
    ...  msg=DCMI power limit not set to 600 watts as expected.

    Set DCMI Power Limit And Verify  800


Disable And Enable Power At Runtime
    [Documentation]  Disable and enable power at runtime.  This
    ...  test case is also known as RQM 71561.

    # System should be off for this test.
    Smart Power Off

    Set DCMI Power Limit And Verify  500
    Activate DCMI Power And Verify

    # Power on the system.
    REST Power On

    # Check that DCMI power limit setting = 500.
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${500}
    ...  msg=DCMI power limit not set to 500 watts as expected.

    Deactivate DCMI Power And Verify

    Activate DCMI Power And Verify

    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${500}
    ...  msg=DCMI power limit not set to 500 watts as expected.


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

    FDC On Test Case Fail
    Smart Power Off
    Deactivate DCMI Power And Verify
    Set DCMI Power Limit And Verify  0
