*** Settings ***
Resource                ../lib/resource.txt
Resource                ../lib/rest_client.robot
Resource                ../lib/connection_client.robot
Library                 DateTime
Library                 Process
Library                 OperatingSystem
Library                 gen_print.py
Library                 gen_robot_print.py

*** Variables ***
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
${bmc_file_system_usage_cmd}=
...  df -h | grep -v /run/initramfs/ro | cut -c 52-54 | grep 100 | wc -l

${BOOT_TIME}     ${0}
${BOOT_COUNT}    ${0}
${count}  ${0}
${devicetree_base}  /sys/firmware/devicetree/base/model

*** Keywords ***

Get BMC System Model
    [Documentation]  Get the BMC model from the device tree.

    ${bmc_model}  ${stderr}=  Execute Command
    ...  cat ${devicetree_base} | cut -d " " -f 1  return_stderr=True
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
    [Arguments]  ${quiet}=${QUIET}

    ${state}=  Read Attribute  ${OPENBMC_BASE_URI}sensors/host/BootProgress
    ...  value  quiet=${quiet}
    [Return]  ${state}

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

    SSHLibrary.Open connection  ${os_host}
    Login  ${os_username}  ${os_password}
    ${cmd_buf}  Catenate  shutdown
    Start Command  ${cmd_buf}
    SSHLibrary.Close Connection

Initiate OS Host Reboot
    [Documentation]  Initiate an OS reboot.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Description of arguments:
    # os_host      The DNS name or IP of the OS.
    # os_username  The username to be used to sign in to the OS.
    # os_password  The password to be used to sign in to the OS.

    SSHLibrary.Open connection  ${os_host}
    Login  ${os_username}  ${os_password}
    ${cmd_buf}  Catenate  reboot
    Start Command  ${cmd_buf}
    SSHLibrary.Close Connection

Initiate Auto Reboot
    [Documentation]  Initiate an auto reboot.

    # Set the auto reboot policy.
    Set Auto Reboot  yes

    SSHLibrary.Open connection  ${openbmc_host}
    Login  ${openbmc_username}  ${openbmc_password}

    # Set the watchdog timer.  Note: 5000 = milliseconds which is 5 seconds.
    ${cmd_buf}=  Catenate  /usr/sbin/mapper call /org/openbmc/watchdog/host0
    ...  org.openbmc.Watchdog set i 5000
    ${output}  ${stderr}  ${rc}=  Execute Command  ${cmd_buf}
    ...  return_stderr=True  return_rc=True
    Should Be Empty  ${stderr}
    Should be equal  ${rc}  ${0}

    # Start the watchdog.
    ${cmd_buf}=  Catenate  /usr/sbin/mapper call /org/openbmc/watchdog/host0
    ...  org.openbmc.Watchdog start
    ${output}  ${stderr}  ${rc}=  Execute Command  ${cmd_buf}
    ...  return_stderr=True  return_rc=True
    Should Be Empty  ${stderr}
    Should be equal  ${rc}  ${0}

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

Get BMC State Deprecated
    [Documentation]  Returns the state of the BMC as a string. (i.e: BMC_READY)
    [Arguments]  ${quiet}=${QUIET}

    @{arglist}=  Create List
    ${args}=  Create Dictionary  data=@{arglist}
    ${resp}=  Call Method  ${OPENBMC_BASE_URI}managers/System/  getSystemState
    ...        data=${args}  quiet=${quiet}
    Should be equal as strings  ${resp.status_code}  ${HTTP_OK}
    ${content}=  to json  ${resp.content}
    [Return]  ${content["data"]}

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
    ${resp}=  Call Method  ${OPENBMC_BASE_URI}control/flash/bios/  update
    ...  data=${args}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Wait Until Keyword Succeeds    2 min   10 sec    Is PNOR Flashing

Get Flash BIOS Status
    [Documentation]  Returns the status of the flash BIOS API as a string. For
    ...              example 'Flashing', 'Flash Done', etc
    ${data}=      Read Properties     ${OPENBMC_BASE_URI}control/flash/bios
    [Return]    ${data['status']}

Is PNOR Flashing
    [Documentation]  Get BIOS 'Flashing' status. This indicates that PNOR
    ...              flashing has started.
    ${status}=    Get Flash BIOS Status
    should be equal as strings     ${status}     Flashing

Is PNOR Flash Done
    [Documentation]  Get BIOS 'Flash Done' status.  This indicates that the
    ...              PNOR flashing has completed.
    ${status}=    Get Flash BIOS Status
    should be equal as strings     ${status}     Flash Done

