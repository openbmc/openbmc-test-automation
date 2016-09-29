*** Settings ***
Documentation     This testsuite is for testing fan interface for openbmc
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Test Teardown     Log FFDC

*** Test Cases ***
Empty Fan Test
   [Documentation]   Dummy Test case. We can't have an empty test case in
   ...               the testcase directory.
   [Tags]  Empty_Fan_Test
   Log    This is a dummy test case.. Ignore
