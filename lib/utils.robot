*** Settings ***
Resource                ../lib/resource.txt
Resource                ../lib/rest_client.robot
Resource                ../lib/connection_client.robot
Library                 String
Library                 DateTime
Library                 Process
Library                 OperatingSystem
Library                 gen_print.py
Library                 gen_robot_print.py
Library                 gen_cmd.py
Library                 gen_robot_keyword.py
Library                 bmc_ssh_utils.py
Library                 utils.py
Library                 var_funcs.py
Library                 SCPLibrary  WITH NAME  scp

*** Variables ***
${pflash_cmd}           /usr/sbin/pflash -r /dev/stdout -P VERSION
${SYSTEM_SHUTDOWN_TIME}       ${5}
${dbuscmdBase}
...  dbus-send --system --print-reply --dest=${OPENBMC_BASE_DBUS}.settings.Host
${dbuscmdGet}
...  ${SETTINGS_URI}host0  org.freedesktop.DBus.Properties.Get
# Enable when ready with openbmc/openbmc-test-automation#203
#${dbuscmdString}=  string:"xyz.openbmc_project.settings.Host" string:
${dbuscmdString}=   string:"org.openbmc.settings.Host" string:

# Assign default value to QUIET for programs which may not define it.
${QUIET}  ${0}
${bmc_mem_free_cmd}=   free | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4
${bmc_mem_total_cmd}=   free | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f2
${bmc_cpu_usage_cmd}=   top -n 1  | grep CPU: | cut -c 7-9
${HOST_SETTING}    ${SETTINGS_URI}host0
# /run/initramfs/ro associate filesystem  should be 100% full always
${bmc_file_system_usage_cmd}=  df -h | cut -c 52-54 | grep 100 | wc -l
${bmc_file_system_usage_cmd}=  df -h | cut -c 52-54 | grep 100 | wc -l
${total_pnor_ro_file_system_cmd}=  df -h | grep /media/pnor-ro | wc -l
${total_bmc_ro_file_system_cmd}=  df -h | grep /media/rofs | wc -l

${BOOT_TIME}     ${0}
${BOOT_COUNT}    ${0}
${count}  ${0}
${devicetree_base}  /sys/firmware/devicetree/base/model

# Initialize default debug value to 0.
${DEBUG}         ${0}

# These variables are used to straddle between new and old methods of setting
# values.
${boot_prog_method}     ${EMPTY}

${power_policy_setup}             ${0}
${bmc_power_policy_method}        ${EMPTY}
@{valid_power_policy_vars}        RESTORE_LAST_STATE  ALWAYS_POWER_ON
...                               ALWAYS_POWER_OFF

${probe_cpu_tool_path}     ${EXECDIR}/tools/ras/probe_cpus.sh
${scom_addrs_tool_path}    ${EXECDIR}/tools/ras/scom_addr_p9.sh
${target_file_path}        /root/

*** Keywords ***

Check BMC Performance
    [Documentation]  Check BMC basic CPU Mem File system performance.

    Check BMC CPU Performance
    Check BMC Mem Performance
    Check BMC File System Performance

Verify PNOR Update
    [Documentation]  Verify that the PNOR is not corrupted.
    # Example:
    # FFS: Flash header not found. Code: 100
    # Error 100 opening ffs !

    Open Connection And Log In
    ${pnor_info}=  Execute Command On BMC  ${pflash_cmd}
    Should Not Contain Any  ${pnor_info}  Flash header not found  Error

Get BMC System Model
    [Documentation]  Get the BMC model from the device tree.

    ${bmc_model}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat ${devicetree_base} | cut -d " " -f 1  return_stderr=True
    ...  test_mode=0
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${bmc_model}
    [Return]  ${bmc_model}

Verify BMC System Model
    [Documentation]  Verify the BMC model with ${OPENBMC_MODEL}.
    [Arguments]  ${bmc_model}

    ${tmp_bmc_model}=  Fetch From Right  ${OPENBMC_MODEL}  /
    ${tmp_bmc_model}=  Fetch From Left  ${tmp_bmc_model}  .
    ${ret}=  Run Keyword And Return Status  Should Contain  ${bmc_model}
    ...  ${tmp_bmc_model}  ignore_case=True
    [Return]  ${ret}

Wait For Host To Ping
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}min
    ...          ${interval}=5 sec

    # host      The DNS name or IP of the host to ping.
    # timeout   The amount of time after which attempts to ping cease.
    # interval  The amount of time in between attempts to ping.

    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping Host  ${host}

Ping Host
    [Arguments]     ${host}
    Should Not Be Empty    ${host}   msg=No host provided
    ${RC}   ${output}=     Run and return RC and Output    ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should be equal     ${RC}   ${0}

Get Boot Progress
    [Documentation]  Get the boot progress and return it.
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    Set Boot Progress Method
    ${state}=  Run Keyword If  '${boot_prog_method}' == 'New'
    ...      New Get Boot Progress  quiet=${quiet}
    ...  ELSE
    ...      Old Get Boot Progress  quiet=${quiet}

    [Return]  ${state}

Set Boot Progress Method
    [Documentation]  Set the boot_prog_method to either 'Old' or 'New'.

    # The boot progress data has moved from an 'org' location to an 'xyz'
    # location.  This keyword will determine whether the new method of getting
    # the boot progress is valid and will set the global boot_prog_method
    # variable accordingly.  If boot_prog_method is already set (either by a
    # prior call to this function or via a -v parm), this keyword will simply
    # return.

    # Note:  There are interim builds that contain boot_progress in both the
    # old and the new location values.  It is nearly impossible for this
    # keyword to determine whether the old boot_progress or the new one is
    # active.  When using such builds where the old boot_progress is active,
    # the only recourse users will have is that they may specify
    # -v boot_prog_method:Old to force old behavior on such builds.

    Run Keyword If  '${boot_prog_method}' != '${EMPTY}'  Return From Keyword

    ${new_status}  ${new_value}=  Run Keyword And Ignore Error
    ...  New Get Boot Progress
    # If the new style read fails, the method must necessarily be "Old".
    Run Keyword If  '${new_status}' == 'PASS'
    ...  Run Keywords
    ...  Set Global Variable  ${boot_prog_method}  New  AND
    ...  Rqpvars  boot_prog_method  AND
    ...  Return From Keyword

    # Default method is "Old".
    Set Global Variable  ${boot_prog_method}  Old
    Rqpvars  boot_prog_method