Is System State Host Booted
    [Documentation]  Checks whether system state is HOST_BOOTED.
    ${state}=    Get BMC State Deprecated
    should be equal as strings     ${state}     HOST_BOOTED

Is OS Starting
    [Documentation]  Check if boot progress is OS starting.
    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  FW Progress, Starting OS

Is OS Off
    [Documentation]  Check if boot progress is "Off".
    ${boot_progress}=  Get Boot Progress
    Should Be Equal  ${boot_progress}  Off

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

    # Description of arguements:
    # file_path  The caller's candidate value.  If this value is ${EMPTY}, this
    #            keyword will compose a file path name.  Otherwise, this
    #            keyword will use the caller's file_path value.  In either
    #            case, the value will be returned.

    ${default_file_path}=  Catenate  /tmp/${OPENBMC_HOST}_os_console
    ${log_file_path}=  Set Variable If  '${log_file_path}' == '${EMPTY}'
    ...  ${default_file_path}  ${log_file_path}

    [Return]  ${log_file_path}

Create OS Console Command String
    [Documentation]  Return a command string to start OS console logging.

    # First make sure that the ssh_pw program is available.
    ${cmd_buf}=  Catenate  which ssh_pw 2>&1
    Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  rc  output
    Should Be Equal  ${rc}  ${0}  msg=${output}\n

    ${cmd_buf}=  Catenate  ssh_pw ${OPENBMC_PASSWORD} -p 2200
    ...  ${OPENBMC_USERNAME}@${OPENBMC_HOST}

    [Return]  ${cmd_buf}

Stop SOL Console Logging
    [Documentation]  Stop system console logging and return log output.
    [Arguments]  ${log_file_path}=${EMPTY}  ${targ_file_path}=${EMPTY}

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

    ${log_file_path}=  Create OS Console File Path  ${log_file_path}
    # Find the pid of the active system console logging session (if any).
    ${search_string}=  Create OS Console Command String
    ${cmd_buf}=  Catenate  echo $(ps -ef | egrep '${search_string}'
    ...  | egrep -v grep | cut -c10-14)
    Rdpissuing  ${cmd_buf}
    ${rc}  ${os_con_pid}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  os_con_pid
    # If rc is not zero it just means that there is no OS Console process
    # running.

    ${cmd_buf}=  Catenate  kill -9 ${os_con_pid}
    Run Keyword If  '${os_con_pid}' != '${EMPTY}'  Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run Keyword If  '${os_con_pid}' != '${EMPTY}'
    ...  Run And Return Rc And Output  ${cmd_buf}
    Run Keyword If  '${os_con_pid}' != '${EMPTY}'  Rdpvars  rc  output

    ${cmd_buf}=  Set Variable  cat ${log_file_path} 2>&1
    Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_buf}
    Rdpvars  rc

    Run Keyword If  '${targ_file_path}' != '${EMPTY}'
    ...  Run Keyword And Ignore Error
    ...  Copy File  ${log_file_path}  ${targ_file_path}

    [Return]  ${output}

Start SOL Console Logging
    [Documentation]  Start system console log to file.
    [Arguments]  ${log_file_path}=${EMPTY}

    # This keyword will first call "Stop SOL Console Logging".  Only then will
    # it start SOL console logging.  The data returned by "Stop SOL Console
    # Logging" will in turn be returned by this keyword.

    # Description of arguments:
    # log_file_path  The file path to which system console log data should be
    #                written.  Note that this path is taken to be a location on
    #                the machine where this program is running rather than on
    #                the Open BMC system.

    ${log_file_path}=  Create OS Console File Path  ${log_file_path}

    ${log_output}=  Stop SOL Console Logging  ${log_file_path}

    # Validate by making sure we can create the file.  Problems creating the
    # file would not be noticed by the subsequent ssh command because we fork
    # the command.
    Create File  ${log_file_path}
    ${sub_cmd_buf}=  Create OS Console Command String
    # Routing stderr to stdout so that any startup error text will go to the
    # output file.
    ${cmd_buf}=  Catenate  ${sub_cmd_buf} > ${log_file_path} 2>&1 &
    Rdpissuing  ${cmd_buf}
    ${rc}  ${output}=  Run And Return Rc And Output  ${cmd_buf}
    # Because we are forking this command, we essentially will never get a
    # non-zero return code or any output.
    Should Be Equal  ${rc}  ${0}

    [Return]  ${log_output}

