*** Settings ***
Documentation      Methods to execute commands on BMC and collect
...                data to a list of FFDC files

Resource           openbmc_ffdc_utils.robot
Resource           rest_client.robot
Resource           utils.robot
Library            SSHLibrary
Library            OperatingSystem
Library            Collections
Library            String
Library            gen_print.py
Library            gen_robot_keyword.py
Library            dump_utils.py

*** Keywords ***

################################################################
# Method : Call FFDC Methods                                   #
#          Execute the user define keywords from the FFDC List #
#          Unlike any other keywords this will call into the   #
#          list of keywords defined in the FFDC list at one go #
################################################################

Call FFDC Methods
    [Documentation]   Call into FFDC Keyword index list.
    [Arguments]  ${ffdc_function_list}=${EMPTY}

    # Description of argument(s):
    # ffdc_function_list  A colon-delimited list naming the kinds of FFDC that
    #                     is to be collected
    #                     (e.g. "FFDC Generic Report:BMC Specific Files").
    #                     Acceptable values can be found in the description
    #                     field of FFDC_METHOD_CALL in
    #                     lib/openbmc_ffdc_list.py.  Those values can be
    #                     obtained via a call to 'Get FFDC Method Desc' (also
    #                     from lib/openbmc_ffdc_list.py).

    @{entries}=  Get FFDC Method Index
    :FOR  ${index}  IN  @{entries}
    \    Method Call Keyword List  ${index}  ${ffdc_function_list}
    Run Key U  SSHLibrary.Close All Connections

Method Call Keyword List
    [Documentation]  Iterate the list through keyword index.
    [Arguments]  ${index}  ${ffdc_function_list}=${EMPTY}

    # Description of argument(s):
    # index               The index into the FFDC_METHOD_CALL dictionary (e.g.
    #                     'BMC LOGS').
    # ffdc_function_list  See ffdc_function_list description in
    #                     "Call FFDC Methods" (above).

    @{method_list}=  Get ffdc method call  ${index}

    # If function list is empty assign default (i.e. a list of all allowable
    # values).  In either case, convert ffdc_function_list from a string to
    # a list.
    @{ffdc_function_list}=
    ...  Run Keyword If  '${ffdc_function_list}' == '${EMPTY}'
    ...    Get FFDC Method Desc  ${index}
    ...  ELSE
    ...    Split String  ${ffdc_function_list}  separator=:

    :FOR  ${method}  IN  @{method_list}
    \    Execute Keyword Method  ${method[0]}  ${method[1]}
    ...      @{ffdc_function_list}

Execute Keyword Method
    [Documentation]  Call into BMC method keywords. Don't let one
    ...              failure skip the remaining. Get whatever data
    ...              it could gather at worse case scenario.
    [Arguments]  ${description}  ${keyword_name}  @{ffdc_function_list}

    # Description of argument(s):
    # description         The description of the FFDC to be collected.  This
    #                     would be any value returned by
    #                     'Get FFDC Method Desc' (e.g. "FFDC Generic Report").
    # keyword_name        The name of the keyword to call to collect the FFDC
    #                     data (again, see FFDC_METHOD_CALL).
    # ffdc_function_list  See ffdc_function_list description in
    #                     "Call FFDC Methods" (above).  The only difference is
    #                     in this case, it should be a list rather than a
    #                     colon-delimited value.

    ${status}  ${ret_values}=  Run Keyword And Ignore Error
    ...  List Should Contain Value  ${ffdc_function_list}  ${description}
    Run Keyword If  '${status}' != 'PASS'  Return from Keyword

    Run Key  ${keyword_name}  ignore=1

################################################################
# Method : BMC FFDC Manifest                                   #
#          Execute command on BMC and write to ffdc_report.txt #
################################################################

BMC FFDC Manifest
    [Documentation]    Get the commands index for the FFDC_BMC_CMD,
    ...                login to BMC and execute commands.

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
    ...                ${target}=BMC

    Run Keyword If   '${logpath}' == '${FFDC_FILE_PATH}'
    ...    Write Cmd Output to FFDC File   ${key_index}  ${cmd}

    ${cmd_buf}=  Catenate  ${target} Execute Command \ ${cmd} \ ignore_err=${1}
    ${status}  ${ret_values}=  Run Key  ${cmd_buf}  ignore=${1}

    ${stdout}=  Set Variable  @{ret_values}[0]
    ${stderr}=  Set Variable  @{ret_values}[1]

    # Write stdout on success and stderr/stdout to the file on failure.
    Run Keyword If  $stderr == '${EMPTY}'
    ...    Write Data To File  ${stdout}${\n}  ${logpath}
    ...  ELSE  Write Data To File
    ...    ERROR output:${\n}${stderr}${\n}Output:${\n}${stdout}${\n}
    ...    ${logpath}