Old Get Boot Progress
    [Documentation]  Get the boot progress the old way (via org location).
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    ${state}=  Read Attribute  ${OPENBMC_BASE_URI}sensors/host/BootProgress
    ...  value  quiet=${quiet}

    [Return]  ${state}

New Get Boot Progress
    [Documentation]  Get the boot progress the new way (via xyz location).
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    ${state}=  Read Attribute  ${HOST_STATE_URI}  BootProgress  quiet=${quiet}

    [Return]  ${state.rsplit('.', 1)[1]}

Is Power On
    ${state}=  Get Power State
    Should be equal  ${state}  ${1}

Is Power Off
    ${state}=  Get Power State
    Should be equal  ${state}  ${0}

Initiate Power On
    [Documentation]  Initiates the power on and waits until the Is Power On
    ...  keyword returns that the power state has switched to on.
    [Arguments]  ${wait}=${1}

    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=  Call Method  ${OPENBMC_BASE_URI}control/chassis0/  powerOn
    ...  data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

    # Does caller want to wait for power on status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword
    Wait Until Keyword Succeeds  3 min  10 sec  Is Power On

Initiate Power Off
    [Documentation]  Initiates the power off and waits until the Is Power Off
    ...  keyword returns that the power state has switched to off.
    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=  Call Method  ${OPENBMC_BASE_URI}control/chassis0/  powerOff
    ...  data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Wait Until Keyword Succeeds  1 min  10 sec  Is Power Off

Initiate OS Host Power Off
    [Documentation]  Initiate an OS reboot.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Description of arguments:
    # os_host      The DNS name or IP of the OS.
    # os_username  The username to be used to sign in to the OS.
    # os_password  The password to be used to sign in to the OS.

    ${cmd_buf}=  Run Keyword If  '${os_username}' == 'root'
    ...      Set Variable  shutdown
    ...  ELSE
    ...      Set Variable  echo ${os_password} | sudo -S shutdown

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${cmd_buf}  fork=${1}

Initiate OS Host Reboot
    [Documentation]  Initiate an OS reboot.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Description of argument(s):
    # os_host      The host name or IP address of the OS.
    # os_username  The username to be used to sign in to the OS.
    # os_password  The password to be used to sign in to the OS.

    ${cmd_buf}=  Run Keyword If  '${os_username}' == 'root'
    ...      Set Variable  reboot
    ...  ELSE
    ...      Set Variable  echo ${os_password} | sudo -S reboot

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${cmd_buf}  fork=${1}

Initiate Auto Reboot
    [Documentation]  Initiate an auto reboot.

    # Set the auto reboot policy.
    Set Auto Reboot  ${1}
    # Set the watchdog timer.  Note: 5000 = milliseconds which is 5 seconds.
    Trigger Host Watchdog Error  5000

Trigger Warm Reset
    log to console    "Triggering warm reset"
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=  openbmc post request
    ...  ${OPENBMC_BASE_URI}control/bmc0/action/warmReset  data=${data}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Fail   msg=warm reset didn't occur

    Sleep   ${SYSTEM_SHUTDOWN_TIME}min
    Check If BMC Is Up

Check OS
    [Documentation]  Attempts to ping the host OS and then checks that the host
    ...              OS is up by running an SSH command.

    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}  ${quiet}=${QUIET}
    ...          ${print_string}=${EMPTY}
    [Teardown]  SSHLibrary.Close Connection

    # os_host           The DNS name/IP of the OS host associated with our BMC.
    # os_username       The username to be used to sign on to the OS host.
    # os_password       The password to be used to sign on to the OS host.
    # quiet             Indicates whether this keyword should write to console.
    # print_string      A string to be printed before checking the OS.

    rprint  ${print_string}

    # Attempt to ping the OS. Store the return code to check later.
    ${ping_rc}=  Run Keyword and Return Status  Ping Host  ${os_host}

    SSHLibrary.Open connection  ${os_host}

    ${status}  ${msg}=  Run Keyword And Ignore Error  Login  ${os_username}
    ...  ${os_password}
    ${err_msg1}=  Sprint Error  ${msg}
    ${err_msg}=  Catenate  SEPARATOR=  \n  ${err_msg1}
    Run Keyword If  '${status}' == 'FAIL'  Fail  msg=${err_msg}
    ${output}  ${stderr}  ${rc}=  Execute Command  uptime  return_stderr=True
    ...        return_rc=True

    ${temp_msg}=  Catenate  Could not execute a command on the operating
    ...  system.\n
    ${err_msg1}=  Sprint Error  ${temp_msg}
    ${err_msg}=  Catenate  SEPARATOR=  \n  ${err_msg1}

    # If the return code returned by "Execute Command" is non-zero, this
    # keyword will fail.
    Should Be Equal  ${rc}  ${0}  msg=${err_msg}
    # We will likewise fail if there is any stderr data.
    Should Be Empty  ${stderr}

    ${temp_msg}=  Set Variable  Could not ping the operating system.\n
    ${err_msg1}=  Sprint Error  ${temp_msg}
    ${err_msg}=  Catenate  SEPARATOR=  \n  ${err_msg1}
    # We will likewise fail if the OS did not ping, as we could SSH but not
    # ping
    Should Be Equal As Strings  ${ping_rc}  ${TRUE}  msg=${err_msg}

