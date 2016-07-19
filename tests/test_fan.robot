*** Settings ***
Documentation     This testsuite is for testing fan interface for openbmc
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot

*** Test Cases ***
Test place holder dummy
   [Documentation]   TODO Implement test fan use cases
   ...               Added reboot_tests tag to ignore this execution
   [Tags]            reboot_tests
   Log    This is a dummy test case.. Ignore
