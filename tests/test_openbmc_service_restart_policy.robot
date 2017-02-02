*** Settings ***
Documentation  Verify Auto Restart policy for set of mission critical
...            services needed for functioning on BMC.

Resource         ../lib/resource.txt
Resource         ../lib/connection_client.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Open Connection And Log In
Suite Teardown   Close All Connections
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify OpenBMC Services Auto Restart Policy
    [Documentation]  \n Kill active services listed and expect to
    ...              restart automatically.
    [Tags]  Verify_OpenBMC_Services_Auto_Restart_Policy
    # The services listed bellow Restart policy should be "always"
    # systemctl -p Restart show xyz.openbmc_project.Logging.service | cat
    # Restart=always
    @{services}=
    ...  Create List   xyz.openbmc_project.Logging.service
    ...                xyz.openbmc_project.ObjectMapper.service
    ...                xyz.openbmc_project.State.BMC.service
    ...                xyz.openbmc_project.State.Chassis.service
    ...                xyz.openbmc_project.State.Host.service
    : FOR  ${SERVICE}  IN   @{services}
    \    Check Service Autorestart  ${SERVICE}


Kill Services And Expect Service Restart
    [Documentation]  \n Kill the service and it must restart.
    [Tags]  Kill_Services_And_Expect_Service_Restart

    # systemctl -p MainPID show xyz.openbmc_project.Logging.service | cat
    # MainPID=891
    ${MainPID}=  Execute Command On BMC
    ...  systemctl -p MainPID show xyz.openbmc_project.Logging.service | cut -d = -f2
    Should Not Be Equal  ${0}  ${MainPID}  msg=Logging service not restarted.

    # systemctl -p ActiveState show xyz.openbmc_project.Logging.service | cat
    # ActiveState=active
    ${ActiveState}=   Execute Command On BMC
    ...   systemctl -p ActiveState show xyz.openbmc_project.Logging.service| cut -d = -f2
    Should Be Equal  active  ${ActiveState}  msg=Logging Service not in active state.

    Execute Command On BMC  kill -9 ${MainPID}
    Sleep  10s  reason=Wait for service to restart.

    ${MainPID}=  Execute Command On BMC
    ...  systemctl -p MainPID show xyz.openbmc_project.Logging.service | cut -d = -f2
    Should Not Be Equal  ${0}  ${MainPID}  msg=Logging service not restarted.

    ${ActiveState}=   Execute Command On BMC
    ...   systemctl -p ActiveState show xyz.openbmc_project.Logging.service| cut -d = -f2
    Should Be Equal  active  ${ActiveState}  msg=Logging service not in active state.


*** Keywords ***

Check Service Autorestart
    [Documentation]  Check if given policy is "always".
    [Arguments]  ${servicename}
    ${restart_policy}=  Execute Command On BMC
    ...  systemctl -p Restart show ${servicename} | cut -d = -f2
    Should Be Equal  always  ${restart_policy}
    ...  msg=Restart policy for ${servicename}


Execute Command On BMC
    [Documentation]  Execute given command on BMC and return output.
    [Arguments]  ${command}
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${stdout}