Wait for OS
    [Documentation]  Waits for the host OS to come up via calls to "Check OS".
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}  ${timeout}=${OS_WAIT_TIMEOUT}
    ...          ${quiet}=${0}
    [Teardown]  rprintn

    # os_host           The DNS name or IP of the OS host associated with our
    #                   BMC.
    # os_username       The username to be used to sign on to the OS host.
    # os_password       The password to be used to sign on to the OS host.
    # timeout           The timeout in seconds indicating how long you're
    #                   willing to wait for the OS to respond.
    # quiet             Indicates whether this keyword should write to console.

    # The interval to be used between calls to "Check OS".
    ${interval}=  Set Variable  5

    ${message}=  Catenate  Checking every ${interval} seconds for up to
    ...  ${timeout} seconds for the operating system to communicate.
    rqprint_timen  ${message}

    Wait Until Keyword Succeeds  ${timeout} sec  ${interval}  Check OS
    ...                          ${os_host}  ${os_username}  ${os_password}
    ...                          print_string=\#

    rqprintn

    rqprint_timen  The operating system is now communicating.


Get Power State
    [Documentation]  Returns the power state as an integer. Either 0 or 1.
    [Arguments]  ${quiet}=${QUIET}

    @{arglist}=  Create List
    ${args}=  Create Dictionary  data=@{arglist}

    ${resp}=  Call Method  ${OPENBMC_BASE_URI}control/chassis0/  getPowerState
    ...        data=${args}  quiet=${quiet}
    Should be equal as strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  to json  ${resp.content}
    [Return]  ${content["data"]}

Clear BMC Record Log
    [Documentation]  Clears all the event logs on the BMC. This would be
    ...              equivalent to ipmitool sel clear.
    @{arglist}=   Create List
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=  Call Method
    ...  ${OPENBMC_BASE_URI}records/events/  clear  data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

Copy PNOR to BMC
    Import Library      SCPLibrary      WITH NAME       scp
    Open Connection for SCP
    Log    Copying ${PNOR_IMAGE_PATH} to /tmp
    scp.Put File    ${PNOR_IMAGE_PATH}   /tmp

Flash PNOR
    [Documentation]    Calls flash bios update method to flash PNOR image
    [Arguments]    ${pnor_image}
    @{arglist}=   Create List    ${pnor_image}
    ${args}=     Create Dictionary    data=@{arglist}
    ${resp}=  Call Method  /org/openbmc/control/flash/bios/  update
    ...  data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Wait Until Keyword Succeeds    2 min   10 sec    Is PNOR Flashing

Get Flash BIOS Status
    [Documentation]  Returns the status of the flash BIOS API as a string. For
    ...              example 'Flashing', 'Flash Done', etc
    ${data}=  Read Properties  /org/openbmc/control/flash/bios
    [Return]    ${data['status']}

Is PNOR Flashing
    [Documentation]  Get BIOS 'Flashing' status. This indicates that PNOR
    ...              flashing has started.
    ${status}=    Get Flash BIOS Status
    Should Contain  ${status}  Flashing

Is PNOR Flash Done
    [Documentation]  Get BIOS 'Flash Done' status.  This indicates that the
    ...              PNOR flashing has completed.
    ${status}=    Get Flash BIOS Status
    should be equal as strings     ${status}     Flash Done


Is OS Starting
    [Documentation]  Check if boot progress is OS starting.
    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  OSStart

Is OS Off
    [Documentation]  Check if boot progress is "Off".
    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  Off

Get Boot Progress To OS Starting State
    [Documentation]  Get the system to a boot progress state of 'FW Progress,
    ...  Starting OS'.

    ${boot_progress}=  Get Boot Progress
    Run Keyword If  '${boot_progress}' == 'OSStart'
    ...  Log  Host is already in OS starting state
    ...  ELSE
    ...  Run Keywords  Initiate Host PowerOff  AND  Initiate Host Boot
    ...  AND  Wait Until Keyword Succeeds  10 min  10 sec  Is OS Starting

Verify Ping and REST Authentication
    ${l_ping}=   Run Keyword And Return Status
    ...    Ping Host  ${OPENBMC_HOST}
    Run Keyword If  '${l_ping}' == '${False}'
    ...    Fail   msg=Ping Failed

    ${l_rest}=   Run Keyword And Return Status
    ...    Initialize OpenBMC
    Run Keyword If  '${l_rest}' == '${False}'
    ...    Fail   msg=REST Authentication Failed

    # Just to make sure the SSH is working for SCP
    Open Connection And Log In
    ${system}   ${stderr}=    Execute Command   hostname   return_stderr=True
    Should Be Empty     ${stderr}

Check If BMC is Up
    [Documentation]  Wait for Host to be online. Checks every X seconds
    ...              interval for Y minutes and fails if timed out.
    ...              Default MAX timedout is 10 min, interval 10 seconds.
    [Arguments]      ${max_timeout}=${OPENBMC_REBOOT_TIMEOUT} min
    ...              ${interval}=10 sec

    Wait Until Keyword Succeeds
    ...   ${max_timeout}  ${interval}   Verify Ping and REST Authentication


Check If warmReset is Initiated
    [Documentation]  Ping would be still alive, so try SSH to connect
    ...              if fails the ports are down indicating reboot
    ...              is in progress

    # Warm reset adds 3 seconds delay before forcing reboot
    # To minimize race conditions, we wait for 7 seconds
    Sleep  7s
    ${alive}=   Run Keyword and Return Status
    ...    Open Connection And Log In
    Return From Keyword If   '${alive}' == '${False}'    ${False}
    [Return]    ${True}

Flush REST Sessions
    [Documentation]   Removes all the active session objects
    Delete All Sessions

Initialize DBUS cmd
    [Documentation]  Initialize dbus string with property string to extract
    [Arguments]   ${boot_property}
    ${cmd}=     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${cmd}=     Catenate  ${cmd}${boot_property}
    Set Global Variable   ${dbuscmd}     ${cmd}

