*** Settings ***

Documentation  Utilities for Robot keywords that use REST.

Resource                ../lib/resource.robot
Resource                ../lib/rest_client.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Resource                ../lib/common_utils.robot
Resource                ../lib/bmc_redfish_utils.robot
Library                 String
Library                 DateTime
Library                 Process
Library                 OperatingSystem
Library                 gen_print.py
Library                 gen_misc.py
Library                 gen_robot_print.py
Library                 gen_cmd.py
Library                 gen_robot_keyword.py
Library                 bmc_ssh_utils.py
Library                 utils.py
Library                 var_funcs.py
Library                 SCPLibrary  WITH NAME  scp
Library                 gen_robot_valid.py
Library                 pldm_utils.py


*** Variables ***

${SYSTEM_SHUTDOWN_TIME}   ${5}

# Assign default value to QUIET for programs which may not define it.
${QUIET}  ${0}

${HOST_SETTING}    ${SETTINGS_URI}host0

${boot_prog_method}               ${EMPTY}
${power_policy_setup}             ${0}
${bmc_power_policy_method}        ${EMPTY}
@{BOOT_PROGRESS_STATES}           SystemHardwareInitializationComplete  OSBootStarted  OSRunning

${REDFISH_SYS_STATE_WAIT_TIMEOUT}    120 Seconds

*** Keywords ***


Verify Ping and REST Authentication
    [Documentation]  Verify ping and rest authentication.
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


Verify Ping SSH And Redfish Authentication
    [Documentation]  Verify ping, SSH and redfish authentication.

    ${l_ping}=   Run Keyword And Return Status  Ping Host  ${OPENBMC_HOST}
    Run Keyword If  '${l_ping}' == '${False}'  Fail   msg=Ping Failed

    ${l_rest}=   Run Keyword And Return Status   Redfish.Login
    Run Keyword If  '${l_rest}' == '${False}'  Fail   msg=REST Authentication Failed

    # Just to make sure the SSH is working.
    Open Connection And Log In
    ${system}   ${stderr}=    Execute Command   hostname   return_stderr=True
    Should Be Empty     ${stderr}


Check If BMC is Up
    [Documentation]  Wait for Host to be online. Checks every X seconds
    ...              interval for Y minutes and fails if timed out.
    ...              Default MAX timedout is 10 min, interval 10 seconds.
    [Arguments]      ${max_timeout}=${OPENBMC_REBOOT_TIMEOUT} min
    ...              ${interval}=10 sec

    # Description of argument(s):
    # max_timeout   Maximum time to wait.
    #               This should be expressed in Robot Framework's time format
    #               (e.g. "10 minutes").
    # interval      Interval to wait between status checks.
    #               This should be expressed in Robot Framework's time format
    #               (e.g. "5 seconds").

    Wait Until Keyword Succeeds
    ...   ${max_timeout}  ${interval}   Verify Ping and REST Authentication


Flush REST Sessions
    [Documentation]   Removes all the active session objects
    Delete All Sessions


Trigger Host Watchdog Error
    [Documentation]  Inject host watchdog timeout error via REST.
    [Arguments]  ${milliseconds}=1000  ${sleep_time}=5s

    # Description of argument(s):
    # milliseconds  The time watchdog timer value in milliseconds (e.g. 1000 =
    #               1 second).
    # sleep_time    Time delay for host watchdog error to get injected.
    #               Default is 5 seconds.

    ${data}=  Create Dictionary
    ...  data=xyz.openbmc_project.State.Watchdog.Action.PowerCycle
    ${status}  ${result}=  Run Keyword And Ignore Error
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  ExpireAction
    Run Keyword If  '${status}' == 'PASS'
    ...  Write Attribute  ${HOST_WATCHDOG_URI}  ExpireAction  data=${data}

    ${int_milliseconds}=  Convert To Integer  ${milliseconds}
    ${data}=  Create Dictionary  data=${int_milliseconds}
    Write Attribute  ${HOST_WATCHDOG_URI}  Interval  data=${data}

    ${data}=  Create Dictionary  data=${True}
    Write Attribute  ${HOST_WATCHDOG_URI}  Enabled  data=${data}

    Sleep  ${sleep_time}


