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
    [Documentation]  Count the occurrence number of a given object.
    [Arguments]  ${object_base_uri_path}  ${object_name}

    # Description of argument(s):
    # object_base_uri_path    Object base path
    #                         (e.g. "/org/open_power/control/").
    # object_name             Object name (e.g. "occ", "cpu" etc).

    ${object_list}=  Get Endpoint Paths
    ...  ${object_base_uri_path}  ${object_name}
    ${list_count}=  Get Length  ${object_list}
    [Return]  ${list_count}


Read Object Attribute
    [Documentation]  Return object attribute data.
    [Arguments]  ${object_base_uri_path}  ${attribute_name}

    # Description of argument(s):
    # object_base_uri_path       Object path.
    #                   (e.g. "/org/open_power/control/occ0").
    # attribute_name    Object attribute name.

    ${resp}=  OpenBMC Get Request
    ...  ${object_base_uri_path}/attr/${attribute_name}  quiet=${1}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}
    ${content}=  To JSON  ${resp.content}
    [Return]  ${content["data"]}


Verify OCC State
    [Documentation]  Check OCC active state.
    [Arguments]  ${expected_occ_active}=${1}
    # Description of Argument(s):
    # expected_occ_active  The expected occ_active value (i.e. 1/0).

    # Example cpu_list data output:
    #  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    #  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1
    ${cpu_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/  cpu*

    :FOR  ${endpoint_path}  IN  @{cpu_list}
    \  ${is_functional}=  Read Object Attribute  ${endpoint_path}  Functional
    \  Continue For Loop If  ${is_functional} == ${0}
    \  ${num}=  Set Variable  ${endpoint_path[-1]}
    \  ${occ_active}=  Get OCC Active State  ${OPENPOWER_CONTROL}occ${num}
    \  Should Be Equal  ${occ_active}  ${expected_occ_active}
    ...  msg=OCC not in right state
