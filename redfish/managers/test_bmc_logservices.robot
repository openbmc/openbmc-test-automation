*** Settings ***
Documentation    Test BMC Manager functionality.

Resource         ../../lib/openbmc_ffdc.robot
Library          Collections

Test Setup       Redfish.Login
Test Teardown    Test Teardown Execution

Test Tags        Test_BMC_LogService

*** Variables ***

@{member_entry_attributes}=    @odata.id  @odata.type  Created  EntryType  Id  Name  OemRecordFormat  Severity

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

Verify Log Service Defaults
    [Documentation]  Verify log service defaults.
    [Tags]  Verify_Log_Service_Defaults

    # Get log service default properties
    ${logservice}=    Redfish.Get Properties    /redfish/v1/Managers/bmc/LogServices
    ...    valid_status_codes=[${HTTP_OK}]

    # Validate log service properties
    Valid Value  logservice['@odata.id']  ['/redfish/v1/Managers/bmc/LogServices']
    Valid Value  logservice['Name']  ['Open BMC Log Services Collection']
    Length Should Be  ${logservice["Members"]}  ${logservice["Members@odata.count"]}

Verify LogService Journal Defaults
    [Documentation]  Verify logservice journal defaults.
    [Tags]  Verify_LogService_Journal_Defaults

    # Get log service journal default properties
    ${logservice_journal}=    Redfish.Get Properties    /redfish/v1/Managers/bmc/LogServices/Journal
    ...    valid_status_codes=[${HTTP_OK}]

    # Validate log service journal properties
    Valid Value  logservice_journal['@odata.id']  ['/redfish/v1/Managers/bmc/LogServices/Journal']
    Valid Value  logservice_journal['Name']  ['Open BMC Journal Log Service']
    Valid Value  logservice_journal['Id']  ['Journal']
    Valid Value  logservice_journal['OverWritePolicy']  ['WrapsWhenFull']
    Valid Value  logservice_journal['Entries']['@odata.id']  ['/redfish/v1/Managers/bmc/LogServices/Journal/Entries']

Verify LogService Journal Entries Defaults
    [Documentation]  Verify logservice journal entries defaults.
    [Tags]  Verify_LogService_Journal_Entries_Defaults

    # Get log service journal entries default properties
    ${logservice_journal_entries}=    Redfish.Get Properties    /redfish/v1/Managers/bmc/LogServices/Journal/Entries
    ...    valid_status_codes=[${HTTP_OK}]

    # Validate log service journal entries properties
    Valid Value  logservice_journal_entries['@odata.id']  ['/redfish/v1/Managers/bmc/LogServices/Journal/Entries']
    Valid Value  logservice_journal_entries['Description']  ['Collection of BMC Journal Entries']

    # Validate each members required attributes
    ${member_count}=    Get Length    ${logservice_journal_entries["Members"]}
    Run Keyword If    ${member_count} > 0
    ...    Validate Journal Entry Members    ${logservice_journal_entries["Members"]}

*** Keywords ***

Verify Supported And Unsupported Methods
    [Documentation]  Verify supported and unsupported methods for given uri.
    [Arguments]   ${uri}

    # Description of argument(s):
    # uri               The uri to be tested.

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

Validate Journal Entry Members
    [Documentation]  Validate required properties exist for each journal entry member.
    [Arguments]    ${members_collection}

    # Description of argument(s):
    # members         collection of journal entry members.

    FOR    ${member}    IN    @{members_collection}
        FOR    ${attribute}    IN    @{member_entry_attributes}
            Dictionary Should Contain Key    ${member}    ${attribute}
        END
    END