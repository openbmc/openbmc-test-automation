*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/connection_client.robot
Resource            ../lib/code_update_utils.robot

Test Teardown       FFDC On Test Case Fail

*** Variables ***

${BMC_SW_PATH}   ${HOST_INVENTORY_URI}system/chassis/motherboard/boxelder/bmc
${HOST_SW_PATH}  ${HOST_INVENTORY_URI}system/chassis

*** Test Cases ***

Verify Software Purposes
    [Documentation]  Verify that all software objects have a valid 'Purpose'
    ...              field.
    [Tags]  Verify_Software_Purpose

    ${object_uris}=  Read Properties  ${SOFTWARE_VERSION_URI}/list

    :FOR  ${uri}  IN  @{object_uris}
    \  ${object}=  Read Properties  ${uri}
    \  Continue For Loop If  not 'Purpose' in ${object}
    \  Should Contain Any  &{object}[Purpose]  ${VERSION_PURPOSE_HOST}
    ...  ${VERSION_PURPOSE_BMC}


BMC Software Hex ID
    [Documentation]  Verify BMC images have valid 8-digit hex IDs.
    [Tags]  BMC_Software_Hex_ID
    [Template]  Verify Software Hex IDs

    # Software Purpose
    ${VERSION_PURPOSE_BMC}


BMC Software Version
    [Documentation]  Verify BMC version and activation status.
    [Tags]  BMC_Software_Version
    [Template]  Verify Software Version

    # Software Purpose
    ${VERSION_PURPOSE_BMC}


BMC Software Path
    [Documentation]  Verify BMC images have valid 'Path' properties.
    [Tags]  BMC_Software_Path
    [Template]  Verify Software Path

    # Software Version
    ${VERSION_PURPOSE_BMC}


BMC Software RequestedActivation
    [Documentation]  Veriify BMC images have valid 'RequestedActivation'
    ...  properties.
    [Tags]  BMC_Software_RequestedActivation
    [Template]  Verify Software RequestedActivation

    # Software Purpose
    ${VERSION_PURPOSE_BMC}


BMC Software Activation Association
    [Documentation]  Verify BMC association.
    [Tags]  BMC_Software_Activation_Association
    [Template]  Verify Software Activation Association

    # Software Purpose           Association path
    ${VERSION_PURPOSE_BMC}       ${BMC_SW_PATH}


Host Software Hex ID
    [Documentation]  Verify host images have valid 8-digit hex IDs.
    [Tags]  Host_Software_Hex_ID
    [Template]  Verify Software Hex IDs

    # Software Purpose
    ${VERSION_PURPOSE_HOST}


Host Software Version
    [Documentation]  Verify host version and activation status.
    [Tags]  Host_Software_Version
    [Template]  Verify Software Version

    # Software Purpose
    ${VERSION_PURPOSE_HOST}


Host Software Path
    [Documentation]  Verify host images have valid 'Path' properties.
    [Tags]  Host_Software_Path
    [Template]  Verify Software Path

    # Software Version
    ${VERSION_PURPOSE_HOST}


Host Software RequestedActivation
    [Documentation]  Veriify host images have valid 'RequestedActivation'
    ...  properties.
    [Tags]  BMC_Software_RequestedActivation
    [Template]  Verify Software RequestedActivation

    # Software Purpose
    ${VERSION_PURPOSE_HOST}


Host Software Activation Association
    [Documentation]  Verify Host association.
    [Tags]  Host_Software_Activation_Association
    [Template]  Verify Software Activation Association

    # Software Purpose           Association path
    ${VERSION_PURPOSE_HOST}      ${HOST_SW_PATH}


*** Keywords ***

Verify Software Hex IDs
    [Documentation]  Verify software has valid hex IDs.
    [Arguments]  ${software_purpose}

    ${software_ids}=  Get Software Objects Id  ${software_purpose}

    : FOR  ${id}  IN  @{software_ids}
    \  Length Should Be  ${id}  ${8}
    \  Should Match Regexp  ${id}  [0-9a-f]*


Verify Software Path
    [Documentation]  Verify software has valid 'Path' properties.
    [Arguments]  ${software_purpose}

    ${software_uris}=  Get Software Objects  ${software_purpose}

    : FOR  ${uri}  IN  @{software_uris}
    \  ${software_object}=  Get Host Software Property  ${uri}
    \  Return From Keyword If  len('&{software_object}[Path]') == ${0}
    \  BMC Execute Command  [ -d "${path}" ]


