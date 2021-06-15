*** Settings ***
Documentation    Test Redfish event service.

Resource         ../../../lib/resource.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/bmc_redfish_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Setup      Suite Setup Execution
Suite teardown   Run Keyword And Ignore Error  Delete All Redfish Sessions

***Variables***

${REMOTE_SERVER_IP}

** Test Cases **

Verify Event Service Available
    [Documentation]  Verify Redfish event service is available.
    [Tags]  Verify_Event_Service_Available

    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/EventService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}


Verify Subscribe An Event
    [Documentation]  Subscribe to an event and verify.
    [Tags]  Verify_Subscribe_An_Event

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    Should Be Empty  ${subscription_list}

    ${HttpHeaders_dict}=  Create Dictionary  Content=application/json
    ${HttpHeaders_list}=  Create List  ${HttpHeaders_dict}
    ${RegistryPrefixes_list}=  Create List  Base  OpenBMC  TaskEvent
    ${ResourceTypes_list}=  Create List  Task

    ${payload}=  Create Dictionary
    ...  Context=Test_Context  Destination=https://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
    ...  EventFormatType=Event  Protocol=Redfish  HttpHeaders=${HttpHeaders_list}
    ...  SubscriptionType=RedfishEvent  RegistryPrefixes=${RegistryPrefixes_list}
    ...  ResourceTypes=${ResourceTypes_list}

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    ${resp}=  redfish.Get  ${subscription_list[0]}

    Dictionary Should Contain Sub Dictionary   ${resp.dict}  ${payload}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not be Empty  ${REMOTE_SERVER_IP}
    Should Not be Empty  ${HTTPS_PORT}


Test Setup Execution
    [Documentation]  Do the test setup.

    Redfish.Login

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    Delete All Subscriptions  ${subscription_list}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Run Keyword And Ignore Error  Redfish.Logout


Delete All Subscriptions
    [Documentation]  Delete all subscriptions.
    [Arguments]   ${subscription_list}

    # Description of argument(s):
    # subscription_list   List of all subscriptions.

    FOR  ${url}  IN  @{subscription_list}
      Redfish.Delete  ${url}
    END

