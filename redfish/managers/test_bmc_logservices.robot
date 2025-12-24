*** Settings ***
Documentation    Test BMC Manager functionality.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Library          SSHLibrary

Test Setup       Redfish.Login
Test Teardown    Test Teardown Execution

Test Tags        Test_BMC_LogService



*** Test Cases ***

Verify LogService Unsupported Methods
    [Documentation]  Verify LogService Unsupported Methods.
    [Tags]  Verify_LogService_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=/redfish/v1/Managers/bmc/LogServices

Verify Journal Log Service Unsupported Methods
    [Documentation]  Verify Journal Log Service Unsupported Methods.
    [Tags]  Verify_Journal_LogService_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=/redfish/v1/Managers/bmc/LogServices/Journal

Verify BMC Journal Entries Unsupported Methods
    [Documentation]  Verify BMC Journal Entries Unsupported Methods.
    [Tags]  Verify_BMC_Journal_Entries_Unsupported_Methods

    Verify Supported And Unsupported Methods    uri=/redfish/v1/Managers/bmc/LogServices/Journal/Entries


*** Keywords ***

Verify Supported And Unsupported Methods
    [Documentation]  Verify Supported And Unsupported Methods for given URI.
    [Arguments]   ${uri}
    # Description of argument(s):
    # uri                 The URI to be tested.

    # GET operation on LogServices
    Redfish.Get    ${uri}
    ...    valid_status_codes=[${HTTP_OK}]

    # Put operation on LogServices
    Redfish.Put  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Post operation on LogServices
    Redfish.Post  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Delete operation on LogServices
    Redfish.Delete  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]

    # Patch operation on LogServices
    Redfish.Patch  ${uri}
    ...  valid_status_codes=[${HTTP_METHOD_NOT_ALLOWED}]


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run Keyword And Ignore Error  Redfish.Logout
    FFDC On Test Case Fail