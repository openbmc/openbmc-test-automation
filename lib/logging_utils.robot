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


Count And Show BMC Error Logs
    [Documentation]  Return the number of BMC error logs.  Optionally
    ...  display the error logs on the console.
    [Arguments]   ${show_logs}=1

    # Description of argument(s):
    # show_logs   Optional parameter to control the displaying of
    #             error logs.  If show_logs=0 the error logs are
    #             not displayed.. The default value is 1.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}

    # Return 0 if no error logs.
    Run Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ...  Return From Keyword  0

    ${elog_entries}=  Get Logging Entry List
    # Determine the number of error logs.
    ${number_of_logs}=  Get Length  ${elog_entries}
    # Display the error logs unless show_logs=0.
    Run Keyword If  '${show_logs}' != '0'  Show BMC Error Logs  ${elog_entries}

    [Return]  ${number_of_logs}


Show BMC Error Logs
    [Documentation]  Display the BMC error logs on the Console.
    [Arguments]   ${elog_entries}

    # Description of argument(s):
    # elog_entries  A list which contains error log entries.  The list is
    #               usually obtained by calling Get Logging Entry List. For
    #               example, ${elog_entries}=  Get Logging Entry List.

    Run Keyword If  ${elog_entries} is None  Return From Keyword

    Log To Console  \n-------------- BMC ERROR LOGS -----------------------
    :FOR  ${error_log}  IN  @{elog_entries}
    \  ${message}=  Read Attribute  ${error_log}  Message
    \  Rpvars  error_log  message
    Log To Console  ----------- END BMC ERROR LOGS ----------------------
