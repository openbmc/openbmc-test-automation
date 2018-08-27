*** Settings ***
Documentation    Remote logging test for rsyslog.

Resource         ../lib/resource.txt
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Test Remote Logging REST Interface
    [Documentation]  Verify Configure and default the remote logging REST
    ...              object property values.
    [Tags]  Test_Remote_Logging_REST_Interface

    Configure Remote Logging Server
    Configure Remote Logging Server  remote_addr=${EMPTY}  remote_port=0


Verify Remote Logging Config On BMC
    [Documentation]  Configure and verify the remote logging configuration
    ...              on BMC.
    [Tags]  Verify_Remote_Logging_Config_On_BMC

    Configure Remote Logging Server

    ${ryslog_conf}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/rsyslog.d/server.conf

    Should Contain   ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_HOST}
    ...  msg=${REMOTE_LOGGING_SERVER_HOST} not configured.
    Should Contain   ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_PORT}
    ...  msg=${REMOTE_LOGGING_SERVER_PORT} not configured.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${REMOTE_LOGGING_SERVER_HOST}
    Should Not Be Empty  ${REMOTE_LOGGING_SERVER_PORT}
    Ping Host  ${REMOTE_LOGGING_SERVER_HOST}
    Remote Logging Interface Should Exist


Remote Logging Interface Should Exist
    [Documentation]  Check if the remote logging URI exist.

    ${resp}=  OpenBMC Get Request  ${REMOTE_LOGGING_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Configure Remote Logging Server
    [Documentation]  Configure the remote logging server on BMC.
    [Arguments]  ${remote_addr}=${REMOTE_LOGGING_SERVER_HOST}
    ...          ${remote_port}=${REMOTE_LOGGING_SERVER_PORT}

    # Description of argument(s):
    # remote_addr  Remote ryslog server address.
    # remote_port  Remote ryslog server port number.

    # Example:
    # https://xx.xx.xx.xx/xyz/openbmc_project/logging/config/remote
    # Response code:200, Content:{
    # "data": {
    #     "Address": "9.3.84.87",
    #     "Port": 514
    # },
    # "message": "200 OK",
    # "status": "ok"
    # }

    ${remote_addr_dict}=  Create Dictionary  data=${remote_addr}
    ${resp}=  OpenBMC Put Request  ${REMOTE_LOGGING_URI}attr/Address
    ...  data=${remote_addr_dict}

    ${port_dict}=  Create Dictionary  data=${remote_port}
    ${resp}=  OpenBMC Put Request  ${REMOTE_LOGGING_URI}attr/Port
    ...  data=${port_dict}

    ${resp}=  OpenBMC Get Request  ${REMOTE_LOGGING_URI.strip("/")}
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${jsondata['data']['Address']}  ${remote_addr}
    Should Be Equal As Strings  ${jsondata['data']['Port']}  ${remote_port}

