*** Settings ***
Documentation       This testsuite is for testing SSL connection to OpenBMC.

Resource            ../../lib/rest_client.robot
Resource            ../../lib/resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Teardown      Delete All Sessions
Test Teardown       FFDC On Test Case Fail


*** Test Cases ***
Test SSL Connection
    [Documentation]    This testcase is for testing the SSL connection to the
    ...    OpenBMC machine.
    [Tags]    test_ssl_connection
    Initialize OpenBMC

Test Non SSL Connection To Port 80
    [Documentation]    Test that OpenBMC machine does not accept the non-secure
    ...    http connection at port 80 and would expect a connection error.
    [Tags]    test_non_ssl_connection_to_port_80

    Create Session    openbmc    http://${OPENBMC_HOST}/    timeout=3
    Run Keyword And Expect Error    *ConnectTimeoutError*    GET On Session    openbmc    /list

Test Non SSL Connection To HTTPS Port
    [Documentation]    Test that OpenBmc does not accept the non-secure
    ...    http connection at port ${HTTPS_PORT} and would expect a connection error.
    [Tags]    test_non_ssl_connection_to_https_port

    Create Session    openbmc    http://${OPENBMC_HOST}:${HTTPS_PORT}/    timeout=3
    Run Keyword And Expect Error    ConnectionError*    GET On Session    openbmc    /list