Verify Software RequestedActivation
    [Documentation]  Verify that software has valid 'Purpose' properties.
    [Arguments]  ${software_purpose}

    ${software_uris}=  Get Software Objects  ${software_purpose}

    : FOR  ${uri}  IN  @{software_uris}
    \  ${software_object}=  Get Host Software Property  ${uri}
    \  Should Contain Any  &{software_object}[RequestedActivation]
    ...  ${REQUESTED_ACTIVE}  ${REQUESTED_NONE}


Verify Software Activation Association
    [Documentation]  Verify software activation association.
    [Arguments]  ${software_purpose}  ${assoiation_path}

    # Description of argument(s):
    # software_purpose    BMC or host software purpose.
    # assoiation_path     BMC or host inventory path.

    # Example:
    # "/xyz/openbmc_project/software/a0d9ba0d": {
    #     "Activation": "xyz.openbmc_project.Software.Activation.Activations.Active",
    #     "Path": "",
    #     "Priority": 0,
    #     "Purpose": "xyz.openbmc_project.Software.Version.VersionPurpose.BMC",
    #     "RequestedActivation": "xyz.openbmc_project.Software.Activation.RequestedActivations.None",
    #     "Version": "v1.99.9-143-g69cab69",
    #     "associations": [
    #        [
    #            "inventory",
    #            "activation",
    #            "/xyz/openbmc_project/inventory/system/chassis/motherboard/boxelder/bmc"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/software/a0d9ba0d/inventory": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/boxelder/bmc"
    #    ]
    # },

    ${obj_path_list}=  Get Software Objects  ${software_purpose}

    : FOR  ${index}  IN  @{obj_path_list}
    \  Verify Inventory Association  ${index}  ${assoiation_path}


Verify Inventory Association
    [Documentation]  Verify software inventory association.
    [Arguments]  ${software_path}  ${assoiation_path}

    # Description of argument(s):
    # software_path       BMC or host software id.
    # assoiation_path     BMC or host inventory path.

    # Example:
    #    "/xyz/openbmc_project/inventory/system/chassis/motherboard/boxelder/bmc/activation": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/software/e42627b5",
    #        "/xyz/openbmc_project/software/a0d9ba0d"
    #    ]
    # },

    ${sw_attr_data}=  Read Attribute  ${software_path}  associations
    List Should Contain Value  @{sw_attr_data}  ${assoiation_path}

    # Verify the inventory path in software manager entry.
    ${sw_endpoint_data}=  Read Attribute
    ...  ${software_path}${/}inventory  endpoints
    List Should Contain Value  ${sw_endpoint_data}  ${assoiation_path}

    # Verify the inventory path.
    ${inv_endpoint_data}=  Read Attribute
    ...  ${assoiation_path}${/}activation  endpoints
    List Should Contain Value  ${inv_endpoint_data}  ${software_path}


Verify Software Version
    [Documentation]  Verify version and activation status.
    [Arguments]  ${software_purpose}

    # Description of argument(s):
    # software_purpose    BMC or host software purpose.

    # Example:
    # /xyz/openbmc_project/software/list
    # [
    #   "/xyz/openbmc_project/software/2f974579",
    #   "/xyz/openbmc_project/software/136cf504"
    # ]
    ${obj_list}=  Get Software Objects  ${software_purpose}
    : FOR  ${index}  IN  @{obj_list}
    \  ${resp}=  Get Host Software Property  ${index}
    \  Verify Software Properties  ${resp}  ${software_purpose}
    \  Run Keyword If  '${software_purpose}' == '${VERSION_PURPOSE_BMC}'
    ...  Check BMC Version  ${index}  ${resp["Version"]}


Verify Software Properties
    [Documentation]  Verify the software object properties.
    [Arguments]  ${software_property}  ${software_purpose}

    # Description of argument(s):
    # software_property   JSON response data.
    # software_purpose    BMC or host software purpose
    #        (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #              "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    Check Activation Status  ${software_property["Activation"]}


Check BMC Version
    [Documentation]  Get BMC version from /etc/os-release and compare.
    [Arguments]  ${software_object}  ${version}

    # Description of argument(s):
    # software_object   Software object path.
    # version           Software version (e.g. "v1.99.2-107-g2be34d2-dirty")

    ${min_value}=  Get Least Value Priority Image  ${VERSION_PURPOSE_BMC}
    ${priority_value}=  Read Software Attribute  ${software_object}  Priority

    Return From Keyword If  ${priority_value} != ${min_value}

    Open Connection And Log In
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Be Equal As Strings  ${version}  ${output[1:-1]}


Check Activation Status
    [Documentation]  Check if software state is "Active".
    [Arguments]  ${status}

    # Description of argument(s):
    # status  Activation status
    # (e.g. "xyz.openbmc_project.Software.Activation.Activations.Active")
    Should Be Equal As Strings  ${ACTIVE}  ${status}
