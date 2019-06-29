*** Settings ***

Documentation  Websocket functionality test.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The username for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.

Resource             ../lib/esel_utils.robot
Resource             ../lib/bmc_redfish_resource.robot
Resource             ../lib/logging_utils.robot
Library              ../lib/gen_cmd.py
Library              OperatingSystem


Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution
Test Teardown        Test Teardown Execution


*** Variables ***

${monitor_pgm}          tools/websocket_monitor.py
${monitor_output_file}  websocket_monitor_out.txt
${expected_string}      eSEL received over websocket interface
${min_number_expected_chars}  20


*** Test Cases ***


Test BMC Websocket Interface
    [Documentation]  Verify eSELs are seen over the websocket interface.
    [Tags]  Test_BMC_Websocket_Interface

    # Spawn the websocket monitor program and then generate an eSEL.
    # The monitor should receive the eSEL through the websocket interface
    # and report this fact to standard output.

    Start Websocket Monitor

    ${initial_esel_count}=  Count Event Logs

    # Generate eSEL (e.g.  typically "CPU 1 core 3 has failed").
    Create eSEL

    ${current_esel_count}=   Count Event Logs

    Rprint Vars  initial_esel_count  current_esel_count
    Run Keyword If  ${initial_esel_count} == ${current_esel_count}
    ...  Fail  msg=Could not generate eSEL.

    # Typical monitor_outupt_file contents:
    # ---------------- ON_MESSAGE:begin --------------------
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_project.Logging.
    # Entry","path":"/xyz/openbmc_project/logging/entry/5","properties":{"Id":5}}
    # eSEL received over websocket interface.

    ${lines}=  Grep File  ${monitor_output_file}  ${expected_string}
    ${len}=  Get Length  ${lines}
    Run Keyword If  ${len} < ${min_number_expected_chars}  Fail
    ...  msg=No eSEL notification over websocket.


*** Keywords ***


Start Websocket Monitor
    [Documentation]  Fork the monitor to run in the background.

    # Delete the previous output file, if any.
    Remove File  ${monitor_output_file}

    # Start the monitor.
    ${cmd}=  Catenate
    ...  python ${monitor_pgm} ${OPENBMC_HOST} ${OPENBMC_USERNAME}
    ...  ${OPENBMC_PASSWORD} 1>${monitor_output_file} 2>&1
    Shell Cmd  ${cmd}  fork=${1}


Find Websocket Monitor
    [Documentation]  Return the process Id of the running websocket monitor.

    # The returned pid may be ${EMPTY} if the monitor has
    # already terminated.

    ${cmd}=  Catenate  ps -ef |
    ...  grep 'python ${monitor_pgm} ${OPENBMC_HOST} ${OPENBMC_USERNAME}'
    ...  | grep -v grep | cut -c10-14
    ${shell_rc}  ${pid}=  Shell Cmd  ${cmd}
    ${pid}=  Strip String  ${pid}
    [Return]  ${pid}


Kill Websocket Monitor
    [Documentation]  Terminate the websocket monitor if its running.

    ${pid}=  Find Websocket Monitor
    Return From Keyword If  '${pid}'=='${EMPTY}'
    Shell Cmd  kill -s SIGTERM ${pid}


Print Websocket Monitor Log
    [Documentation]  Show the contents of the monitor output file.

    ${websocket_monitor_log}=  OperatingSystem.Get File  ${monitor_output_file}
    Log to Console  websocket_monitor_log:
    Log to Console  ${websocket_monitor_log}


Suite Setup Execution
    [Documentation]  Do the suite setup tasks.

    ${is_redfish}=  Run Keyword And Return Status  Redfish.Login
    ${rest_keyword}=  Set Variable If  ${is_redfish}  Redfish  REST

    Run Keyword  ${rest_keyword} Power On  stack_mode=skip

    Delete All Error Logs
    Printn


Test Teardown Execution
    [Documentation]  Do teardown tasks after a test.

    FFDC On Test Case Fail
    Kill Websocket Monitor
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  Print Websocket Monitor Log


Suite Teardown Execution
    [Documentation]  Do the post-suite teardown.

    Delete All Error Logs
    Run Keyword and Return Status  Redfish.Logout
