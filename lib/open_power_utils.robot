*** Settings ***
Documentation  Open power domain keywords.

Variables      ../data/variables.py
Resource       ../lib/utils.robot
Resource       ../lib/connection_client.robot

*** Variables ***
${functional_cpu_count}       ${0}
${active_occ_count}           ${0}
${OCC_WAIT_TIMEOUT}           2 min

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
    [Arguments]  ${value}

    # Description of argument(s):
    # value       CPU position (e.g. "0, 1, 2").

    ${cmd}=  Catenate  busctl get-property org.open_power.OCC.Control
    ...   /org/open_power/control/occ${value} org.open_power.OCC.Status OccActive

    ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
    ...  print_out=1  print_err=1  ignore_err=1

    # The command returns format  'b true'
    Return From Keyword If  '${cmd_output.split(' ')[-1]}' == 'true'  ${1}

    [Return]  ${0}


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


Get Functional Processor Count
    [Documentation]  Get functional processor count.

    ${cpu_list}=  Redfish.Get Members List  /redfish/v1/Systems/system/Processors/  *cpu*

    FOR  ${endpoint_path}  IN  @{cpu_list}
       # {'Health': 'OK', 'State': 'Enabled'} get only matching status good.
       ${cpu_status}=  Redfish.Get Attribute  ${endpoint_path}  Status
       Continue For Loop If  '${cpu_status['Health']}' != 'OK' or '${cpu_status['State']}' != 'Enabled'
       ${functional_cpu_count} =  Evaluate   ${functional_cpu_count} + 1
    END

    [Return]  ${functional_cpu_count}


Get Active OCC State Count
    [Documentation]  Get active OCC state count.

    ${cpu_list}=  Redfish.Get Members List  /redfish/v1/Systems/system/Processors/  *cpu*

    FOR  ${endpoint_path}  IN  @{cpu_list}
       ${num}=  Set Variable  ${endpoint_path[-1]}
       ${cmd}=  Catenate  busctl get-property org.open_power.OCC.Control
       ...   /org/open_power/control/occ${num} org.open_power.OCC.Status OccActive

       ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
       ...  print_out=1  print_err=1  ignore_err=1

       # The command returns format  'b true'
       Continue For Loop If   '${cmd_output.split(' ')[-1]}' != 'true'
       ${active_occ_count} =  Evaluate   ${active_occ_count} + 1
    END

    [Return]  ${active_occ_count}


Match OCC And CPU State Count
    [Documentation]  Get CPU functional count and verify OCC count active matches.

    ${cpu_count}=  Get Functional Processor Count
    Log To Console  Functional Processor count: ${cpu_count}

    FOR  ${num}  IN RANGE  ${0}  ${cpu_count}
       ${cmd}=  Catenate  busctl get-property org.open_power.OCC.Control
       ...   /org/open_power/control/occ${num} org.open_power.OCC.Status OccActive

       ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
       ...  print_out=1  print_err=1  ignore_err=1

       # The command returns format  'b true'
       Continue For Loop If   '${cmd_output.split(' ')[-1]}' != 'true'
       ${active_occ_count} =  Evaluate   ${active_occ_count} + 1
    END

    Log To Console  OCC Active count: ${active_occ_count}

    Should Be Equal  ${active_occ_count}  ${cpu_count}
    ...  msg=OCC count ${active_occ_count} and CPU Count ${cpu_count} mismatched.


