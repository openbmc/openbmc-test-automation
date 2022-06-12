*** Settings ***
Documentation  Sensor Related Keywords

Resource         resource.robot
Library          utils.py

Library          OperatingSystem
Library          Collections

*** Variable ***
@{sensor_service_path_not_mapped_in_sensor_tree}
&{sensor_dbus_uri_command_dict}

${busctl_tree_sensor_service_grep_command}    busctl tree | less | grep -i "Service xyz" | grep -i Sensor
${busctl_tree_command}                        busctl tree | less
${busctl_introspect_command}                  busctl introspect

*** Keywords ***
Create an Dictionary With Sensor ID And Dbus Command For Sensors Via Redfish
    [Documentation]  Create an dictionary by mapping sensor id with dbus command.
    [Arguments]  ${sensor_id_list}

    ${sensor_name_service_path_uri_dict}  ${object_path_uri_list}=
    ...  Create An Dictionary With Sensor Name And Service Path URI  ${sensor_id_list}

    ${sensor_name_object_path_uri_dict}=
    ...  Create An Dictionary With Sensor Name And Object Path URI  ${object_path_uri_list}  ${sensor_id_list}

    FOR  ${sensor_id}  IN  @{sensor_id_list}
      ${sensor_id_in_dict}=  Evaluate  "${sensor_id}" in ${sensor_name_object_path_uri_dict}
      Continue For Loop If  ${sensor_id_in_dict} == False
      ${dbus_service_name}=  Get From Dictionary  ${sensor_name_service_path_uri_dict}  ${sensor_id}
      ${dbus_command}=  Get From Dictionary  ${sensor_name_object_path_uri_dict}  ${sensor_id}
      ${dbus_service_name}=  Split String  ${dbus_service_name}
      ${dbus_service_name}=  Get From List  ${dbus_service_name}  1
      ${dbus_service_name}=  Replace String  ${dbus_service_name}  ${SPACE}  ${EMPTY}
      ${dbus_command}=  Replace String  ${dbus_command}  ${SPACE}  ${EMPTY}
      ${sensor_dbus_uri}=  Catenate  ${dbus_service_name} ${dbus_command}
      Set To Dictionary  ${sensor_dbus_uri_command_dict}  ${sensor_id}  ${sensor_dbus_uri}
    END

    [Return]  ${sensor_dbus_uri_command_dict}  ${sensor_service_path_not_mapped_in_sensor_tree}