Login To OS Host
    [Documentation]  Login to OS Host and return the Login response code.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}

    # Description of arguments:
    # ${os_host} IP address of the OS Host.
    # ${os_username}  OS Host Login user name.
    # ${os_password}  OS Host Login passwrd.

    Redfish Power On  stack_mode=skip  quiet=1

    SSHLibrary.Open Connection  ${os_host}
    ${resp}=  SSHLibrary.Login  ${os_username}  ${os_password}
    RETURN  ${resp}


Initiate Auto Reboot
    [Documentation]  Initiate an auto reboot.
    [Arguments]  ${milliseconds}=5000

    # Description of argument(s):
    # milliseconds  The number of milliseconds for the watchdog timer.

    # Set the auto reboot policy.
    Set Auto Reboot  ${1}
    # Set the watchdog timer.
    Trigger Host Watchdog Error  ${milliseconds}


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


Initiate OS Host Power Off
    [Documentation]  Initiate an OS reboot.
    [Arguments]  ${os_host}=${OS_HOST}  ${os_username}=${OS_USERNAME}
    ...          ${os_password}=${OS_PASSWORD}  ${hard}=${0}

    # Description of argument(s):
    # os_host      The DNS name or IP of the OS.
    # os_username  The username to be used to sign in to the OS.
    # os_password  The password to be used to sign in to the OS.
    # hard         Indicates whether to do a hard vs. soft power off.

    ${time_string}=  Run Keyword If  ${hard}  Set Variable  ${SPACE}now
    ...  ELSE  Set Variable  ${EMPTY}

    ${cmd_buf}=  Run Keyword If  '${os_username}' == 'root'
    ...      Set Variable  shutdown${time_string}
    ...  ELSE
    ...      Set Variable  echo ${os_password} | sudo -S shutdown${time_string}

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  ${cmd_buf}  fork=${1}


Set System LED State
    [Documentation]  Set given system LED via REST.
    [Arguments]  ${led_name}  ${led_state}
    # Description of argument(s):
    # led_name     System LED name (e.g. heartbeat, identify, beep).
    # led_state    LED state to be set (e.g. On, Off).

    ${args}=  Create Dictionary
    ...  data=xyz.openbmc_project.Led.Physical.Action.${led_state}
    Write Attribute  ${LED_PHYSICAL_URI}${led_name}  State  data=${args}

    Verify LED State  ${led_name}  ${led_state}


Read Turbo Setting Via REST
    [Documentation]  Return turbo setting via REST.
    # Returns 1 if TurboAllowed, 0 if not.

    ${turbo_setting}=  Read Attribute
    ...  ${CONTROL_HOST_URI}turbo_allowed  TurboAllowed
    RETURN  ${turbo_setting}


Set Turbo Setting Via REST
    [Documentation]  Set turbo setting via REST.
    [Arguments]  ${setting}  ${verify}=${False}

    # Description of argument(s):
    # setting  State to set TurboAllowed, 1=allowed, 0=not allowed.
    # verify   If True, read the TurboAllowed setting to confirm.

    ${data}=  Create Dictionary  data=${${setting}}
    Write Attribute  ${CONTROL_HOST_URI}turbo_allowed  TurboAllowed
    ...  verify=${verify}  data=${data}


Set REST Logging Policy
    [Documentation]  Enable or disable REST logging setting.
    [Arguments]  ${policy_setting}=${True}

    # Description of argument(s):
    # policy_setting    The policy setting value which can be either
    #                   True or False.

    ${log_dict}=  Create Dictionary  data=${policy_setting}
    Write Attribute  ${BMC_LOGGING_URI}rest_api_logs  Enabled
    ...  data=${log_dict}  verify=${1}  expected_value=${policy_setting}


Old Get Boot Progress
    [Documentation]  Get the boot progress the old way (via org location).
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    ${state}=  Read Attribute  ${OPENBMC_BASE_URI}sensors/host/BootProgress
    ...  value  quiet=${quiet}

    RETURN  ${state}


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


Initiate Power On
    [Documentation]  Initiates the power on and waits until the Is Power On
    ...  keyword returns that the power state has switched to on.
    [Arguments]  ${wait}=${1}

    # Description of argument(s):
    # wait   Indicates whether to wait for a powered on state after issuing
    #        the power on command.

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

    RETURN  ${state}


New Get Boot Progress
    [Documentation]  Get the boot progress the new way (via xyz location).
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    ${state}=  Read Attribute  ${HOST_STATE_URI}  BootProgress  quiet=${quiet}

    RETURN  ${state.rsplit('.', 1)[1]}