Get Time Stamp
    [Documentation]     Get the current time stamp data
    ${cur_time}=    Get Current Date   result_format=%Y%m%d%H%M%S%f
    [Return]   ${cur_time}


Verify BMC State
    [Documentation]   Get the BMC state and verify if the current
    ...               BMC state is as expected.
    [Arguments]       ${expected}

    ${current}=  Get BMC State Deprecated
    Should Contain  ${expected}   ${current}

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

    ${bmc_cpu_usage_output}  ${stderr}=  Execute Command  ${bmc_cpu_usage_cmd}
    ...                   return_stderr=True
    Should be empty  ${stderr}
    ${bmc_cpu_percentage}=  Fetch From Left  ${bmc_cpu_usage_output}  %
    Should be true  ${bmc_cpu_percentage} < 90

BMC Mem Performance Check
    [Documentation]   Minimal 10% of memory should be free in this instance

    ${bmc_mem_free_output}  ${stderr}=   Execute Command  ${bmc_mem_free_cmd}
    ...                   return_stderr=True
    Should be empty  ${stderr}

    ${bmc_mem_total_output}  ${stderr}=   Execute Command  ${bmc_mem_total_cmd}
    ...                   return_stderr=True
    Should be empty  ${stderr}

    ${bmc_mem_percentage}=   Evaluate  ${bmc_mem_free_output}*100
    ${bmc_mem_percentage}=  Evaluate
    ...   ${bmc_mem_percentage}/${bmc_mem_total_output}
    Should be true  ${bmc_mem_percentage} > 10

BMC File System Usage Check
    [Documentation]   Check the file system space. None should be 100% full
    ...   except /run/initramfs/ro
    ${bmc_fs_usage_output}  ${stderr}=   Execute Command
    ...   ${bmc_file_system_usage_cmd}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Be True  ${bmc_fs_usage_output}==0

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
    [arguments]   ${policy}

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}

Get System Power Policy
    [Documentation]  Get the BMC power policy.
    ${currentPolicy}=  Read Attribute  ${HOST_SETTING}  power_policy
    [Return]  ${currentPolicy}

Get Auto Reboot
    [Documentation]  Returns auto reboot setting.
    ${setting}=  Read Attribute  ${HOST_SETTING}  auto_reboot
    [Return]  ${setting}


Set Auto Reboot
    [Documentation]  Set the given auto reboot setting.
    [Arguments]  ${setting}
    # setting  auto reboot's setting, i.e. yes or no

    ${valueDict}=  Set Variable  ${setting}
    ${data}=  Create Dictionary  data=${valueDict}
    Write Attribute  ${HOST_SETTING}  auto_reboot  data=${data}
    ${current_setting}=  Get Auto Reboot
    Should Be Equal  ${current_setting}  ${setting}


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

Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog error using BMC.
    [Arguments]  ${milliseconds}=1000  ${sleep_time}=5s
    # Description of arguments:
    # milliseconds  The time watchdog timer value in milliseconds (e.g. 1000 = 1 second).
    # sleep_time    Time delay for host watchdog error to get injected.
    #               Default is 5 seconds.

    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog set i ${milliseconds}
    Execute Command On BMC
    ...  /usr/sbin/mapper call /org/openbmc/watchdog/host0 org.openbmc.Watchdog start
    Sleep  ${sleep_time}

Login To OS Host
    [Documentation]  Login to OS Host.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}
    # Desription of arguments:
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    ${os_state}=  Run Keyword And Return Status  Ping Host  ${os_host}
    Run Keyword If  '${os_state}' == 'False'
    ...  Run Keywords  Initiate Host Reboot  AND
    ...  Is Host Running  AND
    ...  Wait for OS  ${os_host}  ${os_username}  ${os_password}

    Open Connection  ${os_host}
    Login  ${os_username}  ${os_password}

Configure Initial Settings
    [Documentation]  Restore old IP and route.
    ...  This keyword requires initial settings viz IP address,
    ...  Network Mask, default gatway and serial console IP and port
    ...  information which should be provided in command line.

    [Arguments]  ${host}=${OPENBMC_HOST}  ${mask}=${NET_MASK}  ${gw_ip}=${GW_IP}

    # Open telnet connection and ignore the error, in case telnet session is already
    # opened by the program calling this keyword.

    Run Keyword And Ignore Error  Open Telnet Connection to BMC Serial Console
    Telnet.write  ifconfig eth0 ${host} netmask ${mask}
    Telnet.write  route add default gw ${gw_ip}

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
