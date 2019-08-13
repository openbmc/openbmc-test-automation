*** Settings ***
Documentation  Event notification test cases

Resource        ../lib/resource.robot
Resource        ../lib/openbmc_ffdc.robot
Library         ../lib/event_notification.py  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Subscribe And Verify Event Notification
    [Documentation]  Subscribe and verify event notification.
    [Tags]  Subscribe_And_Verify_Event_Notification

    &{data}=  Create Dictionary  paths=/xyz/openbmc_project/sensors  interfaces=xyz.openbmc_project.Sensor.Value
    ${result}=  subscribe  ${data}
    Should Contain  ${result}[0][path]  /xyz/openbmc_project/sensors