New Get Power Policy
    [Documentation]  Returns the BMC power policy (new method).
    ${currentPolicy}=  Read Attribute  ${POWER_RESTORE_URI}  PowerRestorePolicy

    RETURN  ${currentPolicy}


Old Get Power Policy
    [Documentation]  Returns the BMC power policy (old method).
    ${currentPolicy}=  Read Attribute  ${HOST_SETTING}  power_policy

    RETURN  ${currentPolicy}


Redfish Get Power Restore Policy
    [Documentation]  Returns the BMC power restore policy.

    ${power_restore_policy}=  Redfish.Get Attribute  /redfish/v1/Systems/${SYSTEM_ID}  PowerRestorePolicy
    RETURN  ${power_restore_policy}


Get Auto Reboot
    [Documentation]  Returns auto reboot setting.
    ${setting}=  Read Attribute  ${CONTROL_HOST_URI}/auto_reboot  AutoReboot

    RETURN  ${setting}


Redfish Get Auto Reboot
    [Documentation]  Returns auto reboot setting.

    ${resp}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Attribute  /redfish/v1/Systems/${SYSTEM_ID}  Boot
    RETURN  ${resp["AutomaticRetryConfig"]}


Trigger Warm Reset
    [Documentation]  Initiate a warm reset.

    log to console    "Triggering warm reset"
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=  Openbmc Post Request
    ...  ${OPENBMC_BASE_URI}control/bmc0/action/warmReset  data=${data}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Fail   msg=warm reset didn't occur

    Sleep   ${SYSTEM_SHUTDOWN_TIME}min
    Check If BMC Is Up


Get Power State
    [Documentation]  Returns the power state as an integer. Either 0 or 1.
    [Arguments]  ${quiet}=${QUIET}

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console.

    @{arglist}=  Create List
    ${args}=  Create Dictionary  data=@{arglist}

    ${resp}=  Call Method  ${OPENBMC_BASE_URI}control/chassis0/  getPowerState
    ...        data=${args}  quiet=${quiet}
    Should be equal as strings  ${resp.status_code}  ${HTTP_OK}

    RETURN  ${resp.json()["data"]}


Clear BMC Gard Record
    [Documentation]  Clear gard records from the system.

    @{arglist}=  Create List
    ${args}=  Create Dictionary  data=@{arglist}
    ${resp}=  Call Method
    ...  ${OPENPOWER_CONTROL}gard  Reset  data=${args}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Flash PNOR
    [Documentation]    Calls flash bios update method to flash PNOR image
    [Arguments]    ${pnor_image}

    # Description of argument(s):
    # pnor_image  The filename and path of the PNOR image
    #             (e.g. "/home/image/zaius.pnor").

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
    RETURN    ${data['status']}


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


Create OS Console File Path
    [Documentation]  Create OS console file path name and return it.
    [Arguments]  ${log_file_path}=${EMPTY}

    # Description of arguments:
    # file_path  The caller's candidate value.  If this value is ${EMPTY}, this
    #            keyword will compose a file path name.  Otherwise, this
    #            keyword will use the caller's file_path value.  In either
    #            case, the value will be returned.

    ${status}=  Run Keyword And Return Status  Variable Should Exist
    ...  ${TEST_NAME}

    ${default_file_path}=  Set Variable If  ${status} == ${TRUE}
    ...  ${EXECDIR}${/}tmp${/}${OPENBMC_HOST}_${TEST_NAME.replace(' ', '')}_os_console.txt
    ...  ${EXECDIR}${/}tmp${/}${OPENBMC_HOST}_os_console.txt

    ${log_file_path}=  Set Variable If  '${log_file_path}' == '${EMPTY}'
    ...  ${default_file_path}  ${log_file_path}

    RETURN  ${log_file_path}


Get Endpoint Paths
    [Documentation]   Returns all url paths ending with given endpoint
    ...               Example:
    ...               Given the following endpoint: cpu
    ...               This keyword will return: list of all urls ending with
    ...               cpu -
    ...               /org/openbmc/inventory/system/chassis/motherboard/cpu0,
    ...               /org/openbmc/inventory/system/chassis/motherboard/cpu1
    [Arguments]   ${path}   ${endpoint}

    # Description of arguments:
    # path       URL path for enumeration.
    # endpoint   Endpoint string (url path ending).

    # Make sure path ends with slash.
    ${path}=  Add Trailing Slash  ${path}

    ${resp}=  Read Properties  ${path}enumerate  timeout=30
    Log Dictionary  ${resp}

    ${list}=  Get Dictionary Keys  ${resp}
    # For a given string, look for prefix and suffix for matching expression.
    # Start of string followed by zero or more of any character followed by
    # any digit or lower case character.
    ${resp}=  Get Matches  ${list}  regexp=^.*[0-9a-z_].${endpoint}\[_0-9a-z]*$  case_insensitive=${True}

    RETURN  ${resp}


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


