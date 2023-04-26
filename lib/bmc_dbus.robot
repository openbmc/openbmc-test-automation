*** Settings ***
Documentation      Implemented keywords to execute DBUS related commands on BMC.

Resource           resource.robot
Library            OperatingSystem
Library            Collections

*** Variable ***

${BUSCTL_TREE_COMMAND}                   busctl tree | less
${BUSCTL_INTROSPECT_COMMAND}             busctl introspect
@{dbus_uri_list}

*** Keywords ***

Get DBUS URI List From BMC
    [Documentation]  Get the available DBUS URIs from device tree on BMC.
    [Arguments]  ${service_name}  ${dbus_url}

    # Return the dbus uris corresponding to the service name provided.
    # Description of argument(s):
    #    service_name     Any service uri of the dbus.
    #                        Eg : xyz.openbmc_project.FruDevice
    #    dbus_url         Any dbus url of the dbus.
    #                        Eg : /xyz/openbmc_project/FruDevice

    # Execute dbus tree command
    ${bmc_response}=  BMC Execute Command  ${BUSCTL_TREE_COMMAND}
    ${bmc_response}=  Convert To List  ${bmc_response}
    ${bmc_response_output}=  Get From List  ${bmc_response}  0
    ${bmc_response_output_list}=  Split String  ${bmc_response_output}  \n\n
    # Identify the offset of the service name in the response.
    ${service_name_index_value}=  get_subsequent_value_from_list  ${bmc_response_output_list}  ${service_name}
    ${service_name_index_value}=  Get From List  ${service_name_index_value}  0

    # Get the service name and its corresponding URI's.
    ${service_name_with_uri_list}=  Get From List  ${bmc_response_output_list}  ${service_name_index_value}
    ${service_name_with_uri_list}=  Split String  ${service_name_with_uri_list}  \n

    # Find index of all the uris where the dbus URI matched.
    ${uri_list_index}=  get_subsequent_value_from_list  ${service_name_with_uri_list}  ${dbus_url}
    FOR  ${list_index}  IN  @{uri_list_index}
        # For each index, get the URI and append to list
        ${dbus_uri}=  Get From List  ${service_name_with_uri_list}  ${list_index}
        Append To List  ${dbus_uri_list}  ${dbus_uri}
    END

    [Return]  ${dbus_uri_list[1:]}


Fetch DBUS URI List Without Unicode
    [Documentation]  Gets the list of DBUS URI for the service and returns only sub URIs.
    [Arguments]  ${dbus_uri_list}

    # Return the dbus uris list without the unicodes.
    # Description of argument(s):
    #    dbus_uri_list      List of all the uris for the corresponding service name.
    #    Example:    Converts "  ├─/xyz/openbmc_project/FruDevice/device_0",
    #                ...  to '/xyz/openbmc_project/FruDevice/device_0'

    @{dbus_list}=  Create List
    FOR  ${item}  IN  @{dbus_uri_list}
        ${item}=  Set Variable  ${item.strip()}
        ${item}=  Remove Unicode From Uri  ${item}
        Append To List  ${dbus_list}  ${item}
    END

    [Return]  ${dbus_list}


Execute DBUS Introspect Command
    [Documentation]  Execute the DBUS introspect command and return response.
    [Arguments]  ${dbus_command}

    # Execute the busctl instrospect command for the service name and dbus uri.
    # Description of argument(s):
    #   dbus_command    Command with service name and dbus uri for the fru device.
    #      Example :    xyz.openbmc_project.FruDevice xyz/openbmc_project/FruDevice/device_0

    ${cmd}=  Catenate  ${BUSCTL_INTROSPECT_COMMAND} ${dbus_command}
    ${resp}=  BMC Execute Command  ${cmd}

    [Return]  ${resp[0]}