Create OS Console File Path
    [Documentation]  Create OS console file path name and return it.
    [Arguments]  ${log_file_path}=${EMPTY}

    # Description of arguments:
    # file_path  The caller's candidate value.  If this value is ${EMPTY}, this
    #            keyword will compose a file path name.  Otherwise, this
    #            keyword will use the caller's file_path value.  In either
    #            case, the value will be returned.

    ${default_file_path}=  Catenate  /tmp/${OPENBMC_HOST}_os_console.txt
    ${log_file_path}=  Set Variable If  '${log_file_path}' == '${EMPTY}'
    ...  ${default_file_path}  ${log_file_path}

    [Return]  ${log_file_path}

Create OS Console Command String
    [Documentation]  Return a command string to start OS console logging.

    # First make sure that the ssh_pw program is available.
    ${cmd_buf}=  Catenate  which ssh_pw 2>/dev/null || find ${EXECDIR} -name 'ssh_pw'
    Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  rc  output

    Should Be Equal As Integers  0  ${rc}  msg=Could not find ssh_pw.

    ${ssh_pw_file_path}=  Set Variable  ${output}

    ${cmd_buf}=  Catenate  ${ssh_pw_file_path} ${OPENBMC_PASSWORD} -p 2200
    ...  -o "StrictHostKeyChecking no" ${OPENBMC_USERNAME}@${OPENBMC_HOST}

    [Return]  ${cmd_buf}

Get SOL Console Pid
    [Documentation]  Get the pid of the active sol conole job.

    # Find the pid of the active system console logging session (if any).
    ${search_string}=  Create OS Console Command String
    # At least in some cases, ps output does not show double quotes so we must
    # replace them in our search string with the regexes to indicate that they
    # are optional.
    ${search_string}=  Replace String  ${search_string}  "  ["]?
    ${cmd_buf}=  Catenate  echo $(ps awwo user,pid,cmd | egrep
    ...  '${search_string}' | egrep -v grep | cut -c10-14)
    Rdpissuing  ${cmd_buf}
    ${rc}  ${os_con_pid}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  os_con_pid
    # If rc is not zero it just means that there is no OS Console process
    # running.

    [Return]  ${os_con_pid}


Stop SOL Console Logging
    [Documentation]  Stop system console logging and return log output.
    [Arguments]  ${log_file_path}=${EMPTY}
    ...          ${targ_file_path}=${EXECDIR}${/}logs${/}
    ...          ${return_data}=${1}

    # If there are muliple system console processes, they will all be stopped.
    # If there is no existing log file this keyword will return an error
    # message to that effect (and write that message to targ_file_path, if
    # specified).
    # NOTE: This keyword will not fail if there is no running system console
    # process.

    # Description of arguments:
    # log_file_path   The file path that was used to call "Start SOL
    #                 Console Logging".  See that keyword (above) for details.
    # targ_file_path  If specified, the file path to which the source
    #                 file path (i.e. "log_file_path") should be copied.
    # return_data     If this is set to ${1}, this keyword will return the SOL
    #                 data to the caller as a unicode string.

    ${log_file_path}=  Create OS Console File Path  ${log_file_path}

    ${os_con_pid}=  Get SOL Console Pid

    ${cmd_buf}=  Catenate  kill -9 ${os_con_pid}
    Run Keyword If  '${os_con_pid}' != '${EMPTY}'  Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run Keyword If  '${os_con_pid}' != '${EMPTY}'
    ...  Run And Return Rc And Output  ${cmd_buf}
    Run Keyword If  '${os_con_pid}' != '${EMPTY}'  Rdpvars  rc  output

    Run Keyword If  '${targ_file_path}' != '${EMPTY}'
    ...  Run Keyword And Ignore Error
    ...  Copy File  ${log_file_path}  ${targ_file_path}

    ${output}=  Set Variable  ${EMPTY}
    ${loc_quiet}=  Evaluate  ${debug}^1
    ${rc}  ${output}=  Run Keyword If  '${return_data}' == '${1}'
    ...  Cmd Fnc  cat ${log_file_path} 2>/dev/null  quiet=${loc_quiet}
    ...  print_output=${0}  show_err=${0}

    [Return]  ${output}

Start SOL Console Logging
    [Documentation]  Start system console log to file.
    [Arguments]  ${log_file_path}=${EMPTY}  ${return_data}=${1}

    # This keyword will first call "Stop SOL Console Logging".  Only then will
    # it start SOL console logging.  The data returned by "Stop SOL Console
    # Logging" will in turn be returned by this keyword.

    # Description of arguments:
    # log_file_path   The file path to which system console log data should be
    #                 written.  Note that this path is taken to be a location
    #                 on the machine where this program is running rather than
    #                 on the Open BMC system.
    # return_data     If this is set to ${1}, this keyword will return any SOL
    #                 data to the caller as a unicode string.

    ${log_file_path}=  Create OS Console File Path  ${log_file_path}

    ${log_output}=  Stop SOL Console Logging  ${log_file_path}
    ...  return_data=${return_data}

    # Validate by making sure we can create the file.  Problems creating the
    # file would not be noticed by the subsequent ssh command because we fork
    # the command.
    Create File  ${log_file_path}
    ${sub_cmd_buf}=  Create OS Console Command String
    # Routing stderr to stdout so that any startup error text will go to the
    # output file.
    # TODO: Doesn't work with tox so reverting temporarily.
    # nohup detaches the process completely from our pty.
    #${cmd_buf}=  Catenate  nohup ${sub_cmd_buf} &> ${log_file_path} &
    ${cmd_buf}=  Catenate  ${sub_cmd_buf} > ${log_file_path} 2>&1 &
    Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_buf}
    # Because we are forking this command, we essentially will never get a
    # non-zero return code or any output.
    Should Be Equal  ${rc}  ${0}

    Sleep  1
    ${os_con_pid}=  Get SOL Console Pid

    Should Not Be Empty  ${os_con_pid}

    [Return]  ${log_output}

Get Time Stamp
    [Documentation]     Get the current time stamp data
    ${cur_time}=    Get Current Date   result_format=%Y%m%d%H%M%S%f
    [Return]   ${cur_time}


