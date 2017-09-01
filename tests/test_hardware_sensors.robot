*** Settings ***
Documentation   Suite to test harware sensors.

Resource        ../lib/utils.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/openbmc_ffdc.robot

Suite Setup     Pre Test Suite Execution
Test Teardown   Post Test Case Execution

*** Test Cases ***

System Ambient Temperature
    [Documentation]  Check the ambient sensor temperature.
    [Tags]  System_Ambient_Temperature

    # Example:
    # /xyz/openbmc_project/sensors/temperature/ambient
    # {
    #     "Scale": -3,
    #     "Unit": "xyz.openbmc_project.Sensor.Value.Unit.DegreesC",
    #     "Value": 25767
    # }

    ${temp_data}=  Read Properties  ${SENSORS_URI}temperature/ambient
    Should Be True  ${temp_data["Scale"]} == ${-3}
    Should Be Equal As Strings
    ...  ${temp_data["Unit"]}  xyz.openbmc_project.Sensor.Value.Unit.DegreesC
    Should Be True  ${temp_data["Value"]/1000} <= ${50}
    ...  msg=System working temperature crossed 50 degree celsius.


*** Keywords ***

Pre Test Suite Execution
    [Documentation]  Do the initial test suite setup.
    # - Power off.
    # - Boot Host.
    Initiate Host PowerOff
    Initiate Host Boot

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    # - Capture FFDC on test failure.
    # - Delete error logs.
    # - Close all open SSH connections.

   FFDC On Test Case Fail
   Delete Error Logs
   Close All Connections

