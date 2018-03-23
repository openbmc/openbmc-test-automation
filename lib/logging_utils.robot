*** Settings ***
Documentation    Error logging utility keywords.

Resource        rest_client.robot
Variables       ../data/variables.py

*** Keywords ***

Get Logging Entry List
    [Documentation]  Get logging entry and return the object list.

    ${entry_list}=  Create List
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ${jsondata}=  To JSON  ${resp.content}

    :FOR  ${entry}  IN  @{jsondata["data"]}
    \  Continue For Loop If  '${entry.rsplit('/', 1)[1]}' == 'callout'
    \  Append To List  ${entry_list}  ${entry}

    # Logging entries list.
    # ['/xyz/openbmc_project/logging/entry/14',
    #  '/xyz/openbmc_project/logging/entry/15']
    [Return]  ${entry_list}


Logging Entry Should Exist
    [Documentation]  Find the matching message id and return the entry id.
    [Arguments]  ${message_id}

    # Description of argument(s):
    # message_id    Logging message string.
    #               Example: "xyz.openbmc_project.Common.Error.InternalFailure"

    ${elog_entries}=  Get Logging Entry List

    :FOR  ${entry}  IN  @{elog_entries}
    \  ${resp}=  Read Properties  ${entry}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${message_id}  ${resp["Message"]}
    \  Return From Keyword If  ${status} == ${TRUE}  ${entry}

    Fail  No ${message_id} logging entry found.


Get Error Logs
    [Documentation]  Return a dictionary which contains the BMC error logs.
    [Arguments]   ${quiet}=1

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console, 0 = verbose, 1 = quiet.

    #  The length of the returned dictionary indicates how many logs there are.
    #  Printing of error logs can be done with the keyword Print Error Logs,
    #  for example, Print Error Logs  ${error_logs}  Message.

    ${status}  ${error_logs}=  Run Keyword And Ignore Error  Read Properties
    ...  /xyz/openbmc_project/logging/entry/enumerate  quiet=${quiet}

    ${empty_dict}=  Create Dictionary
    Return From Keyword If  '${status}' == 'FAIL'  ${empty_dict}
    [Return]  ${error_logs}
