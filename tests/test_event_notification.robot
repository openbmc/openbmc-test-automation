*** Settings ***
Documentation  Event notification test cases

Resource        ../lib/resource.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/rest_client.robot
Library         ../lib/gen_print.py
Library         Process
Library         OperatingSystem

Test Setup  Printn
#Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Subscribe And Verify Event Notification
    [Documentation]  Subscribe and verify event notification.
    [Tags]  Subscribe_And_Verify_Event_Notification

    # Subscribe to the dbus path
    &{dbus_path}=  Create Dictionary  paths=/xyz/openbmc_project/control/host0/power_cap
    ${result}=  Run Process  ${EXECDIR}/lib/event_notification.py  -H  ${OPENBMC_HOST}  -U  ${OPENBMC_USERNAME}  -P  ${OPENBMC_PASSWORD}  -D  ${dbus_path}  timeout=1  on_timeout=continue  stdout=event_output.txt

    # Get current reading
    Read Properties  ${CONTROL_HOST_URI}power_cap

    # Set power limit out of range.
    ${power_limit}=  Set Variable  1700
    ${int_power_limit}=  Convert To Integer  ${power_limit}
    ${data}=  Create Dictionary  data=${int_power_limit}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCap  data=${data}

    # Wait for output to be written into the file
    Sleep  5

    # Verify the output
    ${output}=  OperatingSystem.Get File  event_output.txt
    Should Contain  ${output}  PropertiesChanged
    Should Contain  ${output}  ${power_limit}
