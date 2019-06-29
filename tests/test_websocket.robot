*** Settings ***

Documentation  Websocket functionality test.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.

Resource             ../lib/esel_utils.robot
Resource             ../lib/bmc_redfish_resource.robot
Library              ../lib/gen_cmd.py
Library              OperatingSystem


Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution
Test Teardown        Test Teardown Execution


*** Variables ***

${monitor_pgm}          tools/websocket_monitor.py
${monitor_output_file}  websocket_monitor_out.txt
${expected_string}      eSEL received over websocket interface


*** Test Cases ***


Test BMC Websocket Interface
    [Documentation]  Verify eSELs are seen over the websocket interface.
    [Tags]  Test_BMC_Websocket_Interface

    # After starting the websocket monitor program in the background,
    # this TC will generate an eSEL.
    # The monitor program will receive the eSEL message
    # through the websocket interface and write an indication that the
    # eSEL was received to a file.

    Start Websocket Monitor

    ${initial_esel_count}=  Count Number Of eSELs

    # Generate eSEL, typically "CPU 1 core 3 has failed".
    Create eSEL

    ${current_esel_count}=   Count Number Of eSELs

    Rprint Vars  initial_esel_count  current_esel_count
    Run Keyword If  ${initial_esel_count} == ${current_esel_count}
    ...  Fail  msg=Could not generate eSEL.

    ${lines}=  Grep File  ${monitor_output_file}  ${expected_string}
    ${len}=  Get Length  ${lines}
    Run Keyword If  ${len} < 3  Fail
    ...  msg=No eSEL notification over websocket.


*** Keywords ***


Count Number Of eSELs
    [Documentation]  Count eSELs.

    ${esels}=  Redfish.Get Attribute  ${EVENT_LOG_URI}Entries  Members
    ${num_elogs}=  Get Length  ${esels}
    [Return]  ${num_elogs}


Start Websocket Monitor
    [Documentation]  Fork the monitor to run in the background.

    # Delete the previous output file, if any.
    Remove File  ${monitor_output_file}

    # Start the monitor.
    ${cmd}=  Catenate
    ...  python ${monitor_pgm} ${OPENBMC_HOST} ${OPENBMC_USERNAME}
    ...  ${OPENBMC_PASSWORD} 1>${monitor_output_file} 2>&1
    Shell Cmd  ${cmd}  fork=${1}


Show Websocket Monitor Log
    [Documentation]  Show the contents of the monitor output file.

    ${websocket_monitor_log}=  OperatingSystem.Get File  ${monitor_output_file}
    Rprint Vars  websocket_monitor_log


Test Teardown Execution
    [Documentation]  Do teardown tasks after a test.

    FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  Show Websocket Monitor Log


Suite Setup Execution
    [Documentation]  Do the suite setup tasks.

    ${is_redfish}=  Run Keyword And Return Status  Redfish.Login
    ${rest_keyword}=  Set Variable If  ${is_redfish}  Redfish  REST
    Rprint Vars  rest_keyword

    Run Keyword  ${rest_keyword} Power On  stack_mode=skip

    Delete All Error Logs
    Printn


Suite Teardown Execution
    [Documentation]  Do the post-suite teardown.

    Delete All Error Logs
    Redfish.Logout
