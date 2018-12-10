*** Settings ***

Documentation  Utilities for Robot keywords that do not use REST.

Resource                ../lib/resource.txt
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
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

${pflash_cmd}             /usr/sbin/pflash -r /dev/stdout -P VERSION

${dbuscmdBase}
...  dbus-send --system --print-reply --dest=${OPENBMC_BASE_DBUS}.settings.Host
${dbuscmdGet}
...  ${SETTINGS_URI}host0  org.freedesktop.DBus.Properties.Get
${dbuscmdString}=  string:"xyz.openbmc_project.settings.Host" string:

# Assign default value to QUIET for programs which may not define it.
${QUIET}  ${0}

${bmc_mem_free_cmd}=   free | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f4
${bmc_mem_total_cmd}=   free | tr -s ' ' | sed '/^Mem/!d' | cut -d" " -f2
${bmc_cpu_usage_cmd}=   top -n 1  | grep CPU: | cut -c 7-9
${HOST_SETTING}    ${SETTINGS_URI}host0

# /run/initramfs/ro associate filesystem  should be 100% full always
${bmc_file_system_usage_cmd}=  df -h | cut -c 52-54 | grep 100 | wc -l
${total_pnor_ro_file_system_cmd}=  df -h | grep /media/pnor-ro | wc -l
${total_bmc_ro_file_system_cmd}=  df -h | grep /media/rofs | wc -l

${BOOT_TIME}     ${0}
${BOOT_COUNT}    ${0}
${count}  ${0}
${devicetree_base}  /sys/firmware/devicetree/base/model

# Initialize default debug value to 0.
${DEBUG}         ${0}

${probe_cpu_tool_path}     ${EXECDIR}/tools/ras/probe_cpus.sh
${scom_addrs_tool_path}    ${EXECDIR}/tools/ras/scom_addr_p9.sh
${target_file_path}        /root/

${default_tarball}  ${EXECDIR}/obmc-phosphor-debug-tarball-witherspoon.tar.xz

# These variables are used to straddle between new and old methods of setting
# values.
${bmc_power_policy_method}        ${EMPTY}
@{valid_power_policy_vars}        RESTORE_LAST_STATE  ALWAYS_POWER_ON
...                               ALWAYS_POWER_OFF


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

    ${stdout}  ${stderr}  ${rc}=
    ...  BMC Execute Command  /usr/sbin/pflash -h | egrep -q skip
    ...  ignore_err=${1}
    ${pflash_cmd}=  Set Variable If  ${rc} == ${0}  ${pflash_cmd} --skip=4096
    ...  ${pflash_cmd}
    ${pnor_info}=  BMC Execute Command  ${pflash_cmd}
    Should Not Contain Any  ${pnor_info}  Flash header not found  Error


Get BMC System Model
    [Documentation]  Get the BMC model from the device tree and return it.

    ${bmc_model}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat ${devicetree_base} | cut -d " " -f 1  return_stderr=True
    ...  test_mode=0
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${bmc_model}  msg=BMC model is empty.
    [Return]  ${bmc_model}


Verify BMC System Model
    [Documentation]  Verify the BMC model with ${OPENBMC_MODEL}.
    [Arguments]  ${bmc_model}

    # Description of argument(s):
    # bmc_model System model (e.g. "witherspoon").

    ${tmp_bmc_model}=  Fetch From Right  ${OPENBMC_MODEL}  /
    ${tmp_bmc_model}=  Fetch From Left  ${tmp_bmc_model}  .
    ${ret}=  Run Keyword And Return Status  Should Contain  ${bmc_model}
    ...  ${tmp_bmc_model}  ignore_case=True
    [Return]  ${ret}


Wait For Host To Ping
    [Documentation]  Wait for the given host to ping.
    [Arguments]  ${host}  ${timeout}=${OPENBMC_REBOOT_TIMEOUT}min
    ...          ${interval}=5 sec

    # Description of argument(s):
    # host      The host name or IP of the host to ping.
    # timeout   The amount of time after which ping attempts cease.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "10 seconds").
    # interval  The amount of time in between attempts to ping.
    #           This should be expressed in Robot Framework's time format
    #           (e.g. "5 seconds").

    Wait Until Keyword Succeeds  ${timeout}  ${interval}  Ping Host  ${host}


