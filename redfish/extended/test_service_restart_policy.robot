*** Settings ***
Documentation  Verify Auto Restart policy for set of mission critical
...            services needed for functioning on BMC.

Resource         ../../lib/resource.robot
Resource         ../../lib/connection_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/utils.robot
Library          ../../data/platform_variables.py

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
    ...               xyz.openbmc_project.State.Chassis@0.service
    ...               xyz.openbmc_project.State.Host@0.service
    FOR  ${SERVICE}  IN  @{services}
      Check Service Autorestart  ${SERVICE}
    END


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

Kill The List Of Services And Expect Killed Service Gets Restarted
    [Documentation]  Kill the given services and expect again services get restarted automatically.
    [Tags]  Kill_The_List_Of_Services_And_Expect_Killed_Service_Gets_Restarted

    # Create a list of services in respective server model python file
    # like romulus.py, witherspoon.py on openbmc-test-automation/data directory etc.
    # Example of creating a list of services in their respective server model python file
    # SERVICES = {
    # "BMC_SERVICES": ['xyz.openbmc_project.Logging.service', 'xyz.openbmc_project.ObjectMapper.service',
    # 'xyz.openbmc_project.State.BMC.service', 'xyz.openbmc_project.State.Chassis.service',
    # 'xyz.openbmc_project.State.Host.service']

    @{auto_restart_policy_always_services}=  Create List
    @{incorrect_auto_restart_policy_services}=  Create List
    @{service_not_started}=  Create List

    # Creating an list of services which needs to be validated.

    ${services}=  Get Service Restart Policy Services  ${OPENBMC_MODEL}
    ${service_list}=  Get From Dictionary  ${services}  BMC_SERVICES
    ${length_services}=  Get Length  ${service_list}

    # From service list it will check service auto-restart policy
    # If incorrect those services will be appended to incorrect_auto_restart_policy_services list
    # Proper restart policy services will be appended to auto_restart_policy_always_services list.

    FOR  ${service}  IN  @{service_list}
        ${service_status}=  Run Keyword And Return Status  Check Service Autorestart  ${service}
        IF  ${service_status} == False
            Append To List  ${incorrect_auto_restart_policy_services}  ${service}
        ELSE
            Append To List  ${auto_restart_policy_always_services}  ${service}
        END
    END

    ${length_incorrect_autorestart_policy}=  Get Length  ${incorrect_auto_restart_policy_services}
    IF  ${length_incorrect_autorestart_policy} != 0 and ${length_incorrect_autorestart_policy} == ${length_services}
        Log  ${incorrect_auto_restart_policy_services}
        Fail  msg=All the given services have incorrect auto-restart policy.
    ELSE IF  ${length_incorrect_autorestart_policy} != 0 and ${length_incorrect_autorestart_policy} != ${length_services}
        Log  ${incorrect_auto_restart_policy_services}
        Run Keyword And Continue On Failure  Fail  msg=Listed services are having incorrect auto-restart policy.
    END

    # This will get process id and check the service active state before killing the services.
    # If service process id was 0 or service was not in active state then those services will get
    # appended to service_not_started list.
    # Only services with process ID and in active state get killed and checked whether
    # they automatically restart and put into active state.

    FOR  ${service}  IN  @{auto_restart_policy_always_services}
      ${Old_MainPID}=  Get Service Attribute  MainPID  ${service}
      ${ActiveState}=  Get Service Attribute  ActiveState  ${service}
      ${main_pid_status}=  Run Keyword And Return Status  Should Not Be Equal  ${0}  ${Old_MainPID}
      ${active_state_status}=  Run Keyword And Return Status  Should Be Equal  active  ${ActiveState}
      IF  ${main_pid_status} == False or ${active_state_status} == False
          Append To List  ${service_not_started}  ${service}
          CONTINUE
      END

      BMC Execute Command  kill -9 ${Old_MainPID}
      Sleep  10s  reason=Wait for service to restart.

      ${New_MainPID}=  Get Service Attribute  MainPID  ${service}
      Run Keyword And Continue On Failure  Should Not Be Equal  ${0}  ${New_MainPID}
      ...  msg=${service} service not restarted.
      Run Keyword And Continue On Failure  Should Not Be Equal  ${Old_MainPID}  ${New_MainPID}
      ...  msg=Old process ID is mapped to ${service} service after service restart..

      ${ActiveState}=  Get Service Attribute  ActiveState  ${service}
      Run Keyword And Continue On Failure  Should Be Equal  active  ${ActiveState}
      ...  msg=${service} service not in active state.
    END

    ${length_service_not_started}=  Get Length  ${service_not_started}
    ${incorrect_services}=  Evaluate  ${length_incorrect_autorestart_policy} + ${length_service_not_started}

    IF  ${incorrect_services} == ${length_services} and ${length_service_not_started} != 0
        Log  ${service_not_started}
        Fail  msg=All the services were either not started or not in active state by default.
    ELSE IF  ${incorrect_services} != ${length_services} and ${length_service_not_started} != 0
        Log  ${service_not_started}
        Fail  msg=Few listed services were either not started or not in active state by default.
    END

*** Keywords ***

Check Service Autorestart
    [Documentation]  Check if given policy is "always".
    [Arguments]  ${servicename}
    # servicename  Qualified service name
    ${restart_policy}=  Get Service Attribute  Restart  ${servicename}
    Should Be Equal  always  ${restart_policy}
    ...  msg=Incorrect policy for ${servicename}
