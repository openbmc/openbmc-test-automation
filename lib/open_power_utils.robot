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

    ${occ_list}=  Get Endpoint Paths  ${OPENBMC_POWER}  occ*

    [return]  ${occ_list}


Get OCC Active State
    [Documentation]  Get the OCC "OccActive" and return the attribute value.
    [Arguments]  ${occ_object}

    # Description of argument(s):
    # occ_object   OCC object path.
    #             (e.g. "/org/open_power/control/occ0").

    ${occ_attribute}=  Read Attribute  ${occ_object}  OccActive
    [return]  ${occ_attribute}
