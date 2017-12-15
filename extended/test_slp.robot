*** Settings ***
Documentation   Find services and service agents on the system.
Library         OperatingSystem
Library         Collections
Library         String

Resource        ../lib/utils.robot

# Get the SLP services available, make it suite global.
Suite Setup     Suite Setup Execution

Force Tags  SLP_Service_Test

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${service_path}     /etc/slp/services
# SLP_SERVICES  Services listed by slptool, by default Empty.
${SLP_SERVICES}       ${EMPTY}

*** Test Cases ***

Verify SLP Service Types
    [Documentation]  Find services supported by system.
    [Tags]  Verify_SLP_Service_Types
    Verify Service Types

Verify Service Agents For Service Types
    [Documentation]  Find And verify service agents.
    [Tags]  Verify_Service_Agents_For_Service_Types
    @{parameters}=  Split String  ${SLP_SERVICES}  ${\n}
    :FOR  ${parameter}  IN  @{parameters}
    \  ${output}=  Run SLP command  ${service_agents}  ${parameter}
    \  Verify Service Agents  ${output}  ${parameter}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Get SLP services.
    ${output}=  Run  which slptool
    Should Not Be Empty  ${output}
    ...  msg=slptool not installed.
    ${SLP_SERVICES}=  Run SLP command  ${service_types}
    Set Suite Variable  ${SLP_SERVICES}

Run SLP Command
    [Documentation]  Run SLPTool command and return output.
    [Arguments]      ${cmd}  ${param}=${EMPTY}
    # cmd    The SLP command to be run.
    # param  The SLP command parameters.

    ${rc}  ${output}=  Run And Return Rc And Output
    ...   slptool -u ${OPENBMC_HOST} ${cmd} ${param}
    Should Be Equal As Integers  ${rc}  0
    [Return]  ${output}

Verify Service Types
    [Documentation]  Verifies the output of service types.

    ${remove_prefix}=  Remove String  ${SLP_SERVICES}  service:
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

