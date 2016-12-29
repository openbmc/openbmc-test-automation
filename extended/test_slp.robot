*** Settings ***
Documentation   Find services and service agents on the system.
   ...   #Note  We are not testing it on IPv6 as we don't have 
   ...   active interface to configure IPv6.
Library         OperatingSystem
Library         Collections

*** Variables ***
${service_types}    findsrvtypes
${service_agents}   findsrvs
${parameter}        wbem
${verify}           FS
${serv_agent}       service:wbem:https://
${service_line1}    service:wbem:https
${service_line2}    cec-service-processor

***Test Cases ***
Find Services
    [Tags]           Find_Sevrices
    [Documentation]  Find services supported by system.
    ${op}=  Run SLP command  ${service_types}
    Verify Output  ${op}  ${verify}

Find Service Agents
    [Tags]           Find_Sevrice_Agents
    [Documentation]  Find Service agents.
    ${op}=  Run SLP command  ${service_agents}  ${parameter}
    Verify Output  ${op}

*** Keywords ***
Run SLP Command
    [Documentation]  Run SLPTool command and return output.
    [Arguments]      ${cmd}  ${param}=${EMPTY}
    # Description of arguments:
    # cmd  The SLP command to be run.
    # param  The SLP command parameters.

    ${rc}  ${output}=  Run And Return Rc And Output
    ...   slptool -u ${OPENBMC_HOST} ${cmd} ${param}
    [Return]        ${output}

Verify Output
    [Arguments]      ${op}  ${param}=${EMPTY}
    # Description of arguments:
    # op  The SLP tool output to be verified.
    # param  The parameter used to construct a logic.
    # Example of output
    # <service:wbem:https://9.3.40.37:5989>

   Run Keyword If  '${param}' == '${EMPTY}'  Should Contain  ${op}
   ...   ${serv_agent}${OPENBMC_HOST}  msg=Expected process info missing.
   ...   ELSE
   ...   Run Keywords  Should Contain  ${op}  ${service_line1}
   ...   AND  Should Contain  ${op}  ${service_line2}
   ...   msg=Expected service missing.
