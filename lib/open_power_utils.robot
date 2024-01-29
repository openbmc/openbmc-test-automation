*** Settings ***
Documentation  Open power domain keywords.

Variables      ../data/variables.py
Resource       ../lib/utils.robot
Resource       ../lib/connection_client.robot
Library        utilities.py

*** Variables ***
${functional_cpu_count}       ${0}
${active_occ_count}           ${0}
${OCC_WAIT_TIMEOUT}           8 min
${fan_json_msg}               Unable to create dump on non-JSON config based system

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
    [Return]  ${resp.json()["data"]}


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

    ${power_supply_avg_list}=  Create List
    ${power_supply_max_list}=  Create List

    FOR  ${entry}  IN  @{resp.json()["data"]}
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
    Wait Until Keyword Succeeds  30 sec  5 sec  Verify OCC Target State  ${occ_target}


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


Get Sensors Dbus Tree List
    [Documentation]  Get the list dbus path of the given sensor object and
    ...              return the populatedlist.

    ${dbus_obj_var}=  Set Variable
    ...  xyz.openbmc_project.HwmonTempSensor
    ...  xyz.openbmc_project.ADCSensor
    ...  xyz.openbmc_project.VirtualSensor

    # Filter only the dbus paths service by the sensor obj.
    ${sensors_dbus_tree_dict}=  Create Dictionary
    FOR  ${dbus_obj}  IN  @{dbus_obj_var}
        ${cmd}=  Catenate  busctl tree ${dbus_obj} --list | grep /sensors/
        ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
        ...  print_out=0  print_err=0  ignore_err=1
        Set To Dictionary  ${sensors_dbus_tree_dict}  ${dbus_obj}  ${cmd_output.splitlines()}
    END

    Rprint Vars  sensors_dbus_tree_dict
    # Key Pair: 'sensor obj":[list of obj URI]
    # Example:
    # sensors_dbus_tree_dict:
    # [xyz.openbmc_project.HwmonTempSensor]:
    #    [0]:     /xyz/openbmc_project/sensors/temperature/Ambient_0_Temp
    #    [1]:     /xyz/openbmc_project/sensors/temperature/PCIE_0_Temp
    # [xyz.openbmc_project.ADCSensor]:
    #    [0]:     /xyz/openbmc_project/sensors/voltage/Battery_Voltage
    # [xyz.openbmc_project.VirtualSensor]:
    #    [0]:     /xyz/openbmc_project/sensors/temperature/Ambient_Virtual_Temp

    [Return]  ${sensors_dbus_tree_dict}


Get Populated Sensors Dbus List
    [Documentation]  Perform GET operation on the attribute list and confirm it is
    ...              populated and does not error out during GET request..

    ${sensor_dict}=  Get Sensors Dbus Tree List

    # Loop through the dictionary and iterate item entries.
    ${valid_dbus_list}=  Create List
    FOR  ${key}  IN  @{sensor_dict.keys()}
        FOR  ${val}  IN  @{sensor_dict["${key}"]}
           ${cmd}=  Catenate
           ...  busctl get-property ${key} ${val} xyz.openbmc_project.Sensor.Value Value
           ${cmd_output}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
           ...  print_out=0  print_err=0  ignore_err=1
           # Skip failed to get property command on Dbus object.
           Run Keyword If  ${rc} == 0   Append To List  ${valid_dbus_list}  ${val}
        END
    END

    [Return]  ${valid_dbus_list}


Verify Runtime Sensors Dbus List
    [Documentation]  Load pre-defined sensor JSON Dbus data and validate against
    ...              runtime sensor list generated.

    # Default path data/sensor_dbus.json else takes
    # user CLI input -v SENSOR_DBUS_JSON_FILE_PATH:<path>
    ${SENSOR_DBUS_JSON_FILE_PATH}=
    ...  Get Variable Value  ${SENSOR_DBUS_JSON_FILE_PATH}   data/sensor_dbus.json

    ${json_data}=  OperatingSystem.Get File  ${SENSOR_DBUS_JSON_FILE_PATH}
    ${json_sensor_data}=  Evaluate  json.loads('''${json_data}''')  json

    ${runtime_sensor_list}=  Get Populated Sensors Dbus List

    ${system_model}=  Get BMC System Model
    Rprint Vars  system_model
    Rprint Vars  runtime_sensor_list

    ${status}=  Run Keyword And Return Status
    ...  Dictionary Should Contain Value   ${json_sensor_data}  ${runtime_sensor_list}

    Run Keyword If  ${status} == ${False}  Log And Fail  ${json_sensor_data}

    Log To Console  Runtime Dbus sensor list matches.


Log And Fail
    [Documentation]  Log detailed failure log on the console.
    [Arguments]  ${json_sensor_data}

    # Description of Argument(s):
    # json_sensor_data   Sensor JSON data from data/sensor_dbus.json.

    Rprint Vars  json_sensor_data
    Fail  Runtime generated Dbus sensors does not match


Dump Fan Control JSON
    [Documentation]  Execute fan control on BMC to dump config with 'fanctl dump',
    ...              which makes it write a /tmp/fan_control_dump.json file.

    ${output}  ${stderr}  ${rc} =  BMC Execute Command  test -f /usr/bin/fanctl
    ...  print_err=1  ignore_err=1
    Return From Keyword If   ${rc} == 1  fanctl application doesn't exist.

    # This command will force a fan_control_dump.json file in temp path and
    # takes few seconds to complete..
    BMC Execute Command  fanctl dump
    Sleep  10s


Get Fan JSON Data
    [Documentation]  Read the JSON string file from BMC and return.

    # Check for the generated file and return the file data as JSON and fails if
    # it doesn't find file generated.
    ${cmd}=  Catenate  test -f /tmp/fan_control_dump.json; cat /tmp/fan_control_dump.json
    ${json_string}  ${stderr}  ${rc} =  BMC Execute Command  ${cmd}
    ...  print_out=1  print_err=1  ignore_err=1

    Should Be True  ${rc} == 0  msg=No Fan control config JSON file is generated.
    ${fan_json}=  Evaluate  json.loads('''${json_string}''')  json

    [return]  ${fan_json}


Get Fan Attribute Value
    [Documentation]  Return the specified value of the matched search key in
    ...              nested dictionary data.
    [Arguments]  ${fan_dict}  ${key_value}

    # Description of Argument(s):
    # key_value      User input attribute value in the dictionary.

    ${empty_dicts}=  Create Dictionary

    # Check for JSON response data.
    # {
    #   "msg":   "Unable to create dump on non-JSON config based system"
    # }

    ${status}=  Run Keyword And Return Status
    ...   Should Be Equal  ${fan_dict["msg"]}  ${fan_json_msg}
    IF  ${status}
        Log To Console  Skipping attribute ${key_value} check.
        Return From Keyword  ${empty_dicts}
    END

    # Python module:  get_value_from_nested_dict(key,dict)
    ${value_list}=  utilities.Get Value From Nested Dict  ${key_value}  ${fan_dict}

    Should Not Be Empty  ${value_list}  msg=${key_value} key attribute not found.

    [Return]  ${value_list[0]}
