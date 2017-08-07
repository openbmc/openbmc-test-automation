*** Settings ***
Documentation  BMC and PNOR update utilities keywords.

Resource    ../lib/rest_client.robot

*** Keywords ***

Get Software Objects
    [Documentation]  Get the host software objects and return as a list.
    [Arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    # Example:
    # "data": [
    #      "/xyz/openbmc_project/software/f3b29aa8",
    #      "/xyz/openbmc_project/software/e49bc78e",
    # ],
    # Iterate the list and return the host object name path list.

    ${host_list}=  Create List
    ${sw_list}=  Read Properties  ${SOFTWARE_VERSION_URI}

    :FOR  ${index}  IN  @{sw_list}
    \  ${attr_purpose}=  Read Attribute  ${index}  Purpose  quiet=${1}
    \  Continue For Loop If  '${attr_purpose}' != '${version_type}'
    \  Append To List  ${host_list}  ${index}

    [return]  ${host_list}


Get Host Software Property
    [Documentation]  Return a dictionary of host software properties.
    [Arguments]  ${host_object}

    # Description of argument(s):
    # host_object  Host software object path.
    #             (e.g. "/xyz/openbmc_project/software/f3b29aa8").

    ${sw_attributes}=  Read Properties  ${host_object}
    [return]  ${sw_attributes}


Set Host Software Property
    [Documentation]  Set the host software properties of a given object.
    [Arguments]  ${host_object}  ${sw_attribute}  ${data}

    # Description of argument(s):
    # host_object   Host software object name.
    # sw_attribute  Host software attribute name.
    #               (e.g. "Activation", "Priority", "RequestedActivation" etc).
    # data          Value to be written.

    ${args}=  Create Dictionary  data=${data}
    Write Attribute  ${host_object}  ${sw_attribute}  data=${args}

