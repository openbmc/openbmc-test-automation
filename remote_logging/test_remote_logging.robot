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
    [Documentation]  Configure and delete the remote logging REST object.
    [Tags]  Test_Remote_Logging_REST_Interface

    Configure Remote Logging Server
    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Delete Request  ${REMOTE_LOGGING_URI}${1}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Verify Remote Logging REST Interface Config
    [Documentation]  Configure and verify the remote logging configuration.
    [Tags]  Verify_Remote_Logging_REST_Interface_Config

    Configure Remote Logging Server

    ${ryslog_conf} =  BMC Execute Command  cat /etc/rsyslog.d/server.conf
    Should Contain   ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_HOST}
    Should Contain   ${ryslog_conf}  ${REMOTE_LOGGING_SERVER_PORT}


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
    [Documentation]  Configure and verify the remote logging REST interface.

    ${remote_ip}=  Create Dictionary  data=${REMOTE_LOGGING_SERVER_HOST}
    ${resp}=  OpenBMC Put Request  ${REMOTE_LOGGING}attr/Address
    ...  data=${remote_ip}

    ${remote_port}=  Create Dictionary  data=${REMOTE_LOGGING_SERVER_PORT}
    ${resp}=  OpenBMC Put Request  ${REMOTE_LOGGING}attr/Port
    ...  data=${remote_port}

    ${data}=  Read Attribute  ${REMOTE_LOGGING}  ${1}
    Should Be Equal As Strings  ${data[Address]}  ${REMOTE_LOGGING_SERVER_HOST}
    Should Be Equal As Strings  ${data[Port]}  ${REMOTE_LOGGING_SERVER_PORT}

