*** Settings ***
Documentation    Remote logging test for rsyslog.

# Program arguments:
# REMOTE_LOG_SERVER_HOST    The host name or IP address of the remote
#                           logging server.
# REMOTE_LOG_SERVER_PORT    The port number for the remote logging server.
# REMOTE_USERNAME           The username for the remote logging server.
# REMOTE_PASSWORD           The password for the remote logging server.

Resource         ../lib/resource.txt
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Test Remote Logging REST Interface And Verify Config
    [Documentation]  Test remote logging interface and configuration.
    [Tags]  Test_Remote_Logging_REST_Interface_And_Verify_Config

    Configure Remote Logging Server
    Verify Rsyslog Config On BMC

    Configure Remote Logging Server  remote_host=${EMPTY}  remote_port=0
    Verify Rsyslog Config On BMC  remote_host=remote-host  remote_port=port


Verfiy BMC Journald Synced To Remote Logging Server
    [Documentation]  Check that BMC journald is sync to remote rsyslog.
    [Tags]  Verfiy_BMC_Journald_Synced_To_Remote_Logging_Server

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  /bin/hostname
    Remove Journald Logs

    Configure Remote Logging Server
    # Take a couple second to restart rsyslog service.
    Sleep  3s

    # Restart BMC dump service and get the last entry of the journald.
    # Example:
    # Aug 31 15:16:54 wsbmc123 systemd[1]: Started Phosphor Dump Manager
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Dump.Manager.service

    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | tail -1

    ${cmd}=  Catenate  cat /var/log/syslog|grep ${hostname} | tail -1
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    Should Be Equal As Strings   ${bmc_journald}  ${remote_journald}
    ...  msg=Journald logs BMC credentials/password ${OPENBMC_PASSWORD}.


Verify BMC Journald Doesnt Log Any Credential Data
    [Documentation]  Check that BMC journald doesnt log any credential data.
    [Tags]  Verify_BMC_Journald_Doesnt_Log_Any_Credential_Data

    Open Connection And Log In
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -o json-pretty | cat

    Should Not Contain Any  ${bmc_journald}  ${OPENBMC_PASSWORD}
    ...  msg=${bmc_journald} contains ${OPENBMC_PASSWORD} data logged.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${REMOTE_LOG_SERVER_HOST}
    Should Not Be Empty  ${REMOTE_LOG_SERVER_PORT}
    Should Not Be Empty  ${REMOTE_USERNAME}
    Should Not Be Empty  ${REMOTE_PASSWORD}
    Ping Host  ${REMOTE_LOG_SERVER_HOST}
    Remote Logging Server Execute Command  true
    Remote Logging Interface Should Exist


Remote Logging Interface Should Exist
    [Documentation]  Check that the remote logging URI exist.

    ${resp}=  OpenBMC Get Request  ${REMOTE_LOGGING_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Configure Remote Logging Server
    [Documentation]  Configure the remote logging server on BMC.
    [Arguments]  ${remote_host}=${REMOTE_LOG_SERVER_HOST}
    ...          ${remote_port}=${REMOTE_LOG_SERVER_PORT}

    # Description of argument(s):
    # remote_host  The host name or IP address of the remote logging server
    #              (e.g. "xx.xx.xx.xx").
    # remote_port  Remote ryslog server port number (e.g. "514").

    # Example:
    # https://xx.xx.xx.xx/xyz/openbmc_project/logging/config/remote
    # Response code:200, Content:{
    # "data": {
    #     "Address": "xx.xx.xx.xx",
    #     "Port": 514
    # },
    # "message": "200 OK",
    # "status": "ok"
    # }

    ${host_dict}=  Create Dictionary  data=${remote_host}
    Write Attribute  ${REMOTE_LOGGING_URI}  Address  data=${host_dict}
    ...  verify=${TRUE}  expected_value=${remote_host}

    ${remote_port}=  Convert To Integer  ${remote_port}
    ${port_dict}=  Create Dictionary  data=${remote_port}
    Write Attribute  ${REMOTE_LOGGING_URI}  Port  data=${port_dict}
    ...  verify=${TRUE}  expected_value=${remote_port}


Verify Rsyslog Config On BMC
    [Documentation]  Check if the rsyslog configuration on BMC is correct.
    [Arguments]  ${remote_host}=${REMOTE_LOG_SERVER_HOST}
    ...          ${remote_port}=${REMOTE_LOG_SERVER_PORT}

    # Description of argument(s):
    # remote_host  The host name or IP address of the remote logging server
    #              (e.g. "xx.xx.xx.xx").
    # remote_port  Remote ryslog server port number (e.g. "514").

    # Example:
    # Configured:
    # *.* @@xx.xx.xx.xx:514root@wsbmc123
    # By default:
    # #*.* @@remote-host:port

    ${ryslog_conf}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/rsyslog.d/server.conf

    ${config}=  Catenate  @@${remote_host}:${remote_port}

    Should Contain  ${ryslog_conf}  ${config}
    ...  msg=${remote_host} and ${remote_port} are not configured.


Remote Logging Server Execute Command
    [Documentation]  Login to remote logging server.
    [Arguments]  ${command}
    ...          ${remote_host}=${REMOTE_LOG_SERVER_HOST}
    ...          ${user_name}=${REMOTE_USERNAME}
    ...          ${user_password}=${REMOTE_PASSWORD}

    ${remote_dict}=  Create Dictionary  host=${remote_host}
    Open Connection And Log In  ${user_name}  ${user_password}
    ...  &{remote_dict}
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty   ${stderr}
    [Return]  ${stdout}

