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


Get Sensors Aggregation Data
    [Documentation]  Return open power sensors aggregation value list.
    [Arguments]  ${object_base_uri_path}

    # Description of argument(s):
    # object_base_uri_path  An object path such as one of the elements
    #                       returned by 'Get Sensors Aggregation URL List'
    #                       (e.g. "/org/open_power/sensors/aggregation/per_30s/ps0_input_power/average").

    # Example of aggregation [epoch,time] data:
    # "Values": [
    #    [
    #        1517815708479,  <-- EPOCH
    #        282             <-- Value
    #    ],
    #    [
    #        1517815678238,
    #        282
    #    ],
    #    [
    #        1517815648102,
    #        282
    #    ],
    # ],

    ${resp}=  Read Attribute  ${object_base_uri_path}  Values  quiet=${1}
    ${power_sensors_value_list}=  Create List
    :FOR  ${index}  IN  @{resp}
    \  Append To List  ${power_sensors_value_list}  ${index[1]}
    [Return]  ${power_sensors_value_list}


Get Sensors Aggregation URL List
    [Documentation]  Return the open power aggregation maximum list and the
    ...  average list URIs.
    [Arguments]  ${object_base_uri_path}

    # Example of the 2 lists returned by this keyword:
    # avgs:
    #   avgs[0]: /org/open_power/sensors/aggregation/per_30s/ps0_input_power/average
    #   avgs[1]: /org/open_power/sensors/aggregation/per_30s/ps1_input_power/average
    # maxs:
    #   maxs[0]: /org/open_power/sensors/aggregation/per_30s/ps1_input_power/maximum
    #   maxs[1]: /org/open_power/sensors/aggregation/per_30s/ps0_input_power/maximum

    # Description of argument(s):
    # object_base_uri_path  Object path.
    #                       base path "/org/open_power/sensors/"
    #        (e.g. "base path + aggregation/per_30s/ps0_input_power/average")

    # Example of open power sensor aggregation data as returned by the get
    # request:
    # /org/open_power/sensors/list
    # [
    #    "/org/open_power/sensors/aggregation/per_30s/ps0_input_power/average",
    #    "/org/open_power/sensors/aggregation/per_30s/ps1_input_power/maximum",
    #    "/org/open_power/sensors/aggregation/per_30s/ps0_input_power/maximum",
    #    "/org/open_power/sensors/aggregation/per_30s/ps1_input_power/average"
    # ]

    ${resp}=  OpenBMC Get Request  ${object_base_uri_path}list  quiet=${1}
    ${content}=  To JSON  ${resp.content}

    ${power_supply_avg_list}=  Create List
    ${power_supply_max_list}=  Create List

    :FOR  ${entry}  IN  @{content["data"]}
    \  ${status}=
    ...  Run keyword And Return Status  Should Contain  ${entry}  average
    \  Run Keyword If  ${status} == ${False}
    ...    Append To List  ${power_supply_max_list}  ${entry}
    ...  ELSE
    ...    Append To List  ${power_supply_avg_list}  ${entry}

    [Return]  ${power_supply_avg_list}  ${power_supply_max_list}
