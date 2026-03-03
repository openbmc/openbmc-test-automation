*** Settings ***
Documentation    Test Redfish event service subscription function.

Resource         ../../../lib/resource.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/bmc_redfish_utils.robot

Suite Setup      Suite Setup Execution
Suite teardown   Suite Teardown Execution

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Test Tags       Event_Service

*** Variables ***

# override this default using -v REMOTE_SERVER_IP:<IP> from CLI
${REMOTE_SERVER_IP}    10.7.7.7

** Test Cases **

Verify Add Subscribe Server For Event Notification
    [Documentation]  Subscribe a remote server and verify if added successful.
    [Tags]  Verify_Add_Subscribe_Server_For_Event_Notification

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    Should Be Empty  ${subscription_list}

    ${RegistryPrefixes_list}=  Create List  Base  OpenBMC  TaskEvent
    ${ResourceTypes_list}=  Create List  Task

    ${payload}=  Create Dictionary
    ...  Context=Test_Context  Destination=https://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
    ...  EventFormatType=Event  Protocol=Redfish  SubscriptionType=RedfishEvent
    ...  RegistryPrefixes=${RegistryPrefixes_list}  ResourceTypes=${ResourceTypes_list}

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    ${resp}=  redfish.Get  ${subscription_list[0]}

    Dictionary Should Contain Sub Dictionary   ${resp.dict}  ${payload}


Verify Invalid Subscriptions Details For Event Notification
    [Documentation]  Verify invalid subscriptions details for event notification.
    [Tags]  Verify_Invalid_Subscriptions_Details_For_Event_Notification

    # Post subscriptions with invalid format type value.
    ${payload}=    Create Dictionary    Context=Test_Context    Destination=https://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
    ...    Protocol=Redfish    EventFormatType=None    ResourceTypes=${ResourceTypes_list}
    ...    RegistryPrefixes=${RegistryPrefixes_list}    DeliveryRetryPolicy=SuspendRetries

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Post subscriptions with invalid protocol value.
    ${payload}=    Create Dictionary    Context=Test_Context    Destination=http_://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
    ...    EventFormatType=metricReport    Protocol=REDFISH    RegistryPrefixes=Syncagent    ResourceTypes=systems

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Post subscriptions with empty destination.
    ${payload}=    Create Dictionary    Context=Test_Context    Destination=""    EventFormatType=event    Protocol=redfish
    ...    RegistryPrefixes=eventLog    ResourceTypes=eventService

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]

Verify And Modify Subscriptions Details For Event Notification
    [Documentation]  Verify and modify subscriptions details for event notification.
    [Tags]  Verify_And_Modify_Subscriptions_Details_For_Event_Notification

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions
    Should Be Empty  ${subscription_list}

    # Create a new subscription.
    ${payload}=    Create Dictionary    Context=Test_Context    Destination=https://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
    ...    Protocol=Redfish    EventFormatType=Event    ResourceTypes=${ResourceTypes_list}    RegistryPrefixes=${RegistryPrefixes_list}
    ...    DeliveryRetryPolicy=SuspendRetries

    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Get the subscription list and check the default deliveryretrypolicy is SuspendRetries.
    ${instance}=    Redfish.Get Members List    ${REDFISH_BASE_URI}EventService/Subscriptions
    ${resp}=    Redfish.Get Properties    ${instance}[0]    valid_status_codes=[${HTTP_OK}]
    ${default_policy}=    Get From Dictionary    ${resp}    DeliveryRetryPolicy
    Should Be Equal    ${default_policy}    SuspendRetries

    # Patch operation to update deliveryretrypolicy.
    ${payload}=    Create Dictionary    DeliveryRetryPolicy=TerminateAfterRetries
    Redfish.Patch    ${instance}[0]    body=${payload}    valid_status_codes=[${HTTP_OK}]

    # Check subscriptions deliveryretrypolicy changed.
    ${resp}=    Redfish.Get Properties    ${instance}[0]    valid_status_codes=[${HTTP_OK}]
    ${after_policy}=    Get From Dictionary    ${resp}    DeliveryRetryPolicy
    Should Be Equal    ${after_policy}    TerminateAfterRetries

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not be Empty  ${REMOTE_SERVER_IP}
    Should Not be Empty  ${HTTPS_PORT}

    Redfish.Login


Suite Teardown Execution
    [Documentation]  Do the suite teardown.

    Run Keyword And Ignore Error  Delete All Redfish Sessions
    Run Keyword And Ignore Error  Redfish.Logout


Test Setup Execution
    [Documentation]  Do the test setup.

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    Delete All Subscriptions  ${subscription_list}

    # Verify Redfish event service attribute ServiceEnabled is set to True.
    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/EventService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    Delete All Subscriptions  ${subscription_list}


Delete All Subscriptions
    [Documentation]  Delete all subscriptions.
    [Arguments]   ${subscription_list}

    # Description of argument(s):
    # subscription_list   List of all subscriptions.

    FOR  ${url}  IN  @{subscription_list}
      Redfish.Delete  ${url}
    END

