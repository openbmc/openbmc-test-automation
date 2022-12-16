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

    ${event_dict}=  Get Redfish Event Logs

    ${event_sw_inv}=  utils.get_key_value_from_nested_dict  ${event_dict}  Id
    ${event_record_length}=  Get Length  ${event_sw_inv}

    ${pel_dict}=  pel_utils.get_pel_detail_information

    ${pel_sw_inv}=  pel_utils.get_formatted_dict
    ...  pel_data_key=Private Header  pel_data_sub_key=BMC Event Log Id  pel_data=${pel_dict}
    ${pel_record_length}=  Get Length  ${pel_sw_inv}

    Run Keyword And Return If  ${event_record_length} == ${pel_record_length} == 0
    ...  Log  No PEL log and event entries found.

    Run Keyword If  ${event_record_length} != ${pel_record_length}
     ...  Fail  PEL log and event entries are not equal.


    FOR  ${event_id}  IN  @{event_sw_inv.keys()}

        ${event_inst_sw_inv}=  Set Variable  ${event_sw_inv['${event_id}']}

        ${pel_inst_sw_inv}=  Set Variable  ${pel_sw_inv['${event_id}']}

        # Python module: pel_utils
        pel_utils.Compare Pel And Redfish Event Log  ${pel_inst_sw_inv}  ${event_inst_sw_inv}

    END
