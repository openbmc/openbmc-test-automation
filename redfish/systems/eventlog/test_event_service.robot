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
@{Service_state}                ${False}  ${True}
@{Invalid_service_state}        FALSE  TRUE  1  0  on  off

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

Verify Subscriptions Defaults
    [Documentation]  Verify Subscriptions default property values.
    [Tags]  Verify_Subscriptions_Defaults

    ${subscriptions}=  Redfish.Get Properties  /redfish/v1/EventService/Subscriptions
    Rprint Vars  subscriptions
    ${subscriptions_count}=  Get Length  ${subscriptions['Members']}

    Valid Value  subscriptions['@odata.id']  ['/redfish/v1/EventService/Subscriptions/', '/redfish/v1/EventService/Subscriptions']
    Valid Value  subscriptions['Name']  ['Event Destination Collections']
    Valid Value  subscriptions['Members@odata.count']  [${subscriptions_count}]

Verify Event Service Enable And Disable Methods
    [Documentation]  Verify event service enable and disable methods.
    [Tags]  Verify_Event_Service_Enable_And_Disable_Methods
    [Setup]  Fetch Default Event Service State
    [Teardown]  Set Default Event Service State

    FOR  ${state}  IN  @{Service_state}
        # Patch operation to update service enabled state.
        ${payload}=  Create Dictionary  ServiceEnabled=${state}
        Redfish.Patch  /redfish/v1/EventService  body=${payload}  valid_status_codes=[${HTTP_OK}]

        # Check service enabled state changed.
        ${resp}=  Redfish.Get Properties  /redfish/v1/EventService  valid_status_codes=[${HTTP_OK}]
        ${after_policy}=  Get From Dictionary  ${resp}  ServiceEnabled
        Should Be Equal  ${after_policy}  ${state}
    END

Verify Invalid Data For Enable And Disable Event Service Methods
    [Documentation]  Verify invalid data for enable and disable event service methods.
    [Tags]  Verify_Invalid_Data_For_Enable_And_Disable_Event_Service_Methods
    [Setup]  Fetch Default Event Service State
    [Teardown]  Set Default Event Service State

    FOR  ${state}  IN  @{Invalid_service_state}
        # Patch operation to change the service enabled state.
        ${payload}=  Create Dictionary  ServiceEnabled=${state}
        Redfish.Patch  /redfish/v1/EventService  body=${payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]
    END

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

Verify Invalid Modify Subscriptions Details For Event Notification
    [Documentation]  Verify invalid modify subscriptions details for event notification.
    [Tags]  Verify_Invalid_Modify_Subscriptions_Details_For_Event_Notification

    Check And Create Subscription

    # Get the subscription list.
    ${instance}=  Redfish.Get Members List  ${REDFISH_BASE_URI}EventService/Subscriptions

    # Patch operation with empty body.
    ${payload}=  Create Dictionary
    Redfish.Patch  ${instance}[0]  body=${payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Patch operation with empty destination.
    ${payload}=  Create Dictionary  Destination=""
    Redfish.Patch  ${instance}[0]  body=&{payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]

    # Patch operation with empty resource types and registry prefixes.
    ${payload}=  Create Dictionary  resource_types=[]  registry_prefixes=[]
    Redfish.Patch  ${instance}[0]  body=&{payload}  valid_status_codes=[${HTTP_BAD_REQUEST}]


*** Keywords ***

Fetch Default Event Service State
    [Documentation]  Get the default state of the event service.

    ${resp}=  Redfish.Get Properties  /redfish/v1/EventService  valid_status_codes=[${HTTP_OK}]
    ${default_state}=  Get From Dictionary  ${resp}  ServiceEnabled
    Set Test Variable  ${default_state}

Set Default Event Service State
    [Documentation]  Set the event service to its default state.

    ${payload}=  Create Dictionary  ServiceEnabled=${default_state}
    Redfish.Patch  /redfish/v1/EventService  body=${payload}  valid_status_codes=[${HTTP_OK}]

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${REMOTE_SERVER_IP}
    Should Not Be Empty  ${HTTPS_PORT}

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

Check And Create Subscription
    [Documentation]  Check if subscription exists and create one if not.

    ${subscription_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/EventService/Subscriptions

    ${length}=  Get Length  ${subscription_list}

    Return From Keyword If  ${length} > 0

    Try Subscription Creation


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
