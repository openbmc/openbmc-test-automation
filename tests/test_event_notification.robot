*** Settings ***
Documentation  Event notification test cases

Resource        ../lib/resource.robot
Resource        ../lib/openbmc_ffdc.robot
Library         ../lib/eventNotification.py  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
#Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Subscribe To Event Notification
    [Documentation]  Subscribe to event notification to receive alerts.
    [Tags]  Subscribe_To_Event_Notification

    &{data}=  Create Dictionary  paths=/xyz/openbmc_project/sensors  interfaces=xyz.openbmc_project.Sensor.Value
    ${result}=  subscribe  ${data}
    Log To Console  \n${result}
    Should Contain  ${result}[0][path]  /xyz/openbmc_project/sensors
