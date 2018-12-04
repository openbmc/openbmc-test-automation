*** Settings ***

Documentation  Utilities for Robot keywords that use REST.

Resource                ../lib/resource.txt
Resource                ../lib/rest_client.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/boot_utils.robot
Resource                ../lib/common_utils.robot
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
    # interfal      Interval to wait between status checks.
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

    ${data}=  Create Dictionary  data=${milliseconds}
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

    REST Power On  stack_mode=skip  quiet=1

    SSHLibrary.Open Connection  ${os_host}
    ${resp}=  Login  ${os_username}  ${os_password}
    [Return]  ${resp}


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
    [Return]  ${turbo_setting}


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
    Write Attribute  ${BMC_LOGGING_URI}${/}rest_api_logs  Enabled
    ...  data=${log_dict}  verify=${1}  expected_value=${policy_setting}
