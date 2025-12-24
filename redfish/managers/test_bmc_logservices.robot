*** Settings ***
Documentation    Test BMC Manager functionality.

Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Redfish.Login
Test Teardown    Test Teardown Execution

Test Tags        Test_BMC_LogService


*** Test Cases ***

Verify LogService Unsupported Methods
    [Documentation]  Verify logservice unsupported methods.
    [Tags]  Verify_LogService_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=${REDFISH_BASE_URI}Managers/bmc/LogServices

Verify Journal LogService Unsupported Methods
    [Documentation]  Verify journal logservice unsupported methods.
    [Tags]  Verify_Journal_LogService_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=${REDFISH_BASE_URI}Managers/bmc/LogServices/Journal

Verify BMC Journal Entries Unsupported Methods
    [Documentation]  Verify bmc journal entries unsupported methods.
    [Tags]  Verify_BMC_Journal_Entries_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=${REDFISH_BASE_URI}Managers/bmc/LogServices/Journal/Entries


*** Keywords ***

Verify Supported And Unsupported Methods
    [Documentation]  Verify supported and unsupported methods for given uri.
    [Arguments]   ${uri}

    # Description of argument(s):
    # uri                 The uri to be tested.

    # GET operation on logservices.
    Redfish.Get    ${uri}
    ...    valid_status_codes=[${HTTP_OK}]

    # Put operation on logservices.
    Redfish.Put  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Post operation on logservices.
    Redfish.Post  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Delete operation on logservices.
    Redfish.Delete  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Patch operation on logservices.
    Redfish.Patch  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run Keyword And Ignore Error  Redfish.Logout
    FFDC On Test Case Fail