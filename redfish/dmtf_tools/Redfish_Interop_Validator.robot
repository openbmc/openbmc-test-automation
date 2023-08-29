*** Settings ***
Documentation      Test BMC Redfish conformance using  https://github.com/DMTF/Redfish-Interop-Validator.
...                DMTF tool.
...                It validate the Redfish service based on an interoperability profile given to it.

Resource           ../../lib/dmtf_tools_utils.robot

*** Variables ***

${DEFAULT_PYTHON}  python3
${rsv_dir_path}    Redfish-Interop-Validator
${rsv_github_url}  https://github.com/DMTF/Redfish-Interop-Validator.git
# In future, when the profile is available at https://redfish.dmtf.org/profiles/
# Default profile available at  data/openbmc_redfish_interop_profile.json
${profile_path}    ${EXECDIR}/data/openbmc_redfish_interop_profile.json
${cmd_str_master}  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishInteropValidator.py
...                --ip https://${OPENBMC_HOST}:${HTTPS_PORT}
...                --authtype=Session
...                -u ${OPENBMC_USERNAME}
...                -p ${OPENBMC_PASSWORD}
...                --logdir ${EXECDIR}${/}logs${/}
...                ${profile_path}
...                --debugging
${branch_name}     main

*** Test Case ***

Test BMC Redfish Using Redfish Interop Validator
    [Documentation]  Check conformance based on the OpenBMC Interoperability profile.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Interop_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_str_master}  check_error=1

    Run Keyword If  ${rc} != 0  Fail  Redfish-Interop-Validator Failed.
