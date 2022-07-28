*** Settings ***

Documentation    Resource file for event notification subscription.

*** Keywords ***

Delete All Event Subscriptions
    [Documentation]  Delete all event subscriptions.

    ${subscriptions}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions  Members
    Return From Keyword If  ${subscriptions} is None
    FOR  ${subscription}  IN  @{subscriptions}
        Redfish.Delete  ${subscription['@odata.id']}
    END

Get Event Subscription IDs
    [Documentation]  Get event subscription IDs.

    ${subscription_ids}=  Create List
    ${subscriptions}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions  Members
    Log  ${subscriptions}
    FOR  ${subscription}  IN  @{subscriptions}
        Append To List  ${subscription_ids}
        ...  ${subscription['@odata.id'].split("/redfish/v1/EventService/Subscriptions/")[-1]}
    END
    [Return]  ${subscription_ids}

