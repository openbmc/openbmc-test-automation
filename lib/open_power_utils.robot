*** Settings ***
Documentation  Open power domain keywords.

Library        ../data/variables.py
Resource       ../lib/utils.robot

*** Keywords ***

Get OCC Objects
    [Documentation]  Get the OCC objects and return as a list.

    # Example:
    # {
    #     "/org/open_power/control/occ0": {
    #          "OccActive": 0
    # },
    #     "/org/open_power/control/occ1": {
    #          "OccActive": 1
    # }

    ${occ_list}=  Get Endpoint Paths  ${OPENPOWER_CONTROL}  occ*

    [Return]  ${occ_list}


Get OCC Active State
    [Documentation]  Get the OCC "OccActive" and return the attribute value.
    [Arguments]  ${occ_object}

    # Description of argument(s):
    # occ_object   OCC object path.
    #             (e.g. "/org/open_power/control/occ0").

    ${occ_attribute}=  Read Attribute  ${occ_object}  OccActive
    [Return]  ${occ_attribute}


Count Object Entries
    [Documentation]  Count the occurence number of a given object.
    [Arguments]  ${object_base_path}  ${object_name}

    # Description of argument(s):
    # object_name         Object name (e.g. "occ", "cpu" etc).
    # object_base_path    Object base path (e.g. "/org/open_power/control/").

    ${object_list}=  Get Endpoint Paths  ${object_base_path}  ${object_name}
    Log To Console  \n ${object_list}
    ${list_count}=  Get Length  ${object_list}
    [Return]  ${list_count}


OCC And Inventory CPU Mapping
    [Documentation]  Return the corresponding OCC object suffix number.
    [Arguments]  ${object_path}

    # Description of argument(s):
    # object_path    Object path (e.g. "/org/open_power/control/occ0").

    # Example:
    # 1x1 OCC and CPU inventory object mapping.
    # "/org/open_power/control/occ0"
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"

    [Return]  ${object_path[-1]}


Read Object Attribute
    [Documentation]  Return object attribute data.
    [Arguments]  ${object_path}  ${attribute_name}

    # Description of argument(s):
    # object_path       Object path.
    #                   (e.g. "/org/open_power/control/occ0").
    # attribute_name    Object attribute name.

    ${resp}=  OpenBMC Get Request  ${object_path}/attr/${attribute_name}
    ...  quiet=${1}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}
    ${content}=  To JSON  ${resp.content}
    [Return]  ${content["data"]}

