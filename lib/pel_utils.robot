*** Settings ***
Documentation    PEL utility keywords.

Resource         logging_utils.robot

*** Variables ***


*** Keywords ***

Verify PEL And Redfish Event Log Are Same
    [Documentation]  Verify PEL log attributes like "SRC", "Created at" are same as
     ...  Redfish event log attributes like "EventId", "Created".

    # PEL Log attributes

    # SRC        : XXXXXXXX
    # Created at : 11/14/2022 12:38:04

    # Event log attributes

    # EventId : XXXXXXXX XXXXXXXX XXXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX XXXXXXXX
    # Created : 2022-11-14T12:38:04+00:00

    # Below temp_event_records dictionary contains all the events where key is "odata.id"
    # and value is event instance.
    #
    # Below is sample for temp_event_records with limited information.
    #
    # /redfish/v1/Systems/system/LogServices/EventLog/Entries/1
    # ['@odata.id'] : /redfish/v1/Systems/system/LogServices/EventLog/Entries/1
    # ['@odata.type'] : Type value
    # ['Id'] : 1
    #
    # /redfish/v1/Systems/system/LogServices/EventLog/Entries/2
    # ['@odata.id'] : /redfish/v1/Systems/system/LogServices/EventLog/Entries/2
    # ['@odata.type'] : Type value
    # ['Id'] : 2

    ${temp_event_records}=  Get Redfish Event Logs

    # Below temp_event_records dictionary is rearranged, where key is Id and value is event instance.

    ${event_records}=  Create Dictionary
    FOR  ${key}  IN  @{temp_event_records.keys()}
      Set To Dictionary  ${event_records}  ${temp_event_records['${key}']['Id']}=${temp_event_records['${key}']}
    END

    ${event_record_length}=  Get Length  ${event_records}

    # Below temp_pel_records dictionary contains PEL detail informaton, where key is PEL id,
    # value is PEL instance plus PEL information data.

    # Python module: pel_utils
    ${temp_pel_records}=  pel_utils.Get PEL Detail Information
    Log  ${temp_pel_records}

    # Below temp_pel_records dictionary is rearranged, where key will be nested key that is "BMC Event Log Id"
    # available in key "Private Header" and value is PEL instance.

    ${pel_records}=  Create Dictionary
    FOR  ${key}  IN  @{temp_pel_records.keys()}
      Set To Dictionary
      ...  ${pel_records}
      ...  ${temp_pel_records['${key}']['Private Header']['BMC Event Log Id']}=${temp_pel_records['${key}']}
    END

    ${pel_record_length}=  Get Length  ${pel_records}

    Run Keyword And Return If  ${event_record_length} == ${pel_record_length} == 0
    ...  Log  No PEL log and event entries found.

    Run Keyword If  ${event_record_length} != ${pel_record_length}
     ...  Fail  msg=PEL log and event entries are not equal.

    FOR  ${event_id}  IN  @{event_records.keys()}
        ${event_instance_record}=  Set Variable  ${event_records['${event_id}']}

        ${pel_instance_record}=  Set Variable  ${pel_records['${event_id}']}

        # Python module: pel_utils
        pel_utils.Compare Pel And Redfish Event Log  ${pel_instance_record}  ${event_instance_record}
    END
