*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Interop-Validator.
...                DMTF tool.

Resource           ../../lib/dmtf_tools_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-Interop-Validator
${rsv_github_url}  https://github.com/DMTF/Redfish-Interop-Validator.git
${cmd_str_master}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishInteropValidator.py
...                --ip https://${OPENBMC_HOST}:${HTTPS_PORT} --authtype=Session -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD} --logdir ${EXECDIR}${/}logs${/} --debugging
...                ${EXECDIR}/data/redfish_interop_profile.json

*** Test Case ***

Test BMC Redfish Using Redfish Interop Validator
    [Documentation]  Check conformance based on an Interoperability profile.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Interop_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_str_master}  check_error=1

    Redfish Interop Validator Result  ${output}
    Run Keyword If  ${rc} != 0  Fail  Redfish-Interop-Validator Failed.