Delete Error Logs
    [Documentation]  Delete error logs.
    [Arguments]  ${quiet}=${0}
    # Description of argument(s):
    # quiet    If enabled, turns off logging to console.

    # Check if error logs entries exist, if not return.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}

    # Get the list of error logs entries and delete them all.
    ${elog_entries}=  Get URL List  ${BMC_LOGGING_ENTRY}
    FOR  ${entry}  IN  @{elog_entries}
        Delete Error Log Entry  ${entry}  quiet=${quiet}
    END


Delete All Error Logs
    [Documentation]  Delete all error log entries using "DeleteAll" interface.

    ${args}=  Set Variable   {"data": []}
    ${resp}=  Openbmc Post Request  ${BMC_LOGGING_URI}action/DeleteAll
    ...  data=${args}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Get Elog URL List
    [Documentation]  Return error log entry list of URLs.

    ${url_list}=  Read Properties  /xyz/openbmc_project/logging/entry/
    Sort List  ${url_list}
    RETURN  ${url_list}


Get BMC Flash Chip Boot Side
    [Documentation]  Return the BMC flash chip boot side.

    # Example:
    # 0  - indicates chip select is current side.
    # 32 - indicates chip select is alternate side.

    ${boot_side}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /sys/class/watchdog/watchdog1/bootstatus

    RETURN  ${boot_side}


Watchdog Object Should Exist
    [Documentation]  Check that watchdog object exists.

    ${resp}=  OpenBMC Get Request  ${WATCHDOG_URI}host0
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Expected watchdog object does not exist.


Get System LED State
    [Documentation]  Return the state of given system LED.
    [Arguments]  ${led_name}

    # Description of argument(s):
    # led_name     System LED name (e.g. heartbeat, identify, beep).

    ${state}=  Read Attribute  ${LED_PHYSICAL_URI}${led_name}  State
    RETURN  ${state.rsplit('.', 1)[1]}


Verify LED State
    [Documentation]  Checks if LED is in given state.
    [Arguments]  ${led_name}  ${led_state}
    # Description of argument(s):
    # led_name     System LED name (e.g. heartbeat, identify, beep).
    # led_state    LED state to be verified (e.g. On, Off).

    ${state}=  Get System LED State  ${led_name}
    Should Be Equal  ${state}  ${led_state}


Get LED State XYZ
    [Documentation]  Returns state of given LED.
    [Arguments]  ${led_name}

    # Description of argument(s):
    # led_name  Name of LED.

    ${state}=  Read Attribute  ${LED_GROUPS_URI}${led_name}  Asserted
    # Returns the state of the LED, either On or Off.
    RETURN  ${state}


Verify Identify LED State
    [Documentation]  Verify that the identify state of the LED group matches caller's expectations.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state  The expected LED asserted state (1 = asserted, 0 = not asserted).

    ${led_state}=  Get LED State XYZ  enclosure_identify
    Should Be Equal  ${led_state}  ${expected_state}  msg=Unexpected LED state.

Verify The Attribute
    [Documentation]  Verify the given attribute.
    [Arguments]  ${uri}  ${attribute_name}  ${attribute_value}

    # Description of argument(s):
    # uri              URI path
    #                  (e.g. "/xyz/openbmc_project/control/host0/TPMEnable").
    # attribute_name   Name of attribute to be verified (e.g. "TPMEnable").
    # attribute_value  The expected value of attribute (e.g. "1", "0", etc.)

    ${output}=  Read Attribute  ${uri}  ${attribute_name}
    Should Be Equal  ${attribute_value}  ${output}
    ...  msg=Attribute "${attribute_name} does not have the expected value.


New Set Power Policy
    [Documentation]   Set the given BMC power policy (new method).
    [Arguments]   ${policy}

    # Description of argument(s):
    # policy    Power restore policy (e.g. ${ALWAYS_POWER_OFF}).

    ${valueDict}=  Create Dictionary  data=${policy}
    Write Attribute
    ...  ${POWER_RESTORE_URI}  PowerRestorePolicy  data=${valueDict}


