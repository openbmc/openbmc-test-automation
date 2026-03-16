*** Settings ***
Documentation    Redfish chassis power state aggregation for single and
...              multiple chassis systems.

Library          Collections
Library          String

*** Keywords ***

Redfish Get Chassis State
    [Documentation]  Return host power and health state.
    ...  Works for both single chassis and multi-chassis systems.
    ...  For single chassis: Returns PowerState and Status.State
    ...  For multi-chassis: Returns aggregated PowerState and Status.State
    ...
    ...  Refer: http://redfish.dmtf.org/schemas/v1/Resource.json#/definitions/Status
    ...
    ...  Example single chassis response:
    ...  "PowerState": "Off",
    ...  "Status": {
    ...     "Health": "OK",
    ...     "HealthRollup": "OK",
    ...     "State": "StandbyOffline"
    ...  }

    # Check if CHASSIS_ID is set (variable or environment variable) and not empty
    ${chassis_id_exists}=  Run Keyword And Return Status
    ...  Variable Should Exist  ${CHASSIS_ID}

    ${chassis_id_valid}=  Set Variable  ${False}
    IF  ${chassis_id_exists}
        ${chassis_id_valid}=  Evaluate  '${CHASSIS_ID}' != '${EMPTY}'
    END

    # Get chassis collection to determine if single or multi-chassis system
    ${chassis_response}=  Redfish.Get Properties  /redfish/v1/Chassis

    # Get the count of chassis members
    ${chassis_count}=  Get Length  ${chassis_response['Members']}

    # Branch based on CHASSIS_ID validity and chassis count
    # If CHASSIS_ID is set and not empty AND chassis count is 1,
    # use single chassis logic
    IF  ${chassis_id_valid} and ${chassis_count} == 1
        ${power_state}  ${status_state}=  Get Single Chassis State
        RETURN  ${power_state}  ${status_state}
    ELSE
        ${aggregated_power}  ${aggregated_status}=  Get Aggregated Chassis State
        RETURN  ${aggregated_power}  ${aggregated_status}
    END

Get Single Chassis State
    [Documentation]  Get power state for single chassis system.

    Log To Console  /redfish/v1/Chassis/${CHASSIS_ID}
    ${chassis}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Properties  /redfish/v1/Chassis/${CHASSIS_ID}

    ${power_state}=  Set Variable  ${chassis["PowerState"]}
    ${status_state}=  Set Variable  ${chassis["Status"]["State"]}

    Log To Console  Single Chassis - PowerState: ${power_state}, Status->State: ${status_state}

    RETURN  ${power_state}  ${status_state}

Get Aggregated Chassis State
    [Documentation]  Get aggregated power state for multi-chassis system.
    ...  Returns the overall system power state based on all chassis.

    # Get the chassis collection
    ${collection}=  Redfish.Get Properties  /redfish/v1/Chassis

    # Extract chassis members and count
    ${members}=  Set Variable  ${collection["Members"]}
    ${count}=  Set Variable  ${collection["Members@odata.count"]}

    Log To Console  Found ${count} chassis in the system

    # Filter chassis members to only include those matching CHASSIS_ID pattern
    ${filtered_chassis_list}=  Filter Chassis Members  ${members}  ${CHASSIS_ID}
    ${filtered_count}=  Get Length  ${filtered_chassis_list}

    Log  Filtered to ${filtered_count} chassis matching pattern '${CHASSIS_ID}'

    # If no chassis match the pattern, fall back to all chassis
    ${chassis_to_query}=  Set Variable If  ${filtered_count} > 0
    ...  ${filtered_chassis_list}
    ...  ${members}

    # Query each chassis and collect power states
    ${power_states}=  Create List
    ${status_states}=  Create List
    ${chassis_uris}=  Create List

    FOR  ${member}  IN  @{chassis_to_query}
        ${chassis_uri}=  Set Variable  ${member["@odata.id"]}
        Log To Console  Querying chassis: ${chassis_uri}

        ${chassis_data}=  Wait Until Keyword Succeeds  1 min  20 sec
        ...  Redfish.Get Properties  ${chassis_uri}

        ${power_state}=  Set Variable  ${chassis_data["PowerState"]}
        ${status_state}=  Set Variable  ${chassis_data["Status"]["State"]}

        Append To List  ${power_states}  ${power_state}
        Append To List  ${status_states}  ${status_state}
        Append To List  ${chassis_uris}  ${chassis_uri}

        Log To Console  Chassis ${chassis_uri}: PowerState=${power_state}, Status->State=${status_state}
    END

    # Aggregate the power states
    ${aggregated_power}=  Aggregate Power States  ${power_states}  ${chassis_uris}
    ${aggregated_status}=  Aggregate Status States  ${status_states}

    Log To Console  Aggregated Result - PowerState: ${aggregated_power}, Status->State: ${aggregated_status}

    RETURN  ${aggregated_power}  ${aggregated_status}

