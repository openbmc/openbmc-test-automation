*** Settings ***
Documentation     Test BMC using https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator
...               DMTF tool.

Library           OperatingSystem
Resource          ../../lib/dmtf_tools_utils.robot
Resource         ../../lib/bmc_redfish_resource.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-JsonSchema-ResponseValidator
${rsv_github_url}  https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}Redfish-JsonSchema-ResponseValidator.py
...                -r https://${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S -v

*** Test Case ***

Test BMC Redfish Using Redfish JsonSchema ResponseValidator
    [Documentation]  Check conformance with a Redfish JSON schema response validator.
    [Tags]  Test_BMC_Redfish_Using_Redfish_JsonSchema_ResponseValidator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    redfish.Login
    ${url_list}=  redfish_utils.List Request  /redfish/v1/
    redfish.Logout

    :FOR  ${url}  IN  @{url_list}
    \  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string} -i ${url}
    \  Redfish JsonSchema ResponseValidator Result  ${output}
