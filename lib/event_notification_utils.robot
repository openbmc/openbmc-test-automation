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

Get Destination IPs Of Event Subscriptions
    [Documentation]  Get all subscribed server IPs as a list from event subscriptions.

    ${subscription_ids}=  Get Event Subscription IDs

    ${server_ips}=  Create List
    FOR  ${id}  IN  @{subscription_ids}
        ${destination}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions/${id}  Destination
        # E.g. https://xx.xx.xx.xx:xxxx/redfish/events
        ${dest_ip}=  Get Regexp Matches  ${destination}  .*://(.*):.*  1
        ${server_ips}=  Combine Lists  ${server_ips}  ${dest_ip}
    END
    [Return]  ${server_ips}

Delete Event Subscription Of Unpingable Destination IPs
    [Documentation]  Delete a event subscription with non-pinging destination.

    ${subscription_ids}=  Get Event Subscription IDs

    FOR  ${id}  IN  @{subscription_ids}
        ${destination}=  Redfish.Get Attribute  /redfish/v1/EventService/Subscriptions/${id}  Destination
        ${dest_ip}=  Get Regexp Matches  ${destination}  .*://(.*):.*  1
        ${status}=  Run Keyword And Return Status  Ping Host  ${dest_ip}[0]

        IF  ${status} == False
            Redfish.Delete   /redfish/v1/EventService/Subscriptions/${id}
        END
    END
