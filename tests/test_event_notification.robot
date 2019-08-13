*** Settings ***
Documentation  Event notification test cases

Resource        ../lib/resource.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/rest_client.robot
Library         Process
Library         OperatingSystem

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Subscribe And Verify Event Notification
    [Documentation]  Subscribe and verify event notification.
    [Tags]  Subscribe_And_Verify_Event_Notification

    # Subscribe to some REST path
    ${power_cap_uri}=  Create Dictionary  paths=${CONTROL_HOST_URI}power_cap
    ${result}=  Run Process  ${EXECDIR}/tools/event_notification.py
    ...  -H  ${OPENBMC_HOST}  -U  ${OPENBMC_USERNAME}
    ...  -P  ${OPENBMC_PASSWORD}  -D  ${power_cap_uri}  timeout=1
    ...  on_timeout=continue  stdout=event_output.txt

    # Get current reading
    Read Properties  ${CONTROL_HOST_URI}power_cap

    # Set power limit out of range.
    ${power_limit}=  Evaluate  random.randint(1000, 3000)  modules=random
    ${data}=  Create Dictionary  data=${power_limit}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCap  data=${data}

    # Wait for output to be written into the file
    Sleep  5

    # Verify event notification output
    ${output}=  OperatingSystem.Get File  event_output.txt
    Should Contain  ${output}  PropertiesChanged
    ${power_limit}=  Convert To String  ${power_limit}
    Should Contain  ${output}  ${power_limit}
    Should Contain  ${output}  PowerCap

