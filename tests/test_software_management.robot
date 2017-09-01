*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/connection_client.robot
Resource            ../lib/code_update_utils.robot
Test Teardown       FFDC On Test Case Fail


*** Test Cases ***

BMC Software Version
    [Documentation]  Verify BMC version and activation status.
    [Tags]  BMC_Software_Version
    [Template]  Verify Software Version

    # Software Version Purpose
    ${VERSION_PURPOSE_BMC}

Host Software Version
    [Documentation]  Verify host version and activation status.
    [Tags]  Host_Software_Version
    [Template]  Verify Software Version

    # Software Version Purpose
    ${VERSION_PURPOSE_HOST}


*** Keywords ***

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


Verify Software Properties
    [Documentation]  Verify the software object properties.
    [Arguments]  ${software_property}  ${software_purpose}

    # Description of argument(s):
    # software_property   JSON response data.
    # software_purpose    BMC or host software purpose
    #        (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #              "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    Check Activation Status  ${software_property["Activation"]}
    Run Keyword If  '${software_purpose}' == '${VERSION_PURPOSE_BMC}'
    ...  Check BMC Version  ${software_property["Version"]}


Check BMC Version
    [Documentation]  Get BMC version from /etc/os-release and compare.
    [Arguments]  ${version}

    # Description of argument(s):
    # version  Software version (e.g. "v1.99.2-107-g2be34d2-dirty")

    Open Connection And Log In
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}=  Execute Command On BMC  ${cmd}
    Should Be Equal As Strings  ${version}  ${output[1:-1]}


Check Activation Status
    [Documentation]  Check if software state is "Active".
    [Arguments]  ${status}

    # Description of argument(s):
    # status  Activation status
    # (e.g. "xyz.openbmc_project.Software.Activation.Activations.Active")
    Should Be Equal As Strings  ${ACTIVE}  ${status}
