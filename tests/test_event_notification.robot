*** Settings ***
Documentation  Event notification test cases.

Library         ../lib/gen_cmd.py
Library         ../lib/var_funcs.py
Library         ../lib/gen_robot_valid.py
Library         ../lib/gen_robot_keyword.py
Resource        ../lib/resource.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/rest_client.robot

Test Setup      Printn

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Subscribe And Verify Event Notification
    [Documentation]  Subscribe and verify event notification.
    [Tags]  Subscribe_And_Verify_Event_Notification
    [Teardown]  Run Keyword And Ignore Error  Kill Cmd  ${popen}

    ${cmd_buf}=  Catenate  event_notification_util.py --quiet=1 --host=${OPENBMC_HOST}
    ...  --password=${OPENBMC_PASSWORD} --dbus_path=${CONTROL_HOST_URI}power_cap
    ${popen}=  Shell Cmd  ${cmd_buf}  return_stderr=1  fork=1
    Rprint Vars  popen.pid
    Qprint Timen  Allow child event_notification_util.py job to begin to wait for the event notification.
    Run Key U  Sleep \ 5 seconds

    # Get current reading for debug.
    ${original_power_cap_settings}=  Read Properties  ${CONTROL_HOST_URI}power_cap  quiet=1
    Rprint Vars  original_power_cap_settings

    # Set power limit out of range.
    ${power_cap}=  Evaluate  random.randint(1000, 3000)  modules=random
    Rprint Vars  original_power_cap_settings  power_cap
    ${data}=  Create Dictionary  data=${power_cap}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCap  data=${data}

    Qprint Timen  Wait for child event_notification_util.py job to see the event notification.
    Run Key U  Sleep \ 5 seconds

    Qprint Timen  Retrieving output from spawned event_notification_util.py job.
    ${rc}  ${stdout}  ${stderr}=  Kill Cmd  ${popen}
    Run Keyword If  ${rc}  Log to Console  ${stderr}
    Valid Value  rc  [0]
    ${event_notification}=  Key Value Outbuf To Dict  ${stdout}  process_indent=1
    Rprint Vars  event_notification

    # Example output:
    # interface:     xyz.openbmc_project.Control.Power.Cap
    # path:          /xyz/openbmc_project/control/host0/power_cap
    # event:         PropertiesChanged
    # properties:
    # PowerCap:      1318

    Valid Value  event_notification['event']  ['PropertiesChanged']
    Valid Value  event_notification['properties']['powercap']  ['${power_cap}']