Filter Chassis Members
    [Documentation]  Filter chassis members to only include those matching the CHASSIS_ID pattern.
    [Arguments]  ${members}  ${chassis_id_pattern}

    ${filtered_list}=  Create List

    FOR  ${member}  IN  @{members}
        ${uri}=  Set Variable  ${member["@odata.id"]}
        # Extract the chassis ID from the URI (e.g., /redfish/v1/Chassis/chassis0 -> chassis0)
        ${chassis_name}=  Fetch From Right  ${uri}  /

        # Check if chassis name starts with the pattern
        ${matches}=  Run Keyword And Return Status
        ...  Should Start With  ${chassis_name}  ${chassis_id_pattern}

        IF  ${matches}
        ...  Append To List  ${filtered_list}  ${member}
    END

    RETURN  ${filtered_list}

Aggregate Power States
    [Documentation]  Aggregate multiple chassis power states into overall system state.
    ...  Logic: ALL chassis must be "On" for system to be "On"
    ...         If ANY chassis is not "On", system is "Off"
    ...         Logs which chassis are not in "On" state
    [Arguments]  ${power_states}  ${chassis_uris}

    # Count occurrences of each state
    ${on_count}=  Count Values In List  ${power_states}  On
    ${total}=  Get Length  ${power_states}

    # Check if all chassis are On. True if On else False
    ${all_on}=  Evaluate  ${on_count} == ${total}

    # If not all On, log which chassis are Off
    IF  not ${all_on}
      Log Chassis Not On  ${power_states}  ${chassis_uris}
    END

    # Aggregation logic: ALL must be On for system to be On
    ${aggregated}=  Set Variable If  ${all_on}  On  Off

    Log To Console  Power State Aggregation: ${on_count}/${total} System: ${aggregated}

    RETURN  ${aggregated}

Log Chassis Not On
    [Documentation]  Log which chassis are not in "On" state.
    [Arguments]  ${power_states}  ${chassis_uris}

    ${index}=  Set Variable  ${0}

    FOR  ${power_state}  IN  @{power_states}
        ${chassis_uri}=  Get From List  ${chassis_uris}  ${index}

        IF  '${power_state}' != 'On'
        ...  Log To Console  WARNING: Chassis ${chassis_uri} PowerState is '${power_state}' (not On)  WARN

        ${index}=  Evaluate  ${index} + 1
    END

Aggregate Status States
    [Documentation]  Aggregate multiple chassis status states into overall system state.
    ...  Logic: If any chassis is "Enabled", system is "Enabled"
    ...         If all chassis are "StandbyOffline", system is "StandbyOffline"
    ...         Otherwise, use the most common state
    [Arguments]  ${status_states}

    # Count occurrences of each state
    ${enabled_count}=  Count Values In List  ${status_states}  Enabled
    ${standby_count}=  Count Values In List  ${status_states}  StandbyOffline
    ${total}=  Get Length  ${status_states}

    # Aggregation logic
    ${aggregated}=  Set Variable If
    ...  ${enabled_count} > 0  Enabled
    ...  ${standby_count} == ${total}  StandbyOffline
    ...  ${status_states}[0]

    Log  Status State Aggregation: ${enabled_count} Enabled, ${standby_count} StandbyOffline -> ${aggregated}

    RETURN  ${aggregated}

Get Chassis Count
    [Documentation]  Return the total number of chassis in the system.

    ${collection}=  Redfish.Get Properties  /redfish/v1/Chassis
    ${count}=  Set Variable  ${collection["Members@odata.count"]}

    Log To Console  Total chassis count: ${count}

    RETURN  ${count}

Get Chassis List
    [Documentation]  Return list of all chassis URIs in the system.

    ${collection}=  Redfish.Get Properties  /redfish/v1/Chassis
    ${members}=  Set Variable  ${collection["Members"]}

    ${chassis_uris}=  Create List

    FOR  ${member}  IN  @{members}
        ${uri}=  Set Variable  ${member["@odata.id"]}
        Append To List  ${chassis_uris}  ${uri}
    END

    Log To Console  Chassis URIs: ${chassis_uris}

    RETURN  ${chassis_uris}

Get Filtered Chassis List
    [Documentation]  Return list of chassis URIs matching the CHASSIS_ID pattern.
    [Arguments]  ${chassis_id_pattern}=${CHASSIS_ID}

    # Description of argument(s):
    # chassis_id_pattern   Chassis string pattern (Ex. chassis, xyz)

    ${collection}=  Redfish.Get Properties  /redfish/v1/Chassis
    ${members}=  Set Variable  ${collection["Members"]}

    ${filtered_members}=  Filter Chassis Members  ${members}  ${chassis_id_pattern}
    ${chassis_uris}=  Create List

    FOR  ${member}  IN  @{filtered_members}
        ${uri}=  Set Variable  ${member["@odata.id"]}
        Append To List  ${chassis_uris}  ${uri}
    END

    Log  Filtered Chassis URIs (pattern: ${chassis_id_pattern}): ${chassis_uris}

    RETURN  ${chassis_uris}
