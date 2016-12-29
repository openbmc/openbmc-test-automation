*** Settings ***
Documentation   Find services and service agents on the system.
Library         OperatingSystem

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${parameter}        management-hardware.IBM
${verify}           FS

***Test Cases ***
Find Services
    [Documentation]    Find services supported by system.
    ${op}              Run SLP command   ${service_types}
    Verify output      ${op}   ${verify}

Find Service Agents
    [Documentation]   Find Service agents.
    ${op}             Run SLP command   ${service_agents}   ${parameter}
    Verify output     ${op}

*** Keywords ***
Run SLP Command
    [Documentation]   Run SLPTool command
    [Arguments]       ${i_cmd}   ${i_param}=${EMPTY}
    ${rc}   ${i_op} =   Run And Return Rc And Output
    ...   slptool -u ${bmc_ip} ${i_cmd} ${i_param}
    [Return]        ${i_op}

Verify output
   [Arguments]      ${i_op}   ${i_param}=${EMPTY}
   Run Keyword If   '${i_param}' == '${EMPTY}'    Should Contain   ${i_op}
   ...              service:management-hardware.IBM:cec-service-processor:
   ...      ELSE   Should Contain   ${i_op}  service:wbem:https
   ...      AND   service:management-hardware.IBM:cec-service-processor