Start Journal Log
    [Documentation]   Start capturing journal log to a file in /tmp using
    ...               journalctl command. By default journal log is collected
    ...               at /tmp/journal_log else user input location.
    ...               The File is appended with datetime.
    [Arguments]       ${file_path}=/tmp/journal_log

    Open Connection And Log In

    ${cur_time}=    Get Time Stamp
    Set Global Variable   ${LOG_TIME}   ${cur_time}
    Start Command
    ...  journalctl -f > ${file_path}-${LOG_TIME}
    Log    Journal Log Started: ${file_path}-${LOG_TIME}


Stop Journal Log
    [Documentation]   Stop journalctl process if its running.
    ...               By default return log from /tmp/journal_log else
    ...               user input location.
    [Arguments]       ${file_path}=/tmp/journal_log

    Open Connection And Log In

    ${rc}=
    ...  Execute Command
    ...  ps ax | grep journalctl | grep -v grep
    ...  return_stdout=False  return_rc=True

    Return From Keyword If   '${rc}' == '${1}'
    ...   No journal log process running

    ${output}  ${stderr}=
    ...  Execute Command   killall journalctl
    ...  return_stderr=True
    Should Be Empty     ${stderr}

    ${journal_log}  ${stderr}=
    ...  Execute Command
    ...  cat ${file_path}-${LOG_TIME}
    ...  return_stderr=True
    Should Be Empty     ${stderr}

    Log    ${journal_log}

    Execute Command    rm ${file_path}-${LOG_TIME}

    [Return]    ${journal_log}

Mac Address To Hex String
    [Documentation]   Converts MAC address into hex format.
    ...               Example
    ...               Given the following MAC: 00:01:6C:80:02:78
    ...               This keyword will return: 0x00 0x01 0x6C 0x80 0x02 0x78
    ...               Description of arguments:
    ...               i_macaddress  MAC address in the following format
    ...               00:01:6C:80:02:78
    [Arguments]    ${i_macaddress}

    ${mac_hex}=  Catenate  0x${i_macaddress.replace(':', ' 0x')}
    [Return]    ${mac_hex}

IP Address To Hex String
    [Documentation]   Converts IP address into hex format.
    ...               Example:
    ...               Given the following IP: 10.3.164.100
    ...               This keyword will return: 0xa 0x3 0xa4 0xa0
    ...               Description of arguments:
    ...               i_ipaddress  IP address in the following format
    ...               10.10.10.10
    [Arguments]    ${i_ipaddress}

    @{ip}=  Split String  ${i_ipaddress}    .
    ${index}=  Set Variable  ${0}

    :FOR    ${item}     IN      @{ip}
    \   ${hex}=  Convert To Hex    ${item}    prefix=0x    lowercase=yes
    \   Set List Value    ${ip}    ${index}    ${hex}
    \   ${index}=  Set Variable    ${index + 1}
    ${ip_hex}=  Catenate    @{ip}
    [Return]    ${ip_hex}

