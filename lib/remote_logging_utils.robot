*** Settings ***
Documentation  Remote syslog utilities keywords.

Resource         ../lib/resource.txt
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot

*** Keywords ***

Configure Remote Log Server With Parameters
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


Configure Remote Log Server
    [Documentation]  Configure the remote logging server on BMC.
    [Arguments]  ${remote_host}=${REMOTE_LOG_SERVER_HOST}
    ...          ${remote_port}=${REMOTE_LOG_SERVER_PORT}

    # Description of argument(s):
    # remote_host  The host name or IP address of the remote logging server
    #              (e.g. "xx.xx.xx.xx").
    # remote_port  Remote ryslog server port number (e.g. "514").

    @{remote_parm_list}=  Create List  ${remote_host}  ${remote_port}

    ${data}=  Create Dictionary  data=@{remote_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${REMOTE_LOGGING_CONFIG_URI}/action/remote  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


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
    Should Be Empty  ${stderr}
    [Return]  ${stdout}


Get Remote Log Server Configured
    [Documentation]  Check that remote logging server is not configured.

    ${address}=  Read Attribute  ${REMOTE_LOGGING_URI}  Address
    Should Not Be Equal  ${address}  ${REMOTE_LOG_SERVER_HOST}

    ${port_number}=  Convert To Integer  ${REMOTE_LOG_SERVER_PORT}
    ${port}=  Read Attribute  ${REMOTE_LOGGING_URI}  Port
    Should Not Be Equal  ${port}  ${port_number}
