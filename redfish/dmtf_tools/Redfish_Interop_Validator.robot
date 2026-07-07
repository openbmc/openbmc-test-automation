*** Settings ***
Documentation      Test BMC Redfish conformance using
...                https://github.com/DMTF/Redfish-Interop-Validator.
...                DMTF tool.
...                It validate the Redfish service based on an
...                interoperability profile given to it.

Resource           ../../lib/dmtf_tools_utils.robot

Test Tags          Redfish_Interop_Validator

*** Variables ***

${DEFAULT_PYTHON}              python3
${rsv_dir_path}                Redfish-Interop-Validator
${rsv_github_url}              https://github.com/DMTF/Redfish-Interop-Validator.git
# In future, when the profile is available at https://redfish.dmtf.org/profiles/
# Default profile available at  data/openbmc_redfish_interop_profile.json
${profile_path}                ${EXECDIR}/data/openbmc_redfish_interop_profile.json
${cmd_str_master}              ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishInteropValidator.py
...                            --ip https://${OPENBMC_HOST}:${HTTPS_PORT}
...                            --authtype=Session
...                            -u ${OPENBMC_USERNAME}
...                            -p ${OPENBMC_PASSWORD}
...                            --logdir ${EXECDIR}${/}logs${/}
...                            ${profile_path}
...                            --debugging
${branch_name}                 main
${ocp_branch_name}             master
${ocp_baseline_profile_path}   ${EXECDIR}${/}OCPBaselineHardwareManagement.v1_1_0.json
${ocp_server_profile_path}     ${EXECDIR}${/}OCPServerHardwareManagement.v1_1_0.json
${ocp_baseline_profile_url}
...  https://raw.githubusercontent.com/opencomputeproject/HWMgmt-OCP-Profiles/${ocp_branch_name}/OCPBaselineHardwareManagement.v1_1_0.json
${ocp_server_profile_url}
...  https://raw.githubusercontent.com/opencomputeproject/HWMgmt-OCP-Profiles/${ocp_branch_name}/Server/OCPServerHardwareManagement.v1_1_0.json

*** Test Cases ***

Test BMC Redfish Using Redfish Interop Validator
    [Documentation]  Check conformance based on the OpenBMC Interoperability profile.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Interop_Validator

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_str_master}  check_error=1

    IF  ${rc} != 0  Fail  Redfish-Interop-Validator Failed.


Test BMC Redfish Using Redfish Interop Validator For OCP Hardware Management Profiles v1_1_0
    [Documentation]  Check conformance based on the OCP Baseline and Server Hardware
    ...  Management interoperability profiles from:
    ...  https://github.com/opencomputeproject/HWMgmt-OCP-Profiles/blob/master/OCPBaselineHardwareManagement.v1_1_0.json
    ...  https://github.com/opencomputeproject/HWMgmt-OCP-Profiles/blob/master/Server/OCPServerHardwareManagement.v1_1_0.json
    [Tags]  Test_BMC_Redfish_Using_Redfish_Interop_Validator_For_OCP_Hardware_Management_Profiles_v1_1_0

    Download DMTF Tool  ${rsv_dir_path}  ${rsv_github_url}  ${branch_name}
    Download OCP Profiles

    ${cmd_ocp_profiles}=  Catenate
    ...  ${DEFAULT_PYTHON} ${rsv_dir_path}${/}RedfishInteropValidator.py
    ...  --ip https://${OPENBMC_HOST}:${HTTPS_PORT}
    ...  --authtype=Session
    ...  -u ${OPENBMC_USERNAME}
    ...  -p ${OPENBMC_PASSWORD}
    ...  --logdir ${EXECDIR}${/}logs${/}
    ...  ${ocp_baseline_profile_path}
    ...  ${ocp_server_profile_path}
    ...  --debugging

    ${rc}  ${output}=  Run DMTF Tool  ${rsv_dir_path}  ${cmd_ocp_profiles}  check_error=1
    IF  ${rc} != 0  Fail  Redfish-Interop-Validator Failed for OCP Hardware Management profiles v1.1.0.

*** Keywords ***

Download OCP Profiles
    [Documentation]  Download OCP Baseline and Server Hardware Management interoperability
    ...  profiles from the OpenComputeProject GitHub repository to local files.

    ${rc}  ${output}=  Shell Cmd  wget -q -O ${ocp_baseline_profile_path} ${ocp_baseline_profile_url}
    Should Be Equal As Integers  ${rc}  0  Failed to download OCP baseline profile: ${output}
    ${rc}  ${output}=  Shell Cmd  wget -q -O ${ocp_server_profile_path} ${ocp_server_profile_url}
    Should Be Equal As Integers  ${rc}  0  Failed to download OCP baseline profile: ${output}
