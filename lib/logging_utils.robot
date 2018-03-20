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
    [Arguments]   ${quiet}=1

    ${status}  ${error_logs}=  Run Keyword And Ignore Error  Read Properties
    ...  /xyz/openbmc_project/logging/entry/enumerate  quiet=${quiet}

    ${empty_dict}=  Create Dictionary
    Return From Keyword If  '${status}' == 'FAIL'  ${empty_dict}
    [Return]  ${error_logs}


Get Error Logs Count
    [Documentation]  Return the number of BMC error logs.  Optionally
    ...  display the error logs on the console.
    [Arguments]   ${show_logs}=0

    # Description of argument(s):
    # show_logs   Optional parameter to control the displaying of
    #             error logs.  If show_logs=1 the error logs are
    #             displayed.  The default value is 0.

    ${error_logs}=  Get Error Logs

    # Determine the number of error logs.
    ${number_of_logs}=  Get Length  ${error_logs}

    # Return 0 if no error logs.
    Run Keyword If  ${number_of_logs} == 0  Return From Keyword  0

    # Display the error logs if show_logs=1.
    Run Keyword If  '${show_logs}' == '1'
    ...  Show BMC Error Logs Message  ${error_logs}

    [Return]  ${number_of_logs}


Show BMC Error Logs Message
    [Documentation]  Display the Message field of the BMC error logs.
    [Arguments]   ${error_logs}

    # Description of argument(s):
    # error_logs  A dictionaly which contains error log entries.  The is
    #             usually obtained by calling Get Error Logs.

    Log To Console  \n-------------- BMC ERROR LOGS -----------------------

    :FOR  ${error_log}  IN  @{error_logs}
    \  Rpvars  error_logs['${error_log}']['Message']

    Log To Console  ----------- END BMC ERROR LOGS ----------------------