BMC CPU Performance Check
   [Documentation]   Minimal 10% of proc should be free in this instance

    ${bmc_cpu_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${bmc_cpu_usage_cmd}
    ${bmc_cpu_usage_output}  ${stderr}  ${rc}=  BMC Execute Command  ${bmc_cpu_usage_cmd}
    ${bmc_cpu_percentage}=  Fetch From Left  ${bmc_cpu_usage_output}  %
    Should be true  ${bmc_cpu_percentage} < 90

BMC Mem Performance Check
    [Documentation]   Minimal 10% of memory should be free in this instance

    ${bmc_mem_free_output}  ${stderr}  ${rc}=   BMC Execute Command
    ...  ${bmc_mem_free_cmd}

    ${bmc_mem_total_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${bmc_mem_total_cmd}
    ${bmc_mem_free_output}  ${stderr}  ${rc}=   BMC Execute Command
    ...  ${bmc_mem_free_cmd}

    ${bmc_mem_total_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${bmc_mem_total_cmd}

    ${bmc_mem_percentage}=  Evaluate  ${bmc_mem_free_output}*100
    ${bmc_mem_percentage}=  Evaluate
    ...   ${bmc_mem_percentage}/${bmc_mem_total_output}
    Should be true  ${bmc_mem_percentage} > 10

BMC File System Usage Check
    [Documentation]   Check the file system space. 4 file system should be
    ...  100% full which is expected
    # Filesystem                Size      Used Available Use% Mounted on
    # /dev/root                14.4M     14.4M         0 100% /
    # /dev/ubiblock0_0         14.4M     14.4M         0 100% /media/rofs-c9249b0e
    # /dev/ubiblock8_0         19.6M     19.6M         0 100% /media/pnor-ro-8764baa3
    # /dev/ubiblock4_0         14.4M     14.4M         0 100% /media/rofs-407816c
    ${bmc_fs_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...   ${bmc_file_system_usage_cmd}
    Should Be True  ${bmc_fs_usage_output}==4
    # /dev/ubiblock8_4         21.1M     21.1M         0 100% /media/pnor-ro-cecc64c4
    ${bmc_fs_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${bmc_file_system_usage_cmd}
    ${bmc_pnor_fs_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${total_pnor_ro_file_system_cmd}
    ${bmc_bmc_fs_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${total_bmc_ro_file_system_cmd}
    ${total_bmc_pnor_image}=  Evaluate
    ...  ${bmc_pnor_fs_usage_output}+${bmc_bmc_fs_usage_output}
    # Considering /dev/root also in total 100% used file system
    ${total_full_fs}=  Evaluate  ${total_bmc_pnor_image}+1
    Should Be True  ${bmc_fs_usage_output}==${total_full_fs}

Check BMC CPU Performance
    [Documentation]   Minimal 10% of proc should be free in 3 sample
    :FOR  ${var}  IN Range  1  4
    \     BMC CPU Performance check

Check BMC Mem Performance
    [Documentation]   Minimal 10% of memory should be free

    :FOR  ${var}  IN Range  1  4
    \     BMC Mem Performance check

Check BMC File System Performance
    [Documentation]  Check for file system usage for 4 times

    :FOR  ${var}  IN Range  1  4
    \     BMC File System Usage check

Get URL List
    [Documentation]  Return list of URLs under given URL.
    [Arguments]  ${openbmc_url}
    # Description of argument(s):
    # openbmc_url  URL for list operation (e.g.
    #              /xyz/openbmc_project/inventory).

    ${url_list}=  Read Properties  ${openbmc_url}/list  quiet=${1}
    Sort List  ${url_list}
    [Return]  ${url_list}

Get Endpoint Paths
    [Documentation]   Returns all url paths ending with given endpoint
    ...               Example:
    ...               Given the following endpoint: cpu
    ...               This keyword will return: list of all urls ending with
    ...               cpu -
    ...               /org/openbmc/inventory/system/chassis/motherboard/cpu0,
    ...               /org/openbmc/inventory/system/chassis/motherboard/cpu1
    ...               Description of arguments:
    ...               path       URL path for enumeration
    ...               endpoint   string for which url path ending
    [Arguments]   ${path}   ${endpoint}

    ${resp}=   Read Properties   ${path}/enumerate   timeout=30
    log Dictionary   ${resp}

    ${list}=   Get Dictionary Keys   ${resp}
    ${resp}=   Get Matches   ${list}   regexp=^.*[0-9a-z_].${endpoint}[0-9]*$
    [Return]   ${resp}

Check Zombie Process
    [Documentation]    Check if any defunct process exist or not on BMC
    ${count}  ${stderr}  ${rc}=  Execute Command  ps -o stat | grep Z | wc -l
    ...    return_stderr=True  return_rc=True
    Should Be True    ${count}==0
    Should Be Empty    ${stderr}

Prune Journal Log
    [Documentation]   Prune archived journal logs.
    [Arguments]   ${vacuum_size}=1M

    # This keyword can be used to prevent the journal
    # log from filling up the /run filesystem.
    # This command will retain only the latest logs
    # of the user specified size.

    Open Connection And Log In
    ${output}  ${stderr}  ${rc}=
    ...  Execute Command
    ...  journalctl --vacuum-size=${vacuum_size}
    ...  return_stderr=True  return_rc=True

    Should Be Equal  ${rc}  ${0}  msg=${stderr}

Set BMC Power Policy
    [Documentation]   Set the given BMC power policy.
    [Arguments]   ${policy}

    # Note that this function will translate the old style "RESTORE_LAST_STATE"
    # policy to the new style "xyz.openbmc_project.Control.Power.RestorePolicy.
    # Policy.Restore" for you.

    # Description of argument(s):
    # policy    Power restore policy (e.g "RESTORE_LAST_STATE",
    #           ${RESTORE_LAST_STATE}).

    # Set the bmc_power_policy_method to either 'Old' or 'New'.
    Set Power Policy Method
    # This translation helps bridge between old and new method for calling.
    ${policy}=  Translate Power Policy Value  ${policy}
    # Run the appropriate keyword.
    Run Key  ${bmc_power_policy_method} Set Power Policy \ ${policy}
    ${currentPolicy}=  Get System Power Policy
    Should Be Equal    ${currentPolicy}   ${policy}

New Set Power Policy
    [Documentation]   Set the given BMC power policy (new method).
    [Arguments]   ${policy}

    # Description of argument(s):
    # policy    Power restore policy (e.g. ${RESTORE_LAST_STATE}).

    ${valueDict}=  Create Dictionary  data=${policy}
    Write Attribute
    ...  ${POWER_RESTORE_URI}  PowerRestorePolicy  data=${valueDict}

Old Set Power Policy
    [Documentation]   Set the given BMC power policy (old method).
    [Arguments]   ${policy}

    # Description of argument(s):
    # policy    Power restore policy (e.g. "RESTORE_LAST_STATE").

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}

Get System Power Policy
    [Documentation]  Get the BMC power policy.

    # Set the bmc_power_policy_method to either 'Old' or 'New'.
    Set Power Policy Method
    ${cmd_buf}=  Create List  ${bmc_power_policy_method} Get Power Policy
    # Run the appropriate keyword.
    ${currentPolicy}=  Run Keyword  @{cmd_buf}
    [Return]  ${currentPolicy}

New Get Power Policy
    [Documentation]  Get the BMC power policy (new method).
    ${currentPolicy}=  Read Attribute  ${POWER_RESTORE_URI}  PowerRestorePolicy
    [Return]  ${currentPolicy}

Old Get Power Policy
    [Documentation]  Get the BMC power policy (old method).
    ${currentPolicy}=  Read Attribute  ${HOST_SETTING}  power_policy
    [Return]  ${currentPolicy}

Get Auto Reboot
    [Documentation]  Returns auto reboot setting.
    ${setting}=  Read Attribute  ${CONTROL_HOST_URI}/auto_reboot  AutoReboot
    [Return]  ${setting}

Set Auto Reboot
    [Documentation]  Set the given auto reboot setting.
    [Arguments]  ${setting}
    # setting  auto reboot's setting, i.e. 1 for enabling and 0 for disabling.

    ${valueDict}=  Set Variable  ${setting}
    ${data}=  Create Dictionary  data=${valueDict}
    Write Attribute  ${CONTROL_HOST_URI}/auto_reboot  AutoReboot   data=${data}
    ${current_setting}=  Get Auto Reboot
    Should Be Equal As Integers  ${current_setting}  ${setting}


Set BMC Reset Reference Time
    [Documentation]  Set current boot time as a reference and increment
    ...              boot count.

    ${cur_btime}=  Get BMC Boot Time
    Run Keyword If  ${BOOT_TIME} == ${0} and ${BOOT_COUNT} == ${0}
    ...  Set Global Variable  ${BOOT_TIME}  ${cur_btime}
    ...  ELSE IF  ${cur_btime} > ${BOOT_TIME}
    ...  Run Keywords  Set Global Variable  ${BOOT_TIME}  ${cur_btime}
    ...  AND
    ...  Set Global Variable  ${BOOT_COUNT}  ${BOOT_COUNT + 1}

Get BMC Boot Time
    [Documentation]  Get boot time from /proc/stat.

    Open Connection And Log In
    ${output}  ${stderr}=
    ...  Execute Command  egrep '^btime ' /proc/stat | cut -f 2 -d ' '
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${btime}=  Convert To Integer  ${output}
    [Return]  ${btime}

Execute Command On BMC
    [Documentation]  Execute given command on BMC and return output.
    [Arguments]  ${command}
    ${stdout}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    [Return]  ${stdout}


Enable Core Dump On BMC
    [Documentation]  Enable core dump collection.
    Open Connection And Log In
    ${core_pattern}=  Execute Command On BMC
    ...  echo '/tmp/core_%e.%p' | tee /proc/sys/kernel/core_pattern
    Should Be Equal As Strings  ${core_pattern}  /tmp/core_%e.%p

Get Number Of BMC Core Dump Files
    [Documentation]  Get number of core dump files on BMC.
    Open Connection And Log In
    ${num_of_core_dump}=  Execute Command
    ...  ls /tmp/core* 2>/dev/null | wc -l
    [Return]  ${num_of_core_dump}

Set Core Dump File Size Unlimited
    [Documentation]  Set core dump file size to unlimited.
    Open Connection And Log In
    Execute Command On BMC
    ...  ulimit -c unlimited

Check For Core Dumps
    [Documentation]  Check for any core dumps exist.
    ${output}=  Get Number Of BMC Core Dump Files
    Run Keyword If  ${output} > 0
    ...  Log  **Warning** BMC core dump files exist  level=WARN

Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog timeout error via REST.
    [Arguments]  ${milliseconds}=1000  ${sleep_time}=5s
    # Description of argument(s):
    # milliseconds  The time watchdog timer value in milliseconds (e.g. 1000 =
    #               1 second).
    # sleep_time    Time delay for host watchdog error to get injected.
    #               Default is 5 seconds.

    ${data}=  Create Dictionary  data=${True}
    Write Attribute  /xyz/openbmc_project/watchdog/host0  Enabled  data=${data}

    ${data}=  Create Dictionary  data=${milliseconds}
    Write Attribute  /xyz/openbmc_project/watchdog/host0  TimeRemaining
    ...  data=${data}

    Sleep  ${sleep_time}

Login To OS Host
    [Documentation]  Login to OS Host.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}
    # Description of arguments:
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    ${os_state}=  Run Keyword And Return Status  Ping Host  ${os_host}
    Run Keyword If  '${os_state}' == 'False'
    ...  Run Keywords  Initiate Host Reboot  AND
    ...  Is Host Running  AND
    ...  Wait for OS  ${os_host}  ${os_username}  ${os_password}

    SSHLibrary.Open Connection  ${os_host}
    ${resp}=  Login  ${os_username}  ${os_password}
    [Return]  ${resp}

Configure Initial Settings
    [Documentation]  Restore old IP and route.
    ...  This keyword requires initial settings viz IP address,
    ...  Network Mask, default gatway and serial console IP and port
    ...  information which should be provided in command line.

    [Arguments]  ${host}=${OPENBMC_HOST}  ${mask}=${NET_MASK}
    ...          ${gw_ip}=${GW_IP}

    # Open telnet connection and ignore the error, in case telnet session is
    # already opened by the program calling this keyword.

    Run Keyword And Ignore Error  Open Telnet Connection to BMC Serial Console
    Telnet.write  ifconfig eth0 ${host} netmask ${mask}
    Telnet.write  route add default gw ${gw_ip}

Install Debug Tarball On BMC
    [Documentation]  Copy the debug tar file to BMC and install.
    [Arguments]  ${tarball_file_path}=${EXECDIR}/obmc-phosphor-debug-tarball-witherspoon.tar.xz
    ...          ${targ_tarball_dir_path}=/tmp/tarball/

    # Description of arguments:
    # tarball_file_path      Path of the debug tarball file.
    #                        The tar file is downloaded from the build page
    #                        https://openpower.xyz/job/openbmc-build/
    #                        obmc-phosphor-debug-tarball-witherspoon.tar.xz
    #
    # targ_tarball_dir_path  The directory path where the tarball is to be
    #                        installed.

    OperatingSystem.File Should Exist  ${tarball_file_path}
    ...  msg=${tarball_file_path} doesn't exist.

    # Upload the file to BMC.
    Import Library  SCPLibrary  WITH NAME  scp
    Open Connection for SCP
    scp.Put File  ${tarball_file_path}  /tmp/debug-tarball.tar.xz

    # Create tarball directory and install.
    BMC Execute Command  mkdir -p ${targ_tarball_dir_path}
    BMC Execute Command
    ...  tar -xf /tmp/debug-tarball.tar.xz -C ${targ_tarball_dir_path}

    # Remove the tarball file from BMC.
    BMC Execute Command  rm -f /tmp/debug-tarball.tar.xz


Get BMC Boot Count
    [Documentation]  Get BMC boot count based on boot time.
    ${cur_btime}=  Get BMC Boot Time

    # Set global variable BOOT_TIME to current boot time if current boot time
    # is changed. Also increase value of global variable BOOT_COUNT by 1.
    Run Keyword If  ${cur_btime} > ${BOOT_TIME}
    ...  Run Keywords  Set Global Variable  ${BOOT_TIME}  ${cur_btime}
    ...  AND
    ...  Set Global Variable  ${BOOT_COUNT}  ${BOOT_COUNT + 1}
    [Return]  ${BOOT_COUNT}

Set BMC Boot Count
    [Documentation]  Set BMC boot count to given value.
    [Arguments]  ${count}

    # Description of arguments:
    # count  boot count value.
    ${cur_btime}=  Get BMC Boot Time

    # Set global variable BOOT_COUNT to given value.
    Set Global Variable  ${BOOT_COUNT}  ${count}

    # Set BOOT_TIME variable to current boot time.
    Set Global Variable  ${BOOT_COUNT}  ${count}

Get System LED State
    [Documentation]  Return the state of given system LED.
    [Arguments]  ${led_name}

    # Description of argument(s):
    # led_name     System LED name (e.g. heartbeat, identify, beep).

    ${state}=  Read Attribute  ${LED_PHYSICAL_URI}${led_name}  State
    [Return]  ${state.rsplit('.', 1)[1]}


Delete Error Logs
    [Documentation]  Delete error logs.

    # Check if error logs entries exist, if not return.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${/}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}

    # Get the list of error logs entries and delete them all.
    ${elog_entries}=  Get URL List  ${BMC_LOGGING_ENTRY}
    :FOR  ${entry}  IN  @{elog_entries}
    \  Delete Error Log Entry  ${entry}


Delete Error Log Entry
    [Documentation]  Delete error log entry.
    [Arguments]  ${entry_path}

    # Description of argument(s):
    # entry_path  Delete an error log entry.
    #             Ex. /xyz/openbmc_project/logging/entry/1

    # Skip delete if entry URI is a callout.
    # Example: /xyz/openbmc_project/logging/entry/1/callout
    Return From Keyword If  '${entry_path.rsplit('/', 1)[1]}' == 'callout'

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Delete Request  ${entry_path}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete All Error Logs
    [Documentation]  Delete all error log entries using "DeleteAll" interface.

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Post Request  ${BMC_LOGGING_URI}action/DeleteAll
    ...  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Get LED State XYZ
    [Documentation]  Returns state of given LED.
    [Arguments]  ${led_name}
    # Description of argument(s):
    # led_name  Name of LED

    ${state}=  Read Attribute  ${LED_GROUPS_URI}${led_name}  Asserted
    [Return]  ${state}


Get BMC Version
    [Documentation]  Returns BMC version from /etc/os-release.
    ...              e.g. "v1.99.6-141-ge662190"

    Open Connection And Log In
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}=  Execute Command On BMC  ${cmd}
    [Return]  ${output}


Get PNOR Version
    [Documentation]  Get the PNOR version from the BMC.

    ${pnor_attrs}=  Get PNOR Attributes
    [Return]  ${pnor_attrs['version']}


Get PNOR Attributes
    [Documentation]  Return PNOR software attributes as a dictionary.

    # This keyword parses /var/lib/phosphor-software-manager/pnor/ro/pnor.toc
    # into key/value pairs.

    ${outbuf}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /var/lib/phosphor-software-manager/pnor/ro/pnor.toc
    ${pnor_attrs}=  Key Value Outbuf To Dict  ${outbuf}  delim==

    [Return]  ${pnor_attrs}


Get Elog URL List
    [Documentation]  Return error log entry list of URLs.

    ${url_list}=  Read Properties  /xyz/openbmc_project/logging/entry/
    Sort List  ${url_list}
    [Return]  ${url_list}


Read Turbo Setting Via REST
    [Documentation]  Return turbo setting via REST.

    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}host/TurboAllowed
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    [Return]  ${jsondata["data"]["value"]}


Set Turbo Setting Via REST
    [Documentation]  Set turbo setting via REST.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  Value which needs to be set.(i.e. False or True)

    ${valueDict}=  Create Dictionary  data=${setting}
    Write Attribute  ${SENSORS_URI}host/TurboAllowed  value  data=${valueDict}

Set Control Boot Mode
    [Documentation]  Set given boot mode on the boot object path attribute.
    [Arguments]  ${boot_path}  ${boot_mode}

    # Description of argument(s):
    # boot_path  Boot object path.
    #            Example:
    #            /xyz/openbmc_project/control/host0/boot
    #            /xyz/openbmc_project/control/host0/boot/one_time
    # boot_mode  Boot mode which need to be set.
    #            Example:
    #            "xyz.openbmc_project.Control.Boot.Mode.Modes.Regular"

    ${valueDict}=  Create Dictionary  data=${boot_mode}
    Write Attribute  ${boot_path}  BootMode  data=${valueDict}

Copy Address Translation Utils To HOST OS
    [Documentation]  Copy address translation utils to host OS.

    OperatingSystem.File Should Exist  ${probe_cpu_tool_path}
    ...  msg=${probe_cpu_tool_path} doesn't exist.
    OperatingSystem.File Should Exist  ${probe_cpu_tool_path}
    ...  msg=${probe_cpu_tool_path} doesn't exist.

    scp.Open connection  ${OS_HOST}  username=${OS_USERNAME}
    ...  password=${OS_PASSWORD}
    scp.Put File  ${probe_cpu_tool_path}  ${target_file_path}
    scp.Put File  ${scom_addrs_tool_path}  ${target_file_path}


Verify BMC RTC And UTC Time Drift
    [Documentation]  Verify that the RTC and UTC time difference is less than
    ...              the given time_drift_max.
    [Arguments]  ${time_diff_max}=${10}

    # Description of argument(s):
    # time_diff_max   The max allowable RTC and UTC time difference in seconds.

    # Example:
    # time_dict:
    #   [local_time]:               Fri 2017-11-03 152756 UTC
    #   [local_time_seconds]:       1509740876
    #   [universal_time]:           Fri 2017-11-03 152756 UTC
    #   [universal_time_seconds]:   1509740876
    #   [rtc_time]:                 Fri 2016-05-20 163403
    #   [rtc_time_seconds]:         1463780043
    #   [time_zone]:                n/a (UTC, +0000)
    #   [network_time_on]:          yes
    #   [ntp_synchronized]:         no
    #   [rtc_in_local_tz]:          no

    ${bmc_time}=  Get BMC Date Time
    ${time_diff}=  Evaluate
    ...  ${bmc_time['universal_time_seconds']} - ${bmc_time['rtc_time_seconds']}
    Should Be True  ${time_diff} < ${time_diff_max}


