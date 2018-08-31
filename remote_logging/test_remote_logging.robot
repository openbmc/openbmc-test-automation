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
Library          ../lib/gen_misc.py

Suite Setup      Suite Setup Execution
Test Setup       Test Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ***

${BMC_STOP_MSG}    Stopping Phosphor IPMI BT DBus Bridge
${BMC_START_MSG}   Starting Flush Journal to Persistent Storage
${BMC_BOOT_MSG}    Startup finished in

# Strings to check from journald.
${RSYSLOG_REGEX}   start|exiting on signal 15

*** Test Cases ***

Test Remote Logging REST Interface And Verify Config
    [Documentation]  Test remote logging interface and configuration.
    [Tags]  Test_Remote_Logging_REST_Interface_And_Verify_Config

    Verify Rsyslog Config On BMC

    Configure Remote Logging Server  remote_host=${EMPTY}  remote_port=0
    Verify Rsyslog Config On BMC  remote_host=remote-host  remote_port=port


Verify Rsyslog Does Not Log On BMC
    [Documentation]  Check that rsyslog journald doesn't log on BMC.
    [Tags]  Verify_Rsyslog_Does_Not_Log_On_BMC

    # Expected filter rsyslog entries.
    # Example:
    # Sep 03 13:20:07 wsbmc123 rsyslogd[3356]:  [origin software="rsyslogd" swVersion="8.29.0" x-pid="3356" x-info="http://www.rsyslog.com"] exiting on signal 15.
    # Sep 03 13:20:18 wsbmc123 rsyslogd[3364]:  [origin software="rsyslogd" swVersion="8.29.0" x-pid="3364" x-info="http://www.rsyslog.com"] start
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -b --no-pager | egrep 'rsyslog' | egrep -Ev '${RSYSLOG_REGEX}'
    ...  ignore_err=${1}

    Should Be Empty  ${bmc_journald}
    ...  msg=${bmc_journald} contains unexpected rsyslog entries.


Verfiy BMC Journald Synced To Remote Logging Server
    [Documentation]  Check that BMC journald is sync to remote rsyslog.
    [Tags]  Verfiy_BMC_Journald_Synced_To_Remote_Logging_Server

    # Restart BMC dump service and get the last entry of the journald.
    # Example:
    # Sep 03 10:09:28 wsbmc123 systemd[1]: Started Phosphor Dump Manager.
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Dump.Manager.service

    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | tail -1

    # Sep 3 10:09:28 wsbmc123 systemd[1]: Started Phosphor Dump Manager.
    ${cmd}=  Catenate  cat /var/log/syslog|grep ${bmc_hostname} | tail -1
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    # TODO: rsyslog configuration and time date template to match BMC journald.
    # Compare the BMC journlad log. Example:
    # systemd[1]: Started Phosphor Dump Manager.
    Should Be Equal As Strings   ${bmc_journald.split('${bmc_hostname}')[1]}
    ...  ${remote_journald.split('${bmc_hostname}')[1]}
    ...  msg= ${bmc_journald} doesn't match remote rsyslog:${remote_journald}.


Verify Journald Post BMC Reset
    [Documentation]  Check that BMC journald is sync'ed to remote rsyslog after
    ...              BMC reset.
    [Tags]  Verify_Journald_Post_BMC_Reset

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  hostname
    OBMC Reboot (off)

    ${cmd}=  Catenate  grep ${hostname} /var/log/syslog |
    ...  egrep '${BMC_STOP_MSG}|${BMC_START_MSG}|${BMC_BOOT_MSG}'
    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    # 1. Last reboot message to verify.
    Should Contain  ${remote_journald}  ${BMC_STOP_MSG}
    ...  msg=The remote journald doesn't contain the IPMI shutdown message: ${BMC_STOP_MSG}.

    # 2. Earliest booting message on journald.
    Should Contain  ${remote_journald}  ${BMC_START_MSG}
    ...  msg=The remote journald doesn't contain the start message: ${BMC_START_MSG}.

    # 3. Unique boot to standby message.
    # Startup finished in 9.961s (kernel) + 1min 59.039s (userspace) = 2min 9.000s
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | egrep '${BMC_BOOT_MSG}' | tail -1

    Should Contain  ${remote_journald}
    ...  ${bmc_journald.split('${hostname}')[1]}
    ...  msg=The remote journald doesn't contain the boot message: ${BMC_BOOT_MSG}.