################################################################
# Method : BMC FFDC Files                                      #
#          Execute command on BMC and write to individual file #
#          based on the file name pre-defined in the list      #
################################################################

BMC FFDC Files
    [Documentation]    Get the command list and iterate
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
    \   ${logpath}=  Catenate  SEPARATOR=   ${LOG_PREFIX}   ${cmd[0]}.txt
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}   ${logpath}



################################################################
# Method : Log Test Case Status                                #
#          Creates test result history footprint for reference #
################################################################

Log Test Case Status
    [Documentation]  Test case execution result history.
    ...  Create once and append to this file
    ...  logs/test_history.txt
    ...  Format   Date:Test suite:Test case:Status
    ...  20160909214053719992:Test Warmreset:Test WarmReset via REST:FAIL

    ${FFDC_DIR_PATH_STYLE}=  Get Variable Value  ${FFDC_DIR_PATH_STYLE}
    ...  ${EMPTY}
    ${FFDC_DIR_PATH}=  Get Variable Value  ${FFDC_DIR_PATH}  ${EMPTY}

    Run Keyword If  '${FFDC_DIR_PATH}' == '${EMPTY}'  Set FFDC Defaults

    Run Keyword If  '${FFDC_DIR_PATH_STYLE}' == '${1}'  Run Keywords
    ...  Set Global Variable  ${FFDC_LOG_PATH}  ${FFDC_DIR_PATH}  AND
    ...  Set Global Variable  ${TEST_HISTORY}  ${FFDC_DIR_PATH}test_history.txt

    Create Directory   ${FFDC_LOG_PATH}

    ${exist}=   Run Keyword and Return Status
    ...   OperatingSystem.File Should Exist   ${TEST_HISTORY}

    Run Keyword If  '${exist}' == '${False}'
    ...   Create File  ${TEST_HISTORY}

    Rpvars  TEST_HISTORY

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
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}.txt
    \   ${resp}=  OpenBMC Get Request  ${cmd[1]}  quiet=${1}
    \   ${status}=    Run Keyword and Return Status
    ...   Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    \   Run Keyword If   '${status}' == '${False}'  Continue For Loop
    \   ${jsondata}=  to json  ${resp.content}    pretty_print=True
    \   Write Data To File  ${\n}${jsondata}${\n}  ${logpath}


BMC FFDC Get Requests
    [Documentation]    Get the command list and iterate
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
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}.txt
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}  ${logpath}
    \   ...  target=OS


Log OS SPECIFIC DISTRO FFDC
    [Documentation]    Create file in current FFDC log directory.
    ...                Executes OS command and write to
    ...                corresponding file name.
    [Arguments]        ${key_index}  ${linux_distro}

    @{cmd_list}=  get ffdc os distro call  ${key_index}  ${linux_distro}
    :FOR  ${cmd}  IN  @{cmd_list}
    \   ${logpath}=  Catenate  SEPARATOR=  ${LOG_PREFIX}  ${cmd[0]}.txt
    \   Execute Command and Write FFDC  ${cmd[0]}  ${cmd[1]}  ${logpath}
    \   ...  target=OS


OS FFDC Files
    [Documentation]    Get the command list and iterate
    [Arguments]  ${OS_HOST}=${OS_HOST}  ${OS_USERNAME}=${OS_USERNAME}
    ...   ${OS_PASSWORD}=${OS_PASSWORD}

    Return From Keyword If  '${OS_HOST}' == '${EMPTY}'
    ...   No OS Host Provided

    # If can't ping, return
    ${rc}=  Run Keyword and Return Status  Ping Host  ${OS_HOST}
    Return From Keyword If  '${rc}' == '${False}'
    ...   Could not ping OS.

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command  uptime  ignore_err=${1}
    Return From Keyword If  '${rc}' != '${0}'  Could not connect to OS.

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  . /etc/os-release; echo $ID  ignore_err=${0}
    Set Global Variable  ${linux_distro}  ${stdout}

    Rpvars  linux_distro

    @{entries}=  Get ffdc os all distros index
    :FOR  ${index}  IN  @{entries}
    \   Log OS ALL DISTROS FFDC  ${index}

    Return From Keyword If
    ...  '${linux_distro}' == '${EMPTY}' or '${linux_distro}' == 'None'
    ...  Could not determine Linux Distribution.

    @{entries}=  Get ffdc os distro index  ${linux_distro}
    :FOR  ${index}  IN  @{entries}
    \   Log OS SPECIFIC DISTRO FFDC  ${index}  ${linux_distro}