Ping Host
    [Documentation]  Ping the given host.
    [Arguments]     ${host}

    # Description of argument(s):
    # host      The host name or IP of the host to ping.

    Should Not Be Empty    ${host}   msg=No host provided
    ${RC}   ${output}=     Run and return RC and Output    ping -c 4 ${host}
    Log     RC: ${RC}\nOutput:\n${output}
    Should be equal     ${RC}   ${0}


Check OS
    [Documentation]  Attempts to ping the host OS and then checks that the host
    ...              OS is up by running an SSH command.

    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}  ${quiet}=${QUIET}
    ...          ${print_string}=${EMPTY}
    [Teardown]  SSHLibrary.Close Connection

    # Description of argument(s):
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

    # Description of argument(s):
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


Copy PNOR to BMC
    [Documentation]  Copy the PNOR image to the BMC.
    Import Library      SCPLibrary      WITH NAME       scp
    Open Connection for SCP
    Log    Copying ${PNOR_IMAGE_PATH} to /tmp
    scp.Put File    ${PNOR_IMAGE_PATH}   /tmp


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


Initialize DBUS cmd
    [Documentation]  Initialize dbus string with property string to extract
    [Arguments]   ${boot_property}

    # Description of argument(s):
    # boot_property   Property string.

    ${cmd}=     Catenate  ${dbuscmdBase} ${dbuscmdGet} ${dbuscmdString}
    ${cmd}=     Catenate  ${cmd}${boot_property}
    Set Global Variable   ${dbuscmd}     ${cmd}


Create OS Console Command String
    [Documentation]  Return a command string to start OS console logging.

    # First make sure that the ssh_pw program is available.
    ${cmd}=  Catenate  which ssh_pw 2>/dev/null || find
    ...  ${EXECDIR} -name 'ssh_pw'

    Rdpissuing  ${cmd}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd}
    Rdpvars  rc  output

    Should Be Equal As Integers  0  ${rc}  msg=Could not find ssh_pw.

    ${ssh_pw_file_path}=  Set Variable  ${output}

    ${cmd}=  Catenate  ${ssh_pw_file_path} ${OPENBMC_PASSWORD} -p 2200
    ...  -o "StrictHostKeyChecking no" ${OPENBMC_USERNAME}@${OPENBMC_HOST}

    [Return]  ${cmd}


Get SOL Console Pid
    [Documentation]  Get the pid of the active SOL console job.
    [Arguments]  ${expect_running}=${0}

    # Description of argument(s):
    # expect_running  If set and if no SOL console job is found, print debug
    #                 info and fail.

    # Find the pid of the active system console logging session (if any).
    ${search_string}=  Create OS Console Command String
    # At least in some cases, ps output does not show double quotes so we must
    # replace them in our search string with the regexes to indicate that they
    # are optional.
    ${search_string}=  Replace String  ${search_string}  "  ["]?
    ${ps_cmd}=  Catenate  ps axwwo user,pid,cmd
    ${cmd_buf}=  Catenate  echo $(${ps_cmd} | egrep '${search_string}' |
    ...  egrep -v grep | cut -c10-14)
    Rdpissuing  ${cmd_buf}
    ${rc}  ${os_con_pid}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  os_con_pid
    # If rc is not zero it just means that there is no OS Console process
    # running.

    Return From Keyword If  '${os_con_pid}' != '${EMPTY}'  ${os_con_pid}
    Return From Keyword If  '${expect_running}' == '${0}'  ${os_con_pid}

    Cmd Fnc  cat ${log_file_path} ; echo ; ${ps_cmd}  quiet=${0}
    ...  print_output=${1}  show_err=${1}

    Should Not Be Empty  ${os_con_pid}


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

    Wait Until Keyword Succeeds  10 seconds  0 seconds
    ...   Get SOL Console Pid  ${1}

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
    [Arguments]       ${file_path}=/tmp/journal_log  ${filter}=${EMPTY}

    # Description of arguments:
    # file_path   The file path of the journal file.

    ${cur_time}=    Get Time Stamp
    Set Global Variable   ${LOG_TIME}   ${cur_time}
    Open Connection And Log In
    Start Command
    ...  journalctl -f ${filter} > ${file_path}-${LOG_TIME}
    Log    Journal Log Started: ${file_path}-${LOG_TIME}


