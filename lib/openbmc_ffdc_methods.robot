*** Settings ***
Documentation      Methods to execute commands on BMC and collect
...                data to a list of FFDC files

Resource           openbmc_ffdc_utils.robot
Resource           rest_client.robot
Resource           utils.robot

*** Keywords ***

################################################################
# Method : Call FFDC Methods                                   #
#          Execute the user define keywords from the FFDC List #
#          Unlike any other keywords this will call into the   #
#          list of keywords defined in the FFDC list at one go #
################################################################

Call FFDC Methods
    [Documentation]   Calls into FFDC Keyword index list

    @{entries}=     Get ffdc method index
    :FOR  ${index}  IN   @{entries}
    \     Method Call Keyword List   ${index}


Method Call Keyword List
    [Documentation]   Iterate the list through keyword index
    [Arguments]       ${index}

    @{method_list}=      Get ffdc method call   ${index}
    :FOR  ${method}  IN  @{method_list}
    \    Execute Keyword Method   ${method[1]}


Execute Keyword Method
    [Documentation]   Calls into BMC method keywords. Don't let one
    ...               failure skips the remaining. Get whatever data
    ...               it could gather at worse case scenario.
    [Arguments]   ${keyword_name}

    Run Keyword And Continue On Failure   ${keyword_name}


################################################################
# Method : BMC FFDC Manifest                                   #
#          Execute command on BMC and write to ffdc_report.txt #
################################################################

BMC FFDC Manifest
    [Documentation]    Get the commands index for the FFDC_BMC_CMD,
    ...                login to BMC and execute commands.
    Open Connection And Log In

    @{entries}=     Get ffdc cmd index
    :FOR  ${index}  IN   @{entries}
    \     Iterate BMC Command List Pairs   ${index}


Iterate BMC Command List Pairs
    [Documentation]    Feed in key pair list from dictionary to execute
    [Arguments]        ${key_index}

    @{cmd_list}=      Get ffdc bmc cmd    ${key_index}
    Set Suite Variable   ${ENTRY_INDEX}   ${key_index}
    :FOR  ${cmd}  IN  @{cmd_list}
    \    Execute Command and Write FFDC    ${cmd[0]}  ${cmd[1]}


Execute Command and Write FFDC
    [Documentation]    Execute command on BMC or OS and write to ffdc
    ...                By default to ffdc_report.txt file else to
    ...                specified file path.
    [Arguments]        ${key_index}
    ...                ${cmd}
    ...                ${logpath}=${FFDC_FILE_PATH}

    Run Keyword If   '${logpath}' == '${FFDC_FILE_PATH}'
    ...    Write Cmd Output to FFDC File   ${key_index}  ${cmd}

    ${stdout}  ${stderr}=
    ...   Execute Command    ${cmd}   return_stderr=True

    # Write stdout data on success and error msg to the file on failure
    Run Keyword If   '${stderr}' == '${EMPTY}'
    ...   Write Data to File   ${stdout}${\n}   ${logpath}
    ...   ELSE   Run Keyword   Write Data to File   ${stderr}${\n}   ${logpath}


################################################################
# Method : BMC FFDC Files                                      #
#          Execute command on BMC and write to individual file #
#          based on the file name pre-defined in the list      #
################################################################

BMC FFDC Files
    [Documentation]    Get the command list and iterate
    Open Connection And Log In
    @{entries}=     Get ffdc file index
    :FOR  ${index}  IN   @{entries}
    \     Create File and Write Data   ${index}


Create File and Write Data
    [Documentation]    Create files to current FFDC log directory,
    ...                executes command and write to corresponding
    ...                file name in the current FFDC directory.
    [Arguments]        ${key_index}

    @{cmd_list}=      Get ffdc bmc file   ${key_index}
    :FOR  ${cmd}  IN  @{cmd_list}
    \   ${logpath}=  Catenate  SEPARATOR=   ${LOG_PREFIX}   ${cmd[0]}
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}   ${logpath}


################################################################
# Method : Log Test Case Status                                #
#          Creates test result history footprint for reference #
################################################################