Old Set Power Policy
    [Documentation]   Set the given BMC power policy (old method).
    [Arguments]   ${policy}

    # Description of argument(s):
    # policy    Power restore policy (e.g. "ALWAYS_POWER_OFF").

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}


Redfish Set Power Restore Policy
    [Documentation]   Set the BMC power restore policy.
    [Arguments]   ${power_restore_policy}

    # Description of argument(s):
    # power_restore_policy    Power restore policy (e.g. "AlwaysOff", "AlwaysOn", "LastState").

    Redfish.Patch  /redfish/v1/Systems/${SYSTEM_ID}  body={"PowerRestorePolicy": "${power_restore_policy}"}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


IPMI Set Power Restore Policy
    [Documentation]   Set the BMC power restore policy using IPMI.
    [Arguments]   ${power_restore_policy}=always-off

    # Description of argument(s):
    # power_restore_policy    Power restore policies
    #                         always-on   : turn on when power is restored
    #                         previous    : return to previous state when power is restored
    #                         always-off  : stay off after power is restored

    ${resp}=  Run IPMI Standard Command  chassis policy ${power_restore_policy}
    # Example:  Set chassis power restore policy to always-off
    Should Contain  ${resp}  ${power_restore_policy}


Set Auto Reboot Setting
    [Documentation]  Set the given auto reboot setting (REST or Redfish).
    [Arguments]  ${value}

    # Description of argument(s):
    # value    The reboot setting, 1 for enabling and 0 for disabling.

    # This is to cater to boot call points and plugin script which will always
    # send using value 0 or 1. This dictionary maps to redfish string values.
    ${rest_redfish_dict}=  Create Dictionary
    ...                    1=RetryAttempts
    ...                    0=Disabled

    Run Keyword If  ${REDFISH_SUPPORT_TRANS_STATE} == ${1}
    ...    Redfish Set Auto Reboot  ${rest_redfish_dict["${value}"]}
    ...  ELSE
    ...    Set Auto Reboot  ${value}

Set Auto Reboot
    [Documentation]  Set the given auto reboot setting.
    [Arguments]  ${setting}

    # Description of argument(s):
    # setting    The reboot setting, 1 for enabling and 0 for disabling.

    ${valueDict}=  Convert To Integer  ${setting}
    ${data}=  Create Dictionary  data=${valueDict}
    Write Attribute  ${CONTROL_HOST_URI}/auto_reboot  AutoReboot   data=${data}
    ${current_setting}=  Get Auto Reboot
    Should Be Equal As Integers  ${current_setting}  ${setting}


