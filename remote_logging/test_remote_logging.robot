*** Settings ***
Documentation    Remote logging test for rsyslog.

# Program arguments:
# REMOTE_LOGGING_SERVER_HOST    The host name or IP address of the remote
#                               logging server.
# REMOTE_LOGGING_SERVER_PORT    The port number for the remote logging server.

Resource         ../lib/resource.txt
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Test Remote Logging REST Interface
    [Documentation]  Configure and default the remote logging REST
    ...              object property values and verify.
    [Tags]  Test_Remote_Logging_REST_Interface

    Configure Remote Logging Server
    Configure Remote Logging Server  remote_host=${EMPTY}  remote_port=0


Verify Remote Logging Config On BMC
    [Documentation]  Configure and verify the remote logging configuration
    ...              on BMC.
    [Tags]  Verify_Remote_Logging_Config_On_BMC

    Configure Remote Logging Server

    ${ryslog_conf}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/rsyslog.d/server.conf

    Should Contain  ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_HOST}
    ...  msg=${REMOTE_LOGGING_SERVER_HOST} not configured.
    Should Contain  ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_PORT}
    ...  msg=${REMOTE_LOGGING_SERVER_PORT} not configured.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${REMOTE_LOGGING_SERVER_HOST}
    Should Not Be Empty  ${REMOTE_LOGGING_SERVER_PORT}
    Ping Host  ${REMOTE_LOGGING_SERVER_HOST}
    Remote Logging Interface Should Exist


Remote Logging Interface Should Exist
    [Documentation]  Check that the remote logging URI exist.

    ${resp}=  OpenBMC Get Request  ${REMOTE_LOGGING_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Configure Remote Logging Server
    [Documentation]  Configure the remote logging server on BMC.
    [Arguments]  ${remote_host}=${REMOTE_LOGGING_SERVER_HOST}
    ...          ${remote_port}=${REMOTE_LOGGING_SERVER_PORT}

    # Description of argument(s):
    # remote_host  Remote ryslog server address (e.g. "xx.xx.xx.xx").
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
