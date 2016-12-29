*** Settings ***
Documentation   Find services and service agents on the system.
Library         OperatingSystem
Library         Collections
Library         String

Resource        ../lib/utils.robot

Suite Setup         Get Service Types

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${service_path}     /etc/slp/services

*** Test Cases ***

Find Services
    [Documentation]  Find services supported by system.
    [Tags]  Find_Services
    Verify Services  ${cmd_output}
    # cmd_output- Services listed by slptool.

Find Service Agents
    [Documentation]  Find service agents.
    [Tags]  Find_Sevrice_Agents
    @{parameters}=  Split String  ${cmd_output}  ${\n}
    :FOR  ${parameter}  IN  @{parameters}
    \  ${output}=  Run SLP command  ${service_agents}  ${parameter}
    \  Verify Service Agents  ${output}  ${parameter}

*** Keywords ***

Get Service Types
    ${output}=  Run  which slptool
    Should Not Be Empty  ${output}
    ...  msg=slptool not installed
    ${cmd_output}=  Run SLP command  ${service_types}
    Set Suite Variable  ${cmd_output}

Run SLP Command
    [Documentation]  Run SLPTool command and return output.
    [Arguments]      ${cmd}  ${param}=${EMPTY}
    # cmd    The SLP command to be run.
    # param  The SLP command parameters.

    ${rc}  ${output}=  Run And Return Rc And Output
    ...   slptool -u ${OPENBMC_HOST} ${cmd} ${param}
    Should Be Equal As Integers  ${rc}  0
    [Return]  ${output}

Verify Services
    [Documentation]  Verifies the output of service types.
    [Arguments]    ${output}
    ${remove_prefix}=  Remove String  ${output}  service:
    @{services}=  Split String  ${remove_prefix}  ${\n}
    ${service_count}=  Get Length  ${services}
    Open Connection And Log In
    ${stdout}  ${stderr}=  Execute Command  ls ${service_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${file_count}=  Get Line Count  ${stdout}
    Should Be Equal  ${service_count}  ${file_count}
    ...  msg=Number of services on system & command are not equal.
    :FOR  ${service}  IN  @{services}
    \  Should Contain  ${stdout}  ${service}
    ...  msg=Services on system & command are not same.

Verify Service Agents
    [Documentation]  Verifies the output of srvs.
    [Arguments]      ${output}  ${service_agent}
    # Example of output
    # <service:service_name:tcp//xxx.xxx.xxx.xxx,2200>

    Run Keywords  Should Contain  ${output}  ${service_agent}  AND
    ...  Should Contain  ${output}  ${OPENBMC_HOST},
    ...  msg=Expected process info missing.

