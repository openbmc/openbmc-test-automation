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
# /dev/mtdblock5 filesystem  should be 100% full always
${bmc_file_system_usage_cmd}=
...  df -h | grep -v /dev/mtdblock5 | cut -c 52-54 | grep 100 | wc -l

${BOOT_TIME}     ${0}
${BOOT_COUNT}    ${0}

*** Keywords ***

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
    [Teardown]  Close Connection

    # os_host           The DNS name/IP of the OS host associated with our BMC.
    # os_username       The username to be used to sign on to the OS host.
    # os_password       The password to be used to sign on to the OS host.
    # quiet             Indicates whether this keyword should write to console.
    # print_string      A string to be printed before checking the OS.

    rprint  ${print_string}

    # Attempt to ping the OS. Store the return code to check later.
    ${ping_rc}=  Run Keyword and Return Status  Ping Host  ${os_host}

    Open connection  ${os_host}

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


Stop OBMC Console Client
    [Documentation]   Stop any running obmc_console_client
    ...               writing to file_path.
    [Arguments]   ${file_path}=/tmp/obmc-console.log

    ${cmd_buf}=  Catenate  SEPARATOR=${SPACE}
    ...  ps ax | grep obmc-console-client | grep ${file_path} | grep -v grep
    ...  | awk '{print $1}'

    ${pid}=
    ...  Execute Command  ${cmd_buf}

    Run Keyword If  '${pid}' != '${EMPTY}'
    ...  Execute Command  kill -s KILL ${pid}
    ...  ELSE  Log  "No obmc-console-client process running"


Start SOL Console Logging
    [Documentation]   Start a new obmc_console_client process and direct
    ...               output to a file.
    [Arguments]   ${file_path}=/tmp/obmc-console.log

    Open Connection And Log In

    Stop OBMC Console Client  ${file_path}

    Start Command
    ...  obmc-console-client > ${file_path}


Stop SOL Console Logging
    [Documentation]  Stop obmc_console_client process, if any, and
    ...              return the console output as a string.
    [Arguments]  ${file_path}=/tmp/obmc-console.log  ${targ_file_path}=${EMPTY}

    # Description of arguments:
    # file_path       The path on the obmc system where SOL output may be
    #                 found.
    # targ_file_path  If specified, the file path to which SOL data should be
    #                 written.

    Open Connection And Log In

    Stop OBMC Console Client  ${file_path}

    ${cmd_buf}=  Set Variable  cat ${file_path}

    ${console}  ${stderr}=
    ...  Execute Command
    ...  if [ -f ${file_path} ] ; then cat ${file_path} ; fi
    ...  return_stderr=True
    Should Be Empty  ${stderr}

    Run Keyword If  '${targ_file_path}' != '${EMPTY}'
    ...  Append To File  ${targ_file_path}  ${console}

    [Return]  ${console}

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
    ...   except /dev/mtdblock5
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
    Should Contain   ${stderr}  Vacuuming done

Set BMC Power Policy
    [Documentation]   Set the given BMC power policy.
    [arguments]   ${policy}

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}


Set BMC Reset Reference Time
    [Documentation]  Set current boot time as a reference and increment
    ...               boot count.

    ${cur_btime}=  Get BMC Boot Time
    Run Keyword If  ${cur_btime} > ${BOOT_TIME}
    ...  Run Keywords
    ...  Set Global Variable  ${BOOT_TIME}  ${cur_btime}
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
