*** Settings ***
Documentation  Verify Auto Restart policy for set of mission critical
...            services needed for functioning on BMC.

Resource         ../lib/resource.txt
Resource         ../lib/connection_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/utils.robot

Suite Setup      Open Connection And Log In
Suite Teardown   Close All Connections
Test Teardown    FFDC On Test Case Fail

*** Variables ***
${LOG_SERVICE}  xyz.openbmc_project.Logging.service

*** Test Cases ***

Verify OpenBMC Services Auto Restart Policy
    [Documentation]  Kill active services and expect auto restart.
    [Tags]  Verify_OpenBMC_Services_Auto_Restart_Policy
    # The services listed below restart policy should be "always"
    # Command output:
    # systemctl -p Restart show xyz.openbmc_project.Logging.service | cat
    # Restart=always
    @{services}=
    ...  Create List  xyz.openbmc_project.Logging.service
    ...               xyz.openbmc_project.ObjectMapper.service
    ...               xyz.openbmc_project.State.BMC.service
    ...               xyz.openbmc_project.State.Chassis.service
    ...               xyz.openbmc_project.State.Host.service
    : FOR  ${SERVICE}  IN  @{services}
    \    Check Service Autorestart  ${SERVICE}


Kill Services And Expect Service Restart
    [Documentation]  Kill the service and it must restart.
    [Tags]  Kill_Services_And_Expect_Service_Restart

    # Get the MainPID and service state.
    ${MainPID}=  Get Service Attribute  MainPID  ${LOG_SERVICE}
    Should Not Be Equal  ${0}  ${MainPID}
    ...  msg=Logging service not restarted.

    ${ActiveState}=  Get Service Attribute  ActiveState  ${LOG_SERVICE}
    Should Be Equal  active  ${ActiveState}
    ...  msg=Logging Service not in active state.

    BMC Execute Command  kill -9 ${MainPID}
    Sleep  10s  reason=Wait for service to restart.

    ${MainPID}=  Get Service Attribute  MainPID  ${LOG_SERVICE}
    Should Not Be Equal  ${0}  ${MainPID}
    ...  msg=Logging service not restarted.

    ${ActiveState}=  Get Service Attribute  ActiveState  ${LOG_SERVICE}
    Should Be Equal  active  ${ActiveState}
    ...  msg=Logging service not in active state.


*** Keywords ***

Check Service Autorestart
    [Documentation]  Check if given policy is "always".
    [Arguments]  ${servicename}
    # servicename  Qualified service name
    ${restart_policy}=  Get Service Attribute  Restart  ${servicename}
    Should Be Equal  always  ${restart_policy}
    ...  msg=Incorrect policy for ${servicename}


Get Service Attribute
    [Documentation]  Get service attribute policy output.
    [Arguments]  ${option}  ${servicename}
    # option  systemctl supported options
    # servicename  Qualified service name
    ${cmd}=  Set Variable
    ...  systemctl -p ${option} show ${servicename} | cut -d = -f2
    ${attr}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    [Return]  ${attr}
