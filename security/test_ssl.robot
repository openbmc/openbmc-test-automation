*** Settings ***
Documentation     This testsuite is for testing SSL connection to OpenBMC.
Suite Teardown    Delete All Sessions

Resource          ../lib/rest_client.robot
Resource          ../lib/resource.robot
Resource          ../lib/openbmc_ffdc.robot
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Test SSL Connection
    [Documentation]  This testcase is for testing the SSL connection to the
    ...  OpenBMC machine.
    [Tags]  Test_SSL_Connection
    Initialize OpenBMC

Test Non SSL Connection To Port 80
    [Documentation]  Test that OpenBMC machine does not accept the non-secure
    ...  http connection at port 80 and would expect a connection error.
    [Tags]  Test_Non_SSL_Connection_To_Port_80

    Create Session  openbmc  http://${OPENBMC_HOST}/  timeout=3
    Run Keyword And Expect Error  *ConnectTimeoutError*  GET On Session  openbmc  /list

Test Non SSL Connection To HTTPS Port
    [Documentation]  Test that OpenBmc does not accept the non-secure
    ...  http connection at port ${HTTPS_PORT} and would expect a connection error.
    [Tags]  Test_Non_SSL_Connection_To_HTTPS_Port

    Create Session  openbmc  http://${OPENBMC_HOST}:${HTTPS_PORT}/  timeout=3
    Run Keyword And Expect Error  ConnectionError*  GET On Session  openbmc  /list
