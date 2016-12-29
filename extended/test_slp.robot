*** Settings ***
Documentation   Find services and service agents on the system.
Library         OperatingSystem

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${parameter}        wbem
${verify}           FS
${serv_agent}       service:wbem:https://
${service_line1}    service:wbem:https
${service_line2_1}    service:management-hardware:
${service_line2_2}    cec-service-processor

***Test Cases ***
Find Services
    [Documentation]    Find services supported by system.
    ${op}=  Run SLP command   ${service_types}
    Verify Output   ${op}   ${verify}

Find Service Agents
    [Documentation]   Find Service agents.
    ${op}=  Run SLP command   ${service_agents}   ${parameter}
    Verify Output   ${op}

*** Keywords ***
Run SLP Command
    [Documentation]   Run SLPTool command
    [Arguments]       ${i_cmd}   ${i_param}=${EMPTY}
    ${rc}   ${i_op}=  Run And Return Rc And Output
    ...   slptool -u ${OPENBMC_HOST} ${i_cmd} ${i_param}
    [Return]        ${i_op}

Verify Output
   [Arguments]      ${i_op}   ${i_param}=${EMPTY}
   Run Keyword If   '${i_param}' == '${EMPTY}'    Should Contain   ${i_op}
   ...              ${serv_agent}${OPENBMC_HOST}
   ...      ELSE   Should Contain   ${i_op}  ${service_line1}
   ...      AND   ${service_line2_1}  AND ${service_line2_2}
