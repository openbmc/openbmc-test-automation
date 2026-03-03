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
${REMOTE_SERVER_IP}             10.7.7.7
@{RegistryPrefixes_list}        Base  OpenBMC  TaskEvent
@{ResourceTypes_list}           Task
${Maximum_subscription_count}   20

** Test Cases **

Verify Add Subscribe Server For Event Notification
    [Documentation]  Subscribe a remote server and verify if added successful.
    [Tags]  Verify_Add_Subscribe_Server_For_Event_Notification

    # Create valid subscription.
    Try Subscription Creation

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    ${resp}=  redfish.Get  ${subscription_list[0]}

    Dictionary Should Contain Sub Dictionary   ${resp.dict}  ${payload}

Verify Maximum Subscriptions For Event Notification
    [Documentation]  Verify maximum subscriptions for event notification.
    [Tags]  Verify_Maximum_Subscriptions_For_Event_Notification

    # Create valid subscription.
    Try Subscription Creation

    # Create maximum subscriptions.
    FOR  ${i}  IN RANGE  1  20
        Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
        ...  valid_status_codes=[${HTTP_CREATED}]
    END

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    # Verify the subscription count is 20.
    ${subscription_list_count}=  Get Length  ${subscription_list}
    Should Be Equal As Integers   ${subscription_list_count}  ${Maximum_subscription_count}

    # Create one more subscription which exceeds the maximum subscription count.
    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...   valid_status_codes=[${HTTP_SERVICE_UNAVAILABLE}]

    # Delete a specific subscription to free up space for a new one.
    Delete Specific Subscription

    # Create a new subscription again which should be successful now.
    Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
        ...  valid_status_codes=[${HTTP_CREATED}]

Verify Event Service Collection Unsupported Methods
    [Documentation]  Verify event service collection with unsupported methods.
    [Tags]  Verify_Event_Service_Collection_Unsupported_Methods

    # Put operation on event service collection.
    Redfish.Put  /redfish/v1/EventService
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Post operation on event service collection.
    Redfish.Post  /redfish/v1/EventService
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Delete operation on event service collection.
    Redfish.Delete  /redfish/v1/EventService
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]


Verify Invalid Subscriptions Details For Event Notification
    [Documentation]  Verify invalid subscriptions details for event notification.
    [Tags]  Verify_Invalid_Subscriptions_Details_For_Event_Notification

    # Create invalid subscription for eventformatType.
    Try Subscription Creation  EventFormatType=None  Valid_status_codes=${HTTP_BAD_REQUEST}

    # Create invalid subscription for protocol.
    Try Subscription Creation  Protocol=REDFISH  Valid_status_codes=${HTTP_BAD_REQUEST}

    # Create invalid subscription for destination.
    Try Subscription Creation  Destination=${EMPTY}  Valid_status_codes=${HTTP_BAD_REQUEST}

Verify And Modify Subscriptions Details For Event Notification
    [Documentation]  Verify and modify subscriptions details for event notification.
    [Tags]  Verify_And_Modify_Subscriptions_Details_For_Event_Notification

    # Create valid subscription.
    Try Subscription Creation

    # Get the subscription list and check the default deliveryretrypolicy is SuspendRetries.
    ${instance}=  Redfish.Get Members List  ${REDFISH_BASE_URI}EventService/Subscriptions
    ${resp}=  Redfish.Get Properties  ${instance}[0]  valid_status_codes=[${HTTP_OK}]
    ${default_policy}=  Get From Dictionary  ${resp}  DeliveryRetryPolicy
    Should Be Equal  ${default_policy}  SuspendRetries

    # Patch operation to update deliveryretrypolicy.
    ${payload}=  Create Dictionary  DeliveryRetryPolicy=TerminateAfterRetries
    Redfish.Patch  ${instance}[0]  body=${payload}  valid_status_codes=[${HTTP_OK}]

    # Check subscriptions deliveryretrypolicy changed.
    ${resp}=  Redfish.Get Properties  ${instance}[0]  valid_status_codes=[${HTTP_OK}]
    ${after_policy}=  Get From Dictionary  ${resp}  DeliveryRetryPolicy
    Should Be Equal  ${after_policy}  TerminateAfterRetries

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

Delete Specific Subscription
    [Documentation]    Delete specific subscription.

    ${subscription_instance}=    Redfish.Get Members List  /redfish/v1/EventService/Subscriptions
    Redfish.Delete    ${subscription_instance}[0]
    ...    valid_status_codes=[${${HTTP_OK}}, ${HTTP_NO_CONTENT}]

Try Subscription Creation
     [Documentation]  Create valid or invalid subscription for event notification.
     [Arguments]  ${Context}=Test_Context  ${Destination}=https://${REMOTE_SERVER_IP}:${HTTPS_PORT}/
     ...    ${EventFormatType}=Event  ${Protocol}=Redfish  ${SubscriptionType}=RedfishEvent
     ...    ${RegistryPrefixes}=${RegistryPrefixes_list}
     ...    ${ResourceTypes}=${ResourceTypes_list}  ${DeliveryRetryPolicy}=SuspendRetries
     ...    ${Valid_status_codes}=${HTTP_CREATED}

     # Description of argument(s):
     # Context              The context of the subscription.
     # Destination          The destination URL for the subscription (e.g. https://XX.XX.XX.XX:443/).
     # EventFormatType      The format type of the event (e.g. Event).
     # Protocol             The protocol used for the subscription (e.g. Redfish).
     # SubscriptionType     The type of the subscription (e.g. RedfishEvent).
     # RegistryPrefixes     The registry prefixes for the subscription (e.g. ["Base", "Event"]).
     # ResourceTypes        The resource types for the subscription (e.g. ["ComputerSystem", "Chassis"]).
     # DeliveryRetryPolicy  The delivery retry policy for the subscription (e.g. SuspendRetries).
     # Valid_status_codes   The valid status codes for the subscription (e.g. [201, 400]).

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions
    Should Be Empty  ${subscription_list}

     ${payload}=  Create Dictionary  Context=${Context}  Destination=${Destination}
     ...    EventFormatType=${EventFormatType}  Protocol=${Protocol}  RegistryPrefixes=${RegistryPrefixes}
     ...    ResourceTypes=${ResourceTypes}  DeliveryRetryPolicy=${DeliveryRetryPolicy}

     Set Test Variable  ${payload}

     Redfish.Post  /redfish/v1/EventService/Subscriptions  body=&{payload}
    ...  valid_status_codes=[${Valid_status_codes}]