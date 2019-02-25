*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Service-Validator.
...                DMTF tool.

Library            OperatingSystem
Library            ../../lib/gen_cmd.py
Resource           ../../lib/dmtf_tools_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-Service-Validator
${rsv_github_url}  https://github.com/DMTF/Redfish-Service-Validator.git
${command_string}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishServiceValidator.py --ip ${OPENBMC_HOST}
    ...  --nochkcert --forceauth -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD}
    ...  --logdir ${EXECDIR}${/}logs${/}  --debug_logging

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    Run DMTF Tool  ${rsv_dir_path}  ${command_string}
