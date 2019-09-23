*** Settings ***

Documentation  Websocket functionality test.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The username for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
# OS_HOST            The OS host name or IP address.
# OS_USERNAME        The username for the OS login.
# OS_PASSWORD        The password for OS_USERNAME.

Resource             ../../lib/esel_utils.robot
Resource             ../../lib/bmc_redfish_resource.robot
Resource             ../../lib/logging_utils.robot
Library              ../../lib/gen_cmd.py
Library              OperatingSystem


Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution
Test Teardown        Test Teardown Execution


*** Variables ***

#${monitor_pgm}          websocket_monitor.py
${monitor_pgm}          python ${EXECDIR}/bin/websocket_monitor.py
${monitor_file}         websocket_monitor_out.txt
${expected_string}      eSEL received over websocket interface
${min_number_chars}     22
${monitor_cmd}          ${monitor_pgm} ${OPENBMC_HOST} --openbmc_username ${OPENBMC_USERNAME}


*** Test Cases ***


Test BMC Websocket Interface
    [Documentation]  Verify eSELs are seen over the websocket interface.
    [Tags]  Test_BMC_Websocket_Interface

    Log To Console  ========================================= SMS000 ============================
    ${bmc_version}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/os-release
    Printn
    Rprint Vars  bmc_version
    Log To Console  ========================================= SMS000 ============================

    ${dirlist}=  List Directory  ${EXECDIR}/bin
    Rprint Vars  dirlist
    Log To Console  ========================================= SMS000A ============================


    # Spawn the websocket monitor program and then generate an eSEL.
    # The monitor should asynchronously receive the eSEL through the
    # websocket interface and report this fact to standard output.

    Start Websocket Monitor

    ${initial_esel_count}=  Get Number Of Event Logs

    # Generate eSEL (e.g.  typically "CPU 1 core 3 has failed").
    Create eSEL

    ${current_esel_count}=   Get Number Of Event Logs



    Log To Console  ========================================= SMS001 ============================
    Rprint Vars  initial_esel_count  current_esel_count
    Log To Console  ========================================= SMS001 ============================
    Run Keyword If  ${initial_esel_count} == ${current_esel_count}
    ...  Fail  msg=System failed to generate eSEL upon request.

    ${line}=  Grep File  ${monitor_file}  ${expected_string}
    # Typical monitor_file contents:
    # --------------- ON_MESSAGE:begin --------------------
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_project.Logging.
    # Entry","path":"/xyz/openbmc_project/logging/entry/5","properties":{"Id":5}}
    # eSEL received over websocket interface.

    ${num_chars}=  Get Length  ${line}
    Run Keyword If  ${num_chars} < ${min_number_chars}  Fail
    ...  msg=No eSEL notification from websocket_monitor.py.


*** Keywords ***


Start Websocket Monitor
    [Documentation]  Fork the monitor to run in the background.

    # Delete the previous output file, if any.
    Remove File  ${monitor_file}

    # Start the monitor. Fork so its a parallel task.
    Shell Cmd
    ...  ${monitor_cmd} --openbmc_password ${OPENBMC_PASSWORD} 1>${monitor_file} 2>&1  fork=${1}

    # Allow time for the monitor to initialize.
    Sleep  5s


Find Websocket Monitor
    [Documentation]  Return the process Id(s) of running websocket monitors.

    ${cmd}=  Catenate  ps -ef | grep '${monitor_cmd}'
    ...  | grep -v grep | grep -v bash | cut -c10-14
    ${shell_rc}  ${pid}=  Shell Cmd  ${cmd}
    # There may be more than one pid returned if there is an instance
    # of a monitory_pgm running from a previous run.
    @{pid_list}=  Split String  ${pid}
    [Return]  ${pid_list}


Kill Websocket Monitor
    [Documentation]  Terminate running websocket monitor.

    ${pid_list}=  Find Websocket Monitor
    FOR  ${pid}  IN  @{pid_list}
        Shell Cmd  kill -s SIGTERM ${pid}
    END


Print Websocket Monitor Log
    [Documentation]  Show the contents of the monitor output file.

    ${websocket_monitor_log}=  OperatingSystem.Get File  ${monitor_file}
    Log to Console  websocket_monitor_log:
    Log to Console  ${websocket_monitor_log}


Suite Setup Execution
    [Documentation]  Do the suite setup tasks.

    Run Keyword  Redfish Power On  stack_mode=skip

    Redfish.Login

    Delete All Error Logs
    Kill Websocket Monitor

    # Allow time for Error Logs to be deleted.
    Sleep  5s


Test Teardown Execution
    [Documentation]  Do teardown tasks after a test.

    ####FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  Print Websocket Monitor Log
    Kill Websocket Monitor


Suite Teardown Execution
    [Documentation]  Do the post-suite teardown.

    Delete All Error Logs
    Run Keyword and Return Status  Redfish.Logout