System Inventory Files
    [Documentation]  Copy systest os_inventory files.
    # The os_inventory files are the result of running
    # systest/htx_hardbootme_test.  If these files exist
    # they are copied to the FFDC directory.
    # Global variable ffdc_dir_path is the path name of the
    # directory they are copied to.
    Copy Files  os_inventory_*.json  ${ffdc_dir_path}
    Remove Files  os_inventory_*.json


##############################################################################
SCP Coredump Files
    [Documentation]  Copy core dump file from BMC to local system.

    # Check if core dump exist in the /tmp
    ${core_files}  ${stderr}  ${rc}=  BMC Execute Command  ls /tmp/core_*
    @{core_list} =  Split String    ${core_files}
    # Copy the core files
    Run Key U  Open Connection for SCP
    :FOR  ${index}  IN  @{core_list}
    \  scp.Get File  ${index}  ${LOG_PREFIX}${index.lstrip("/tmp/")}
    # Remove the file from remote to avoid re-copying on next FFDC call
    \  BMC Execute Command  rm ${index}
    # I can't find a way to do this: scp.Close Connection

#############################################################################
SCP Dump Files
    [Documentation]  Copy all dump files from BMC to local system.

    # Check if dumps exist
    Scp Dumps  ${FFDC_DIR_PATH}  ${FFDC_PREFIX}

##############################################################################
Collect Dump Log
    [Documentation]  Collect dumps from dump entry.
    [Arguments]  ${log_prefix_path}=${LOG_PREFIX}

    ${data}=  Read Properties  ${DUMP_ENTRY_URI}/enumerate  quiet=${1}

    # Grab the list of entries from dump/entry/
    # The data shown below is the result of the "Get Dictionary Keys".
    # Example:
    # /xyz/openbmc_project/dump/entry/1
    # /xyz/openbmc_project/dump/entry/2

    ${dump_list}=  Get Dictionary Keys  ${data}

###########################################################################

Collect eSEL Log
    [Documentation]  Collect eSEL log from logging entry and convert eSEL data
    ...              to elog formatted string text file.
    [Arguments]  ${log_prefix_path}=${LOG_PREFIX}

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/enumerate  quiet=${1}
    ${status}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Return From Keyword If  '${status}' == '${False}'

    ${content}=  To Json  ${resp.content}
    # Grab the list of entries from logging/entry/
    # The data shown below is the result of the "Get Dictionary Keys".
    # Example:
    # /xyz/openbmc_project/logging/entry/1
    # /xyz/openbmc_project/logging/entry/2
    ${esel_list}=  Get Dictionary Keys  ${content['data']}

    ${logpath}=  Catenate  SEPARATOR=  ${log_prefix_path}  esel
    Create File  ${logpath}
    # Fetch data from /xyz/openbmc_project/logging/entry/1/attr/AdditionalData
    #  "ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00 "
    # Sample eSEL entry:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #    "Timestamp": 1487744317025,
    #    "AdditionalData": [
    #        "ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00 "
    #    ],
    #    "Message": "org.open_power.Error.Host.Event.Event",
    #    "Id": 1,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency"
    # }

    :FOR  ${entry_path}  IN  @{esel_list}
    # Skip reading attribute if entry URI is a callout.
    # Example: /xyz/openbmc_project/logging/entry/1/callout
    \  Continue For Loop If  '${entry_path.rsplit('/', 1)[1]}' == 'callout'
    \  ${esel_data}=  Read Attribute  ${entry_path}  AdditionalData  quiet=${1}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Contain Match  ${esel_data}  ESEL*
    \  Continue For Loop If  ${status} == ${False}
    \  ${index}=  Get Esel Index  ${esel_data}
    \  Write Data To File  "${esel_data[${index}]}"  ${logpath}
    \  Write Data To File  ${\n}  ${logpath}

    ${out}=  Run  which eSEL.pl
    ${status}=  Run Keyword And Return Status
    ...  Should Contain  ${out}  eSEL.pl
    Return From Keyword If  '${status}' == '${False}'

    Convert eSEL To Elog Format  ${logpath}


##############################################################################
Convert eSEL To Elog Format
    [Documentation]  Execute parser tool on the eSEL data file to generate
    ...              formatted error log.
    [Arguments]  ${esel_file_path}
    # Description of arguments:
    # esel_file_path  Absolute path of the eSEL data (e.g.
    #                 /tmp/w55.170404.154820.esel).

    # Note: The only way to get eSEL.pl to put the output in a particular
    # directory is to cd to that directory.
    ${cmd_buf}=  Catenate  cd $(dirname ${esel_file_path}) ; eSEL.pl -l
    ...  ${esel_file_path} -p decode_obmc_data
    Run  ${cmd_buf}

##############################################################################