Log Test Case Status
    [Documentation]    Test case execution result history.
    ...                Create once and append to this file
    ...                logs/test_history.txt
    ...                Format   Date:Test suite:Test case:Status
    ...                20160909214053719992:Test Warmreset:Test WarmReset via REST:FAIL
    Create Directory   ${FFDC_LOG_PATH}

    ${exist}=   Run Keyword and Return Status
    ...   OperatingSystem.File Should Exist   ${TEST_HISTORY}

    Run Keyword If  '${exist}' == '${False}'
    ...   Create File  ${TEST_HISTORY}

    ${cur_time}=      Get Current Time Stamp

    Append To File    ${TEST_HISTORY}
    ...   ${cur_time}:${SUITE_NAME}:${TEST_NAME}:${TEST_STATUS}${\n}


Log FFDC Get Requests
    [Documentation]    Create file in current FFDC log directory.
    ...                Do openbmc get request and write to
    ...                corresponding file name.
    ...                JSON pretty print for logging to file.
    [Arguments]        ${key_index}

    @{cmd_list}=  Get ffdc get request  ${key_index}
    :FOR  ${cmd}  IN  @{cmd_list}
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}
    \   ${resp}=  OpenBMC Get Request  ${cmd[1]}
    \   ${status}=    Run Keyword and Return Status
    ...   Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    \   Run Keyword If   '${status}' == '${False}'  Continue For Loop
    \   ${jsondata}=  to json  ${resp.content}    pretty_print=True
    \   Write Data to File  ${\n}${jsondata}${\n}  ${logpath}


BMC FFDC Get Requests
    [Documentation]    Get the command list and iterate
    Open Connection And Log In
    @{entries}=  Get ffdc get request index
    :FOR  ${index}  IN  @{entries}
    \   Log FFDC Get Requests   ${index}


Log OS ALL DISTROS FFDC
    [Documentation]    Create file in current FFDC log directory.
    ...                Executes OS command and write to
    ...                corresponding file name.
    [Arguments]        ${key_index}

    @{cmd_list}=  get ffdc os all distros call  ${key_index}
    :FOR  ${cmd}  IN  @{cmd_list}
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}   ${logpath}


Log OS SPECIFIC DISTRO FFDC
    [Documentation]    Create file in current FFDC log directory.
    ...                Executes OS command and write to
    ...                corresponding file name.
    [Arguments]        ${key_index}  ${linux_distro}

    @{cmd_list}=  get ffdc os distro call  ${key_index}  ${linux_distro}
    :FOR  ${cmd}  IN  @{cmd_list}
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}   ${logpath}



OS FFDC Files
    [Documentation]    Get the command list and iterate
    [Arguments]  ${OS_HOST}=${OS_HOST}  ${OS_USERNAME}=${OS_USERNAME}
    ...   ${OS_PASSWORD}=${OS_PASSWORD}

    Return From Keyword If  '${OS_HOST}' == '${EMPTY}'
    ...   No OS Host Provided

    # If can't ping, return
    ${rc}=  Run Keyword and Return Status  Ping Host  ${OS_HOST}
    Return From Keyword If  '${rc}' == '${False}'
    ...   Could not ping OS

    Open Connection And Log In  host=${OS_HOST}  username=${OS_USERNAME}
    ...   password=${OS_PASSWORD}

    ${output}  ${stderr}  ${rc}=  Execute Command  uptime  return_stderr=True
    ...   return_rc=True

    # If the return code returned by "Execute Command" is non-zero, return
    Return From Keyword If  '${rc}' != '${0}'
    ...   Could not connect to OS

    @{entries}=  Get ffdc os all distros index
    :FOR  ${index}  IN  @{entries}
    \   Log OS ALL DISTROS FFDC  ${index}

    ${linux_distro}=  Execute Command
    ...   . /etc/os-release; echo $ID
    ...   return_stdout=True  return_stderr=False  return_rc=False

    Return From Keyword If  '${linux_distro}' == '${EMPTY}' or '${linux_distro}' == 'None'
    ...   Could not determine Linux Distribution

    @{entries}=  Get ffdc os distro index  ${linux_distro}
    :FOR  ${index}  IN  @{entries}
    \   Log OS SPECIFIC DISTRO FFDC  ${index}  ${linux_distro}
