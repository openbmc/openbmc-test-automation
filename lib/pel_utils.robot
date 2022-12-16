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

    # event_dict_records dictionary contains all the events where key is "odata.id"
    # and value is event instance.
    #
    # Below is sample for event_dict_records with limited information.
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

    ${event_dict_records}=  Get Redfish Event Logs

    # Below event_dict_records dictionary is rearranged, where key is Id and value is event instance.
    
    # Python module: utils
    ${event_dict_records}=  utils.Get Key Value From Nested Dict  ${event_dict_records}  Id
    Should Not Be Equal As Strings  'False'  '${event_dict_records}'
    ...  msg=Expected key that is "Id" not found in dictionary.

    ${event_record_length}=  Get Length  ${event_dict_records}

    # pel_dict_records dictionary contains PEL detail informaton key is PEL id,
    # value is PEL instance plus PEL information data.

    # Python module: pel_utils
    ${pel_dict_records}=  pel_utils.Get PEL Detail Information

    # pel_dict_records dictionary is rearranged, where key will be nested key that is "BMC Event Log Id"
    # available in key "Private Header" and value is PEL instance.

    # Python module: pel_utils
    ${pel_dict_records}=  pel_utils.Get Formatted Dict
    ...  pel_data_key=Private Header  pel_data_sub_key=BMC Event Log Id  pel_data=${pel_dict_records}
    Should Not Be Equal As Strings  'False'  '${pel_dict_records}'
    ...  msg=Expected nested key "BMC Event Log Id" not found in "Private Header" dictionary.

    ${pel_record_length}=  Get Length  ${pel_dict_records}

    Run Keyword And Return If  ${event_record_length} == ${pel_record_length} == 0
    ...  Log  No PEL log and event entries found.

    Run Keyword If  ${event_record_length} != ${pel_record_length}
     ...  Fail  msg=PEL log and event entries are not equal.


    FOR  ${event_id}  IN  @{event_dict_records.keys()}
        ${event_instance_record}=  Set Variable  ${event_dict_records['${event_id}']}

        ${pel_instance_record}=  Set Variable  ${pel_dict_records['${event_id}']}

        # Python module: pel_utils
        pel_utils.Compare Pel And Redfish Event Log  ${pel_instance_record}  ${event_instance_record}
    END
