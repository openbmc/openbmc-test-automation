*** Settings ***
Documentation     This testsuite is for testing SSL connection to OpenBMC
Suite Teardown    Delete All Sessions

Resource          ../../lib/rest_client.robot
Resource          ../../lib/resource.txt

Library           RequestsLibrary.RequestsKeywords

*** Test Cases ***
Test SSL Connection
    [Documentation]     This testcase is for testing the SSL connection to the
    ...     OpenBMC machine.
    Create Session    openbmc    https://${OPENBMC_HOST}/
    ${resp}=    Get Request    openbmc   /list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should Not Be Empty     ${jsondata}

Test non-SSL Connection - Negative
    [Documentation]     This testcase is for test to check OpenBMC machine
    ...     will not accepts the non-secure connection that is with http.
    ...     Expected Response code is - 400
    Create Session    openbmc    http://${OPENBMC_HOST}/
    Run Keyword And Expect Error    ConnectionError*   Get Request    openbmc   /list
