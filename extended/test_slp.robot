*** Settings ***
Library         OperatingSystem

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${parameter}        management-hardware.IBM

***Test Cases ***
Find Services
    [Documentation]    Find services supported by system.
    ${op}              Run SLP command   ${service_types}
    Verify output      ${op}

Find Service Agents
    [Documentation]   Find Service agents.
    ${op}             Run SLP command   ${service_agents}   ${parameter}
    Verify agents     ${op}

*** Keywords ***
Run SLP Command
    [Documentation]   Run SLPTool command
    [Arguments]       ${i_cmd}
    ${rc}   ${i_op} =   Run And Return Rc And Output   slptool -u ${bmc_ip} ${i_cmd}
    Log             ${i_op}
    [Return]        ${i_op}

Verify output
   [Arguments]      ${i_op}
   Should Contain   ${i_op}   	service:wbem:https
   Should Contain   ${i_op}     service:management-hardware.IBM:cec-service-processor

Verify agents
   [Arguments]      ${i_op}
   Should Contain   ${i_op}   service:management-hardware.IBM:cec-service-processor:
   
