*** Settings ***
Documentation      Test BMC using https://github.com/DMTF/Redfish-Service-Validator
...                DMTF tool.

Library            OperatingSystem
Resource           ../../lib/resource.robot

*** Variables ***

${DEFAULT_PYTHON}   python3
${rsv_dir}          Redfish-Service-Validator
${rsv_github_url}   https://github.com/DMTF/Redfish-Service-Validator.git
${cmd_parms}        ${DEFAULT_PYTHON} ${rsv_dir}${/}RedfishServiceValidator.py --ip ${OPENBMC_HOST}
...                 --nochkcert --forceauth -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD}
...                 --logdir ${EXECDIR}${/}logs${/}  --debug_logging

*** Test Case ***

Test BMC Redfish Using Redfish Service Validator
    [Documentation]  Check conformance with a Redfish service interface.
    [Tags]  Test_BMC_Redfish_Using_Redfish_Service_Validator

    Download And Run DMTF Tool  ${rsv_dir}  ${rsv_github_url}  ${cmd_parms}


*** Keywords ***

Download And Run DMTF Tool
    [Documentation]  Git clone tool and execute command.
    [Arguments]      ${dir}  ${url}  ${cmd}

    # Description of arguments:
    # dir    Location for tool download.
    # url    Github URL link(e.g "https://github.com/DMTF/Redfish-Service-Validator").
    # cmd    Tool execute command.

    ${rc}  ${output}=  Run and Return RC and Output  git clone ${url} ${dir}
    Should Be Equal As Integers  ${rc}  0

    ${rc}  ${output}=  Run and Return RC and Output  ${cmd}
    Log  ${output}

    # Example:
    # Validation has failed: 9 problems found
    Should Not Contain  ${output}  Validation has failed
