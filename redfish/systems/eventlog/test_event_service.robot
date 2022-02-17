*** Settings ***
Documentation    Test Redfish event service subscription function.

Resource         ../../../lib/resource.robot
Resource         ../../../lib/bmc_redfish_resource.robot
Resource         ../../../lib/openbmc_ffdc.robot
Resource         ../../../lib/bmc_redfish_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution
Suite Setup      Suite Setup Execution
Suite teardown   Run Keyword And Ignore Error  Delete All Redfish Sessions

***Variables***

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

    # Verify Redfish event service attribute ServiceEnabled is set to True.
    ${resp} =  Redfish_utils.Get Attribute  /redfish/v1/EventService  ServiceEnabled
    Should Be Equal As Strings  ${resp}  ${True}


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

