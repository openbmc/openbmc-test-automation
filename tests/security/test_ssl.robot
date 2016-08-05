*** Settings ***
Documentation     This testsuite is for testing SSL connection to OpenBMC
Suite Teardown    Delete All Sessions

Resource          ../../lib/rest_client.robot
Resource          ../../lib/resource.txt

Suite Setup       Initialize REST setup

*** Test Cases ***
Test SSL Connection
    [Documentation]     This testcase is for testing the SSL connection to the
    ...     OpenBMC machine.
    Initialize OpenBMC

Test non-SSL Connection to port 80
    [Documentation]     This testcase is for test to check OpenBMC machine
    ...     will not accepts the non-secure connection that is with http to
    ...     port 80 and expect a connection error
    Create Session    openbmc    ${AUTH_URI}    timeout=3
    Run Keyword And Expect Error    ConnectionError*   
    ...    Get Request    openbmc   /list

Test non-SSL Connection to port 443
    [Documentation]     This testcase is for test to check OpenBMC machine
    ...     will not accepts the non-secure connection that is with http to
    ...     port 443 and expect 400 in response

    Run Keyword If   '${HTTPS_PORT}' == '${EMPTY}' 
    ...  Create Session   openbmc   http://${OPENBMC_HOST}:443
    ...  ELSE   Create Session  openbmc   http://${OPENBMC_HOST}:${HTTPS_PORT}

    ${resp}=    Get Request    openbmc   /list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_BAD_REQUEST}
    Should Be Equal     ${resp.content}     Bad Request
