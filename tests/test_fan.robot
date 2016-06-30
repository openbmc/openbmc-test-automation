*** Settings ***
Documentation     This testsuite is for testing fan interface for openbmc
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot

*** Test Cases ***
Test place holder dummy
   [Documentation]   Dummy Test case. We can't have an empty test case in
   ...               the testcase directory.
   Log    This is a dummy test case.. Ignore