Stop Journal Log
    [Documentation]   Stop journalctl process if its running.
    ...               By default return log from /tmp/journal_log else
    ...               user input location.
    [Arguments]       ${file_path}=/tmp/journal_log

    # Description of arguments:
    # file_path   The file path of the journal file.

    Open Connection And Log In

    ${rc}=
    ...  Execute Command
    ...  ps | grep journalctl | grep -v grep
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

    # Description of arguments:
    # i_macaddress   The MAC address.

    ${mac_hex}=  Catenate  0x${i_macaddress.replace(':', ' 0x')}
    [Return]    ${mac_hex}


IP Address To Hex String
    [Documentation]   Converts IP address into hex format.
    ...               Example:
    ...               Given the following IP: 10.3.164.100
    ...               This keyword will return: 0xa 0x3 0xa4 0xa0
    [Arguments]    ${i_ipaddress}

    # Description of arguments:
    # i_macaddress   The IP address in the format 10.10.10.10.

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
    ${bmc_cpu_usage_output}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${bmc_cpu_usage_cmd}
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
    # Filesystem            Size    Used Available Use% Mounted on
    # /dev/root            14.4M     14.4M       0 100% /
    # /dev/ubiblock0_0     14.4M     14.4M       0 100% /media/rofs-c9249b0e
    # /dev/ubiblock8_0     19.6M     19.6M       0 100% /media/pnor-ro-8764baa3
    # /dev/ubiblock4_0     14.4M     14.4M       0 100% /media/rofs-407816c
    # /dev/ubiblock8_4     21.1M     21.1M       0 100% /media/pnor-ro-cecc64c4
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
    :FOR  ${var}  IN RANGE  1  4
    \     BMC CPU Performance check


Check BMC Mem Performance
    [Documentation]   Minimal 10% of memory should be free

    :FOR  ${var}  IN RANGE  1  4
    \     BMC Mem Performance check


Check BMC File System Performance
    [Documentation]  Check for file system usage for 4 times

    :FOR  ${var}  IN RANGE  1  4
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

    # Description of argument(s):
    # vacuum_size    Size of journal.

    Open Connection And Log In
    ${output}  ${stderr}  ${rc}=
    ...  Execute Command
    ...  journalctl --vacuum-size=${vacuum_size}
    ...  return_stderr=True  return_rc=True

    Should Be Equal  ${rc}  ${0}  msg=${stderr}


Get System Power Policy
    [Documentation]  Returns the BMC power policy.

    # Set the bmc_power_policy_method to either 'Old' or 'New'.
    Set Power Policy Method
    ${cmd_buf}=  Create List  ${bmc_power_policy_method} Get Power Policy
    # Run the appropriate keyword.
    ${currentPolicy}=  Run Keyword  @{cmd_buf}

    [Return]  ${currentPolicy}


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
    [Documentation]  Returns boot time from /proc/stat.

    Open Connection And Log In
    ${output}  ${stderr}=
    ...  Execute Command  egrep '^btime ' /proc/stat | cut -f 2 -d ' '
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${btime}=  Convert To Integer  ${output}
    [Return]  ${btime}


Enable Core Dump On BMC
    [Documentation]  Enable core dump collection.
    ${core_pattern}  ${stderr}  ${rc}=  BMC Execute Command
    ...  echo '/tmp/core_%e.%p' | tee /proc/sys/kernel/core_pattern
    Should Be Equal As Strings  ${core_pattern}  /tmp/core_%e.%p


Get Number Of BMC Core Dump Files
    [Documentation]  Returns number of core dump files on BMC.
    Open Connection And Log In
    ${num_of_core_dump}=  Execute Command
    ...  ls /tmp/core* 2>/dev/null | wc -l
    [Return]  ${num_of_core_dump}


Set Core Dump File Size Unlimited
    [Documentation]  Set core dump file size to unlimited.
    BMC Execute Command  ulimit -c unlimited


Check For Core Dumps
    [Documentation]  Check for any core dumps exist.
    ${output}=  Get Number Of BMC Core Dump Files
    Run Keyword If  ${output} > 0
    ...  Log  **Warning** BMC core dump files exist  level=WARN