Verify BMC Journald Contains No Credential Data
    [Documentation]  Check that BMC journald doesnt log any credential data.
    [Tags]  Verify_BMC_Journald_Contains_No_Credential_Data

    Open Connection And Log In
    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl -o json-pretty | cat

    Should Not Contain Any  ${bmc_journald}  ${OPENBMC_PASSWORD}
    ...  msg=Journald logs BMC credentials/password ${OPENBMC_PASSWORD}.


Audit BMC SSH Login And Remote Logging
    [Documentation]  Check that the SSH login to BMC is logged and synced to
    ...              remote logging server.
    [Tags]  Audit_BMC_SSH_Login_And_Remote_Logging

    ${test_host_name}  ${test_host_ip}=  Get Host Name IP

    # Aug 31 17:22:55 wsbmc123 systemd[1]: Started SSH Per-Connection Server (xx.xx.xx.xx:51292)
    Open Connection And Log In

    ${login_footprint}=  Catenate  Started SSH Per-Connection Server.*${test_host_ip}

    ${bmc_journald}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager | grep '${login_footprint}'

    ${cmd}=  Catenate SEPARATOR=  grep '${bmc_hostname}|${test_host_ip}|${login_footprint}' /var/log/syslog

    ${remote_journald}=  Remote Logging Server Execute Command  command=${cmd}

    Should Contain  ${remote_journald}  ${bmc_journald}
    ...  msg=${remote_journald} don't contain ${bmc_journald} entry.


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

    ${hostname}  ${stderr}  ${rc}=  BMC Execute Command  /bin/hostname
    Set Suite Variable  ${bmc_hostname}  ${hostname}


Test Setup Execution
    [Documentation]  Do the test setup.

    Remove Journald Logs
    ${cofig_status}=  Run Keyword And Return Status
    ...  Get Remote Log Server Configured

    Run Keyword If  ${config_status}==${FALSE}  Configure Remote Logging Server

    ${ActiveState}=  Get Service Attribute  ActiveState  rsyslog.service
    Should Be Equal  active  ${ActiveState}
    ...  msg=rsyslog logging service not in active state.


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

    # TODO: From Dev to do bump up restart service time and bulk address and
    # port update API.
    # Reference: https://github.com/ibm-openbmc/dev/issues/59
    Sleep  10s

    ${remote_port}=  Convert To Integer  ${remote_port}
    ${port_dict}=  Create Dictionary  data=${remote_port}
    Write Attribute  ${REMOTE_LOGGING_URI}  Port  data=${port_dict}
    ...  verify=${TRUE}  expected_value=${remote_port}

    # TODO: From Dev to do bump up restart service time and bulk address and
    # port update API.
    # Reference: https://github.com/ibm-openbmc/dev/issues/59
    Sleep  10s


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
    ...          ${username}=${REMOTE_USERNAME}
    ...          ${password}=${REMOTE_PASSWORD}

    # Description of argument(s):
    # command          Command line string.
    # remote_host    The host name or IP address of the remote logging server
    #                (e.g. "xx.xx.xx.xx").
    # username       Remote rsyslog server user name.
    # password       Remote rsyslog server password.

    ${remote_dict}=  Create Dictionary  host=${remote_host}
    Open Connection And Log In  ${username}  ${password}
    ...  &{remote_dict}
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty   ${stderr}
    [Return]  ${stdout}


Get Remote Log Server Configured
    [Documentation]  Check that remote logging server is not configured.

    ${address}=  Read Attribute  ${REMOTE_LOGGING_URI}  Address
    Should Not Be Equal  ${address}  ${REMOTE_LOG_SERVER_HOST}

    ${port_number}=  Convert To Integer  ${REMOTE_LOG_SERVER_PORT}
    ${port}=  Read Attribute  ${REMOTE_LOGGING_URI}  Port
    Should Not Be Equal  ${port}  ${port_number}
