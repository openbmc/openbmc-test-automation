*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator
...                DMTF tool.

Library            OperatingSystem
Resource           ../../lib/dmtf_tools_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-JsonSchema-ResponseValidator
${rsv_github_url}  https://github.com/DMTF/Redfish-JsonSchema-ResponseValidator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}Redfish-JsonSchema-ResponseValidator.py
...                -r https://${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S -v

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    # TODO: Build the urls list and key in to the above ${command_string}.
    # -i url list to validate

    ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${command_string}
    Redfish JsonSchema ResponseValidator Result  ${output}
