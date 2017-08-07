*** Settings ***
Documentation  BMC and PNOR update utilities keywords.

Resource    ../lib/rest_client.robot

*** Keywords ***

Get Software Objects
    [Documentation]  Get the host software object list.
    [arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.

    # Example:
    # "data": [
    #      "/xyz/openbmc_project/software/f3b29aa8",
    #      "/xyz/openbmc_project/software/e49bc78e",
    # ],
    # Iterate the list and return the host object name list only.

    ${host_list}=  Create List
    ${sw_list}=  Read Properties  ${SOFTWARE_VERSION_URI}

    :FOR  ${index}  IN  @{sw_list}
    \  ${attr_purpose}=  Read Attribute  ${index}  Purpose  quiet=${1}
    \  Continue For Loop If  '${attr_purpose}' != '${version_type}'
    \  Append To List  ${host_list}  ${index.rsplit('/', 1)[1]}

    [return]  ${host_list}


Get Host Software Property
    [Documentation]  Get the host software properties of a given object.
    [arguments]  ${host_object}

    # Description of argument(s):
    # host_object  Host software object name.

    ${sw_attributes}=  Read Properties  ${SOFTWARE_VERSION_URI}${host_object}
    [return]  ${sw_attributes}


Set Host Software Property
    [Documentation]  Get the host software properties of a given object.
    [arguments]  ${host_object}  ${sw_attribute}  ${data}

    # Description of argument(s):
    # host_object   Host software object name.
    # sw_attribute  Host software attribute name.
    # data          Value to be written.

    ${args}=  Create Dictionary  data=${data}
    Write Attribute
    ...  ${SOFTWARE_VERSION_URI}/${host_object}  ${sw_attribute}  data=${args}