Verify OCC State
    [Documentation]  Check OCC active state.
    [Arguments]  ${expected_occ_active}=${1}
    # Description of Argument(s):
    # expected_occ_active  The expected occ_active value (i.e. 1/0).

    # Example cpu_list data output:
    #  /redfish/v1/Systems/system/Processors/cpu0
    #  /redfish/v1/Systems/system/Processors/cpu1

    ${cpu_list}=  Redfish.Get Members List  /redfish/v1/Systems/system/Processors/  cpu*

    FOR  ${endpoint_path}  IN  @{cpu_list}
       # {'Health': 'OK', 'State': 'Enabled'} get only matching status good.
       ${cpu_status}=  Redfish.Get Attribute  ${endpoint_path}  Status
       Continue For Loop If  '${cpu_status['Health']}' != 'OK' or '${cpu_status['State']}' != 'Enabled'
       Log To Console  ${cpu_status}
       ${num}=  Set Variable  ${endpoint_path[-1]}
       ${occ_active}=  Get OCC Active State  ${num}
       Should Be Equal  ${occ_active}  ${expected_occ_active}
       ...  msg=OCC not in right state
    END


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
    #        282             <-- Power value in watts
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
    FOR  ${entry}  IN  @{resp}
       Append To List  ${power_sensors_value_list}  ${entry[1]}
    END
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

    FOR  ${entry}  IN  @{content["data"]}
        Run Keyword If  'average' in '${entry}'  Append To List  ${power_supply_avg_list}  ${entry}
        Run Keyword If  'maximum' in '${entry}'  Append To List  ${power_supply_max_list}  ${entry}
    END

    [Return]  ${power_supply_avg_list}  ${power_supply_max_list}


REST Verify No Gard Records
    [Documentation]  Verify no gard records are present.

    ${resp}=  Read Properties  ${OPENPOWER_CONTROL}gard/enumerate
    Log Dictionary  ${resp}
    Should Be Empty  ${resp}  msg=Found gard records.


Inject OPAL TI
    [Documentation]  OPAL terminate immediate procedure.
    [Arguments]      ${stable_branch}=master
    ...              ${repo_dir_path}=/tmp/repository
    ...              ${repo_github_url}=https://github.com/open-power/op-test

    # Description of arguments:
    # stable_branch    Git branch to clone. (default: master)
    # repo_dir_path    Directory path for repo tool (e.g. "op-test").
    # repo_github_url  Github URL link (e.g. "https://github.com/open-power/op-test").

    ${value}=  Generate Random String  4  [NUMBERS]

    ${cmd_buf}=  Catenate  git clone --branch ${stable_branch} ${repo_github_url} ${repo_dir_path}/${value}
    Shell Cmd  ${cmd_buf}

    Open Connection for SCP
    scp.Put File  ${repo_dir_path}/${value}/test_binaries/deadbeef  /tmp
    Pdbg  -a putmem 0x300000f8 < /tmp/deadbeef

    # Clean up the repo once done.
    ${cmd_buf}=  Catenate  rm -rf ${repo_dir_path}${/}${value}
    Shell Cmd  ${cmd_buf}


Trigger OCC Reset
    [Documentation]  Trigger OCC reset request on an active OCC.
    [Arguments]  ${occ_target}=${0}

    # Description of Argument(s):
    # occ_target   Target a valid given OCC number 0,1, etc.

    Log To Console   OCC Reset Triggered on OCC ${occ_target}

    ${cmd}=  Catenate  busctl call org.open_power.OCC.Control
    ...  /org/open_power/control/occ${occ_target} org.open_power.OCC.PassThrough
    ...  Send ai 8 64 0 5 20 82 83 84 0

    ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}  print_out=1  print_err=1

    Log To Console  OCC wait check for disabled state.
    Wait Until Keyword Succeeds  5 sec  30 sec  Verify OCC Target State  ${occ_target}


Verify OCC Target State
    [Documentation]  Verify that the user given state matches th current OCC state.
    [Arguments]  ${occ_target}=${0}  ${expected_state}=${0}

    # Description of Argument(s):
    # occ_target       Target a valid given OCC number 0,1, etc.
    # expected_state   For OCC either 0 or 1. Default is 0.

    ${occ_active}=  Get OCC Active State  ${occ_target}
    Should Be Equal  ${occ_active}  ${expected_state}
    Log To Console  Target OCC ${occ_target} state is ${occ_active}.


Trigger OCC Reset And Wait For OCC Active State
    [Documentation]  Trigger OCC reset request and wait for OCC to reset back to active state.

    Trigger OCC Reset

    Log To Console  OCC wait check for active state.
    Wait Until Keyword Succeeds  ${OCC_WAIT_TIMEOUT}  20 sec   Match OCC And CPU State Count