Redfish Set Auto Reboot
    [Documentation]  Set the given auto reboot setting.
    [Arguments]  ${setting}

    # Description of argument(s):
    # setting    The reboot setting, "RetryAttempts" and "Disabled".

    Redfish.Patch  /redfish/v1/Systems/${SYSTEM_ID}  body={"Boot": {"AutomaticRetryConfig": "${setting}"}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${current_setting}=  Redfish Get Auto Reboot
    Should Be Equal As Strings  ${current_setting}  ${setting}


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


Is Power On
    [Documentation]  Verify that the BMC chassis state is on.
    ${state}=  Get Power State
    Should be equal  ${state}  ${1}


Is Power Off
    [Documentation]  Verify that the BMC chassis state is off.
    ${state}=  Get Power State
    Should be equal  ${state}  ${0}


CLI Get BMC DateTime
    [Documentation]  Returns BMC date time from date command.

    ${bmc_time_via_date}  ${stderr}  ${rc}=  BMC Execute Command  date +"%Y-%m-%d %H:%M:%S"  print_err=1
    RETURN  ${bmc_time_via_date}


Update Root Password
    [Documentation]  Update system "root" user password.
    [Arguments]  ${openbmc_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # openbmc_password   The root password for the open BMC system.

    @{password}=  Create List  ${openbmc_password}
    ${data}=  Create Dictionary  data=@{password}

    ${headers}=  Create Dictionary  Content-Type=application/json  X-Auth-Token=${XAUTH_TOKEN}
    ${resp}=  POST On Session  openbmc  ${BMC_USER_URI}root/action/SetPassword
    ...  data=${data}  headers=${headers}
    Valid Value  resp.status_code  [${HTTP_OK}]


Get Post Boot Action
    [Documentation]  Get post boot action.

    # Post code update action dictionary.
    #
    # {
    #    BMC image: {
    #        OnReset: Redfish OBMC Reboot (off),
    #        Immediate: Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}
    #    },
    #    Host image: {
    #        OnReset: RF SYS GracefulRestart,
    #        Immediate: Wait State  os_running_match_state  10 mins
    #    }
    # }

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${post_code_update_actions}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/applytime_table.json'))  modules=json
    Rprint Vars  post_code_update_actions

    RETURN  ${post_code_update_actions}


Get Task State From File
    [Documentation]  Get task states from pre-define data/task_state.json file.

    # Example:  Task state JSON format.
    #
    # {
    #   "TaskRunning": {
    #           "TaskState": "Running",
    #           "TaskStatus": "OK"
    #   },
    #   "TaskCompleted": {
    #           "TaskState": "Completed",
    #           "TaskStatus": "OK"
    #   },
    #   "TaskException": {
    #           "TaskState": "Exception",
    #           "TaskStatus": "Warning"
    #   }
    # }

    # Python module: get_code_base_dir_path()
    ${code_base_dir_path}=  Get Code Base Dir Path
    ${task_state}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/task_state.json'))  modules=json
    Rprint Vars  task_state

    RETURN  ${task_state}


Redfish Set Boot Default
    [Documentation]  Set and Verify Boot source override
    [Arguments]      ${override_enabled}  ${override_target}  ${override_mode}=UEFI

    # Description of argument(s):
    # override_enabled    Boot source override enable type.
    #                     ('Once', 'Continuous', 'Disabled').
    # override_target     Boot source override target.
    #                     ('Pxe', 'Cd', 'Hdd', 'Diags', 'BiosSetup', 'None').
    # override_mode       Boot source override mode (relevant only for x86 arch).
    #                     ('Legacy', 'UEFI').

    ${data}=  Create Dictionary  BootSourceOverrideEnabled=${override_enabled}
    ...  BootSourceOverrideTarget=${override_target}

    Run Keyword If  '${PLATFORM_ARCH_TYPE}' == 'x86'
    ...  Set To Dictionary  ${data}  BootSourceOverrideMode  ${override_mode}

    ${payload}=  Create Dictionary  Boot=${data}

    Redfish.Patch  /redfish/v1/Systems/${SYSTEM_ID}  body=&{payload}
    ...  valid_status_codes=[${HTTP_OK},${HTTP_NO_CONTENT}]

    ${resp}=  Redfish.Get Attribute  /redfish/v1/Systems/${SYSTEM_ID}  Boot
    Should Be Equal As Strings  ${resp["BootSourceOverrideEnabled"]}  ${override_enabled}
    Should Be Equal As Strings  ${resp["BootSourceOverrideTarget"]}  ${override_target}
    Run Keyword If  '${PLATFORM_ARCH_TYPE}' == 'x86'
    ...  Should Be Equal As Strings  ${resp["BootSourceOverrideMode"]}  ${override_mode}


# Redfish state keywords.

Redfish Get BMC State
    [Documentation]  Return BMC health state.

    # "Enabled" ->  BMC Ready, "Starting" -> BMC NotReady

    # Example:
    # "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "Enabled"
    # },

    ${status}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  Status
    RETURN  ${status["State"]}


Redfish Verify BMC State
    [Documentation]  Verify BMC state is enabled.
    [Arguments]  ${match_state}=Enabled

    # Description of argument(s):
    # match_state    Expected match state (e.g. Enabled, Starting, Error)

    ${Status}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  Status

    Should Be Equal As Strings  ${match_state}  ${Status['State']}


Redfish Get Host State
    [Documentation]  Return host power and health state.

    # Refer: http://redfish.dmtf.org/schemas/v1/Resource.json#/definitions/Status

    # Example:
    # "PowerState": "Off",
    # "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "StandbyOffline"
    # },

    ${chassis}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Properties  /redfish/v1/Chassis/${CHASSIS_ID}
    RETURN  ${chassis["PowerState"]}  ${chassis["Status"]["State"]}


Redfish Get Boot Progress
    [Documentation]  Return boot progress state.

    # Example: /redfish/v1/Systems/system/
    # "BootProgress": {
    #    "LastState": "OSRunning"
    # },

    ${boot_progress}=  Wait Until Keyword Succeeds  1 min  20 sec
    ...  Redfish.Get Properties  /redfish/v1/Systems/${SYSTEM_ID}/

    Return From Keyword If  "${PLATFORM_ARCH_TYPE}" == "x86"
    ...  NA  ${boot_progress["Status"]["State"]}

    RETURN  ${boot_progress["BootProgress"]["LastState"]}  ${boot_progress["Status"]["State"]}


Redfish Get States
    [Documentation]  Return all the BMC and host states in dictionary.
    [Timeout]  ${REDFISH_SYS_STATE_WAIT_TIMEOUT}

    # Refer: openbmc/docs/designs/boot-progress.md

    Redfish.Login

    ${bmc_state}=  Redfish Get BMC State
    ${chassis_state}  ${chassis_status}=  Redfish Get Host State
    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress

    ${states}=  Create Dictionary
    ...  bmc=${bmc_state}
    ...  chassis=${chassis_state}
    ...  host=${host_state}
    ...  boot_progress=${boot_progress}

    # Disable loggoing state to prevent huge log.html record when boot
    # test is run in loops.
    #Log  ${states}

    RETURN  ${states}


Is BMC Not Quiesced
    [Documentation]  Verify BMC state is not quiesced.

    ${bmc_state}=   Redfish Get States

    Log To Console  BMC State : ${bmc_state}

    Should Not Be Equal As Strings  Quiesced  ${bmc_state['bmc']}


Is BMC Standby
    [Documentation]  Check if BMC is ready and host at standby.

    ${standby_states}=  Create Dictionary
    ...  bmc=Enabled
    ...  chassis=Off
    ...  host=Disabled
    ...  boot_progress=None

    Run Keyword If  '${PLATFORM_ARCH_TYPE}' == 'x86'
    ...  Set To Dictionary  ${standby_states}  boot_progress=NA

    Wait Until Keyword Succeeds  3 min  10 sec  Redfish Get States

    Wait Until Keyword Succeeds  5 min  10 sec  Match State  ${standby_states}


Match State
    [Documentation]  Check if the expected and current states are matched.
    [Arguments]  ${match_state}

    # Description of argument(s):
    # match_state      Expected states in dictionary.

    ${current_state}=  Redfish Get States
    Dictionaries Should Be Equal  ${match_state}  ${current_state}


Wait For Host Boot Progress To Reach Required State
    [Documentation]  Wait till host boot progress reaches required state.
    [Arguments]      ${expected_boot_state}=OSRunning

    # Description of argument(s):
    # expected_boot_state    Expected boot state. E.g. OSRunning, SystemInitComplete etc.

    Wait Until Keyword Succeeds  ${power_on_timeout}  20 sec
    ...  Is Boot Progress At Required State  ${expected_boot_state}


Redfish Initiate Auto Reboot
    [Documentation]  Initiate an auto reboot.
    [Arguments]  ${interval}=2000

    # Description of argument(s):
    # interval  Value in milliseconds to set Watchdog interval

    # Set auto reboot policy
    Redfish Set Auto Reboot  RetryAttempts

    Redfish Power Operation  On

    Wait Until Keyword Succeeds  2 min  5 sec  Is Boot Progress Changed

    # Set watchdog timer
    Set Watchdog Interval Using Busctl  ${interval}


Is Boot Progress Changed
    [Documentation]  Get BootProgress state and expect boot state mismatch.
    [Arguments]  ${boot_state}=None

    # Description of argument(s):
    # boot_state   Value of the BootProgress state to match against.

    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress

    Should Not Be Equal  ${boot_progress}   ${boot_state}


Is Boot Progress At Required State
    [Documentation]  Get BootProgress state and expect boot state to match.
    [Arguments]  ${boot_state}=None

    # Description of argument(s):
    # boot_state   Value of the BootProgress state to match.

    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress

    Should Be Equal  ${boot_progress}   ${boot_state}


Is Boot Progress At Any State
    [Documentation]  Get BootProgress state and expect boot state to match
    ...              with any of the states mentioned in the list.
    [Arguments]  ${boot_states}=@{BOOT_PROGRESS_STATES}

    # Description of argument(s):
    # boot_states   List of the BootProgress states to match.

    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress
    Should Contain Any  ${boot_progress}  @{boot_states}


Is Host At State
    [Documentation]  Get Host state and check if it matches
    ...   user input expected state.
    [Arguments]  ${expected_host_state}

    # Description of argument(s):
    # expected_host_state  Expected Host State to check.(e.g. Quiesced).

    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress

    Should Be Equal  ${host_state}  ${expected_host_state}


Set Watchdog Interval Using Busctl
    [Documentation]  Set Watchdog time interval.
    [Arguments]  ${milliseconds}=1000

    # Description of argument(s):
    # milliseconds     Time interval for watchdog timer

    ${cmd}=  Catenate  busctl set-property xyz.openbmc_project.Watchdog
    ...                /xyz/openbmc_project/watchdog/host0
    ...                xyz.openbmc_project.State.Watchdog Interval t ${milliseconds}
    BMC Execute Command  ${cmd}


Stop PLDM Service And Wait
    [Documentation]  Stop PLDM service and wait for Host to initiate reset.

    BMC Execute Command  systemctl stop pldmd.service


Get BIOS Attribute
    [Documentation]  Get the BIOS attribute for /redfish/v1/Systems/system/Bios.

    # Python module:  get_member_list(resource_path)
    ${systems}=  Redfish_Utils.Get Member List  /redfish/v1/Systems
    ${bios_attr_dict}=  Redfish.Get Attribute  ${systems[0]}/Bios  Attributes

    RETURN  ${bios_attr_dict}


Set BIOS Attribute
    [Documentation]  PATCH the BIOS attribute for /redfish/v1/Systems/system/Bios.
    [Arguments]  ${attribute_name}  ${attribute_value}

    # Description of argument(s):
    # attribute_name     Any valid BIOS attribute.
    # attribute_value    Valid allowed attribute values.

    # Python module:  get_member_list(resource_path)
    ${systems}=  Redfish_Utils.Get Member List  /redfish/v1/Systems
    Redfish.Patch  ${systems[0]}/Bios/Settings  body={"Attributes":{"${attribute_name}":"${attribute_value}"}}


Is BMC Operational
    [Documentation]  Check if BMC is enabled.
    [Teardown]  Redfish.Logout

    Wait Until Keyword Succeeds  5 min  5 sec  Ping Host  ${OPENBMC_HOST}
    # In some of bmc stack, network services will gets loaded before redfish/ipmi services gets loaded.
    # Hence, 3mins sleep time is added to allow other service gets loaded.
    Sleep  180s
    Redfish.login
    ${bmc_status}=  Redfish Get BMC State
    Should Be Equal  ${bmc_status}  Enabled


PLDM Set BIOS Attribute
    [Documentation]  Set the BIOS attribute via pldmtool and verify the attribute is set.
    ...              Defaulted for fw_boot_side for boot test usage caller.
    [Arguments]  ${attribute_name}=fw_boot_side  ${attribute_value}=Temp

    # Description of argument(s):
    # attribute_name      Valid BIOS attribute name e.g ("fw_boot_side")
    # attribute_value     Valid BIOS attribute value for fw_boot_side.

    # PLDM response output example:
    # {
    #    "Response": "SUCCESS"
    # }

    ${resp}=  pldmtool  bios SetBIOSAttributeCurrentValue -a ${attribute_name} -d ${attribute_value}
    Should Be Equal As Strings  ${resp["Response"]}  SUCCESS

    # PLDM GET output example:
    # {
    #    "CurrentValue": "Temp"
    # }

    ${pldm_output}=  PLDM Get BIOS Attribute  ${attribute_name}
    Should Be Equal As Strings  ${pldm_output["CurrentValue"]}  ${attribute_value}
    ...  msg=Expecting ${attribute_value} but got ${pldm_output["CurrentValue"]}


PLDM Get BIOS Attribute
    [Documentation]  Get the BIOS attribute via pldmtool for a given attribute and return value.
    [Arguments]  ${attribute_name}

    # Description of argument(s):
    # attribute_name     Valid BIOS attribute name e.g ("fw_boot_side")

    ${pldm_output}=  pldmtool  bios GetBIOSAttributeCurrentValueByHandle -a ${attribute_name}
    RETURN  ${pldm_output}


Verify Host Power State
    [Documentation]  Get the Host Power state and compare it with the expected state.
    [Arguments]  ${expected_power_state}

    # Description of argument(s):
    # expected_power_state   State of Host e.g. Off or On.

    ${power_state}  ${health_status}=  Redfish Get Host State
    Should Be Equal  ${power_state}  ${expected_power_state}


Verify Host Is Up
    [Documentation]  Verify Host is Up.

    Wait Until Keyword Succeeds  3 min  30 sec  Verify Host Power State  On
    # Python module:  os_execute(cmd)
    Wait Until Keyword Succeeds  10 min  30 sec  OS Execute Command  uptime