Configure Initial Settings
    [Documentation]  Restore old IP and route.
    ...  This keyword requires initial settings viz IP address,
    ...  Network Mask, default gatway and serial console IP and port
    ...  information which should be provided in command line.

    [Arguments]  ${host}=${OPENBMC_HOST}  ${mask}=${NET_MASK}
    ...          ${gw_ip}=${GW_IP}

    # Description of arguments:
    # host  IP address of the OS Host.
    # mask  Network mask.
    # gu_ip  Gateway IP address or hostname.

    # Open telnet connection and ignore the error, in case telnet session is
    # already opened by the program calling this keyword.
    Run Keyword And Ignore Error  Open Telnet Connection to BMC Serial Console
    Telnet.write  ifconfig eth0 ${host} netmask ${mask}
    Telnet.write  route add default gw ${gw_ip}


Install Debug Tarball On BMC
    [Documentation]  Copy the debug tar file to BMC and install.
    [Arguments]  ${tarball_file_path}=${default_tarball}
    ...  ${targ_tarball_dir_path}=/tmp/tarball/

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
    [Documentation]  Returns BMC boot count based on boot time.
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


Delete Error Log Entry
    [Documentation]  Delete error log entry.
    [Arguments]  ${entry_path}

    # Description of argument(s):
    # entry_path  Delete an error log entry.
    #             Ex. /xyz/openbmc_project/logging/entry/1

    # Skip delete if entry URI is a callout.
    # Examples:
    # /xyz/openbmc_project/logging/entry/1/callout
    # /xyz/openbmc_project/logging/entry/1/callouts/0
    ${callout_entry}=  Run Keyword And Return Status
    ...  Should Match Regexp  ${entry_path}  /callout[s]?(/|$)
    Return From Keyword If  ${callout_entry}

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Delete Request  ${entry_path}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Get BMC Version
    [Documentation]  Returns BMC version from /etc/os-release.
    ...              e.g. "v1.99.6-141-ge662190"

    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    [Return]  ${output}


Get PNOR Version
    [Documentation]  Returns the PNOR version from the BMC.

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

    ${time}=  Get BMC Date Time
    ${time_diff}=  Evaluate
    ...  ${time['universal_time_seconds']} - ${time['rtc_time_seconds']}
    Should Be True  ${time_diff} < ${time_diff_max}


Validate IP On BMC
    [Documentation]  Validate IP address is present in set of IP addresses.
    [Arguments]  ${ip_address}  ${ip_data}

    # Description of argument(s):
    # ip_address  IP address to check (e.g. xx.xx.xx.xx).
    # ip_data     Set of the IP addresses present.

    Should Contain Match  ${ip_data}  ${ip_address}/*
    ...  msg=${ip_address} not found in the list provided.


Remove Journald Logs
    [Documentation]  Remove all journald logs and restart service.

    ${cmd}=  Catenate  systemctl stop systemd-journald.service &&
    ...  rm -rf /var/log/journal && systemctl start systemd-journald.service

    BMC Execute Command  ${cmd}


Check For Regex In Journald
    [Documentation]  Parse the journal log and check for regex string.
    [Arguments]  ${regex}=${ERROR_REGEX}  ${error_check}=${0}  ${boot}=${EMPTY}

    # Description of argument(s):
    # regex            Strings to be filter.
    # error_check      Check for errors.
    # boot             Argument to check current or persistent full boot log
    #                  (e.g. "-b").

    ${journal_log}  ${stderr}  ${rc}=  BMC Execute Command
    ...  journalctl --no-pager ${boot} | egrep '${regex}'  ignore_err=1

    Run Keyword If  ${error_check} == ${0}
    ...    Should Be Empty  ${journal_log}
    ...  ELSE
    ...    Should Not Be Empty  ${journal_log}


Get Service Attribute
    [Documentation]  Get service attribute policy output.
    [Arguments]  ${option}  ${servicename}

    # Description of argument(s):
    # option       systemctl supported options
    # servicename  Qualified service name
    ${cmd}=  Set Variable
    ...  systemctl -p ${option} show ${servicename} | cut -d = -f2
    ${attr}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    [Return]  ${attr}
