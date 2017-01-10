*** Settings ***
Documentation  Do random repeated boots based on the state of the BMC machine.
...  The number of repetitions is designated by ${max_num_tests}. Keyword
...  names that are listed in @{AVAIL_BOOTS} become the selection of possible
...  boots for the test.

Resource  ../lib/dvt/obmc_driver_vars.txt
Resource  ../lib/list_utils.robot
Resource  ../lib/openbmc_ffdc.robot

Library   ../lib/gen_robot_print.py
Library   ../lib/gen_misc.py
Library   ../lib/gen_robot_plug_in.py
Library   ../lib/gen_robot_valid.py
Library   ../lib/state.py
Library   ../lib/boot/powerons.py
Library   ../lib/boot/poweroffs.py
Library   ../lib/obmc_boot_test.py

#  WITH NAME  boot_results

*** Variables ***
# Initialize program parameters variables.
# Create parm_list containing all of our program parameters.  This is used by
# 'Rqprint Pgm Header'
@{parm_list}                openbmc_nickname  openbmc_host  openbmc_username
...  openbmc_password  os_host  os_username  os_password  pdu_host
...  pdu_username  pdu_password  pdu_slot_no  openbmc_serial_host
...  openbmc_serial_port  boot_stack  boot_list  max_num_tests
...  plug_in_dir_paths  status_file_path  openbmc_model  boot_pass  boot_fail
...  ffdc_dir_path_style  ffdc_check  state_change_timeout  power_on_timeout
...  power_on_timeout  test_mode  quiet  debug

# Initialize each program parameter.
${openbmc_nickname}         ${EMPTY}
${openbmc_host}             ${EMPTY}
${openbmc_username}         root
${openbmc_password}         0penBmc
${os_host}                  ${EMPTY}
${os_username}              root
${os_password}              P@ssw0rd
${pdu_host}                 ${EMPTY}
${pdu_username}             admin
${pdu_password}             admin
${pdu_slot_no}              ${EMPTY}
${openbmc_serial_host}      ${EMPTY}
${openbmc_serial_port}      ${EMPTY}
${boot_stack}               ${EMPTY}
${boot_list}                ${EMPTY}
${max_num_tests}            0
${plug_in_dir_paths}        ${EMPTY}
${status_file_path}         ${EMPTY}
${openbmc_model}            ${EMPTY}
# The reason boot_pass and boot_fail are parameters is that it is possible to
# be called by a program that has already done some tests.  This allows us to
# keep the grand total.
${boot_pass}                ${0}
${boot_fail}                ${0}
${ffdc_dir_path_style}      ${EMPTY}
${ffdc_check}               ${EMPTY}
${state_change_timeout}     1 min
${power_on_timeout}         14 mins
${power_off_timeout}        2 mins
${test_mode}                0
${quiet}                    0
${debug}                    0


# Plug-in variables.
${shell_rc}                 0x00000000
${fail_on_plug_in_failure}  1
${return_on_non_zero_rc}    0

${next_boot}                ${EMPTY}
# State dictionary.  Initializing to a realistic state for testing in
# test_mode.
&{default_state}            power=1
...                         bmc=HOST_BOOTED
...                         boot_progress=FW Progress, Starting OS
...                         os_ping=1
...                         os_login=1
...                         os_run_cmd=1
&{state}                    &{default_state}

# Flag variables.
${cp_setup_called}          ${0}
# test_really_running is needed by DB_Logging plug-in.
${test_really_running}      ${1}

*** Test Cases ***
Randomized Boot Testing
    [Documentation]  Performs random, repeated boots.
    [Tags]  Randomized_boot_testing

    # Call the Main keyword to prevent any dots from appearing in the console
    # due to top level keywords.
    Main

*** Keywords ***
###############################################################################
Main
    [Teardown]  Program Teardown

    Setup

    :For  ${BOOT_COUNT}  IN RANGE  ${max_num_tests}
    \  Test Loop Body  ${BOOT_COUNT}

    Rprint Timen  Completed all requested boot tests.

###############################################################################


###############################################################################
Setup
    [Documentation]  Do general program setup tasks.

    Rprintn

    Validate Parms

    Rqprint Pgm Header

    Create Boot Results Table

    # Preserve the values of boot_pass/boot_fail that were passed in.
    Set Global Variable  ${initial_boot_pass}  ${boot_pass}
    Set Global Variable  ${initial_boot_fail}  ${boot_fail}

    # Call "setup" plug-ins, if any.
    Plug In Setup
    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=setup
    Should Be Equal  '${rc}'  '${0}'

    # Keyword "FFDC" will fail if TEST_MESSAGE is not set.
    Set Global Variable  ${TEST_MESSAGE}  ${EMPTY}

    # Setting cp_setup_called lets our Teardown know that it needs to call
    # the cleanup plug-in call point.
    Set Global Variable  ${cp_setup_called}  ${1}

    Rqprint Timen  Getting system state.
    # The state dictionary must be primed before calling Test Loop Body.
    ${temp_state}=  Run Keyword If  '${test_mode}' == '0'  Get State
    ...  ELSE  Create Dictionary  &{default_state}
    Set Global Variable  &{state}  &{temp_state}
    Rpvars  state

###############################################################################


###############################################################################
Validate Parms
    [Documentation]  Validate all program parameters.

    rprintn

    Rvalid Value  AVAIL_BOOTS
    Rvalid Value  openbmc_host
    Rvalid Value  openbmc_username
    Rvalid Value  openbmc_password
    # os_host is optional so no validation is being done.
    Run Keyword If  '${OS_HOST}' != '${EMPTY}'  Run Keywords
    ...  Rvalid Value  os_username  AND
    ...  Rvalid Value  os_password
    Rvalid Value  pdu_host
    Rvalid Value  pdu_username
    Rvalid Value  pdu_password
    Rvalid Integer  pdu_slot_no
    Rvalid Value  openbmc_serial_host
    Rvalid Integer  openbmc_serial_port
    Rvalid Integer  max_num_tests
    Rvalid Value  openbmc_model
    Rvalid Integer  boot_pass
    Rvalid Integer  boot_fail

    ${boot_pass_temp}=  Convert To Integer  ${boot_pass}
    Set Global Variable  ${boot_pass}  ${boot_pass_temp}
    ${boot_fail_temp}=  Convert To Integer  ${boot_fail}
    Set Global Variable  ${boot_fail}  ${boot_fail_temp}

    ${temp_arr}=  Rvalidate Plug Ins  ${plug_in_dir_paths}
    Set Global Variable  @{plug_in_packages_list}  @{temp_arr}

    Run Keyword If  '${openbmc_nickname}' == '${EMPTY}'
    ...  Set Global Variable  ${openbmc_nickname}  ${openbmc_host}

    Set FFDC Dir Path Style

###############################################################################


###############################################################################
Set FFDC Dir Path Style

    Run Keyword If  '${ffdc_dir_path_style}' != '${EMPTY}'  Return from Keyword

    ${temp}=  Run Keyword and Continue On Failure  Get Environment Variable
    ...  FFDC_DIR_PATH_STYLE  ${0}

    Set Global Variable  ${ffdc_dir_path_style}  ${temp}

###############################################################################


###############################################################################
Program Teardown
    [Documentation]  Clean up after this program.

    Run Keyword If  '${cp_setup_called}' == '1'  Run Keywords
    ...  Plug In Setup  AND
    ...  Rprocess Plug In Packages  call_point=cleanup
    ...  stop_on_plug_in_failure=1

    Rqprint Pgm Footer

###############################################################################


###############################################################################
Test Loop Body
    [Documentation]  The main loop body for the loop in "main".
    [Arguments]  ${BOOT_COUNT}

    Rqprintn
    Rqprint Timen  Starting boot ${BOOT_COUNT+1} of ${max_num_tests}.

    ${loc_next_boot}=  Select Boot  ${state['power']}
    Set Global Variable  ${next_boot}  ${loc_next_boot}

    # Clear this file.  Plug-ins may now write to it.
    Remove File  ${FFDC_LIST_FILE_PATH}

    ${status}  ${msg}=  Run Keyword And Ignore Error  Run Boot  ${next_boot}
    Run Keyword If  '${status}' == 'FAIL'  rprint  ${msg}

    rprintn
    Run Keyword If  '${BOOT_STATUS}' == 'PASS'  Run Keywords
    ...    Set Global Variable  ${boot_success}  ${1}  AND
    ...    Rqprint Timen  BOOT_SUCCESS: "${next_boot}" succeeded.
    ...  ELSE  Run Keywords
    ...    Set Global Variable  ${boot_success}  ${0}  AND
    ...      Rqprint Timen  BOOT_FAILED: ${next_boot} failed.

    Update Boot Results Table  ${next_boot}  ${BOOT_STATUS}

    # NOTE: A post_test_case call point failure is NOT counted as a boot
    # failure.
    Plug In Setup
    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=post_test_case  stop_on_plug_in_failure=1

    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=ffdc_check  shell_rc=${0x00000200}
    ...  stop_on_plug_in_failure=1  stop_on_non_zero_rc=1

    Run Keyword If
    ...  '${BOOT_STATUS}' != 'PASS' or '${FFDC_CHECK}' == 'All' or '${shell_rc}' == '${0x00000200}'
    ...  Run Keyword and Continue On Failure  My FFDC

    # Run plug-ins to see if we ought to stop execution.
    Plug In Setup
    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=stop_check
    Run Keyword If  '${rc}' != '${0}'  Run Keywords
    ...  Rprint Error Report  Stopping as requested by user.
    ...  Fail

    Print Boot Results Table
    Rqprint Timen  Finished boot ${BOOT_COUNT+1} of ${max_num_tests}.

    Rqprint Timen  Getting system state.
    # The state must be refreshed before calling Test Loop Body again.
    ${temp_state}=  Run Keyword If  '${test_mode}' == '0'  Get State
    ...  quiet=${1}
    ...  ELSE  Create Dictionary  &{default_state}
    Set Global Variable  &{state}  &{temp_state}
    rpvars  state

###############################################################################


###############################################################################
Select Boot
    [Documentation]  Select a boot test to be run based on our current state.
    ...  Return the chosen boot type.
    [Arguments]  ${power}

    # power      The power state of the machine, either zero or one.

    ${boot}=  Run Keyword If  ${power} == ${0}  Select Power On
    ...  ELSE  Run Keyword If  ${power} == ${1}  Select Power Off
    ...  ELSE  Run Keywords  Log to Console
    ...  **ERROR** BMC not in state to power on or off: "${power}"  AND
    ...  Fatal Error

    [return]  ${boot}

###############################################################################


###############################################################################
Select Power On
    [Documentation]  Randomly chooses a boot from the list of Power On boots.

    @{power_on_choices}=  Intersect Lists  ${VALID_POWER_ON}  ${AVAIL_BOOTS}

    ${length}=  Get Length  ${power_on_choices}

    # Currently selects the first boot in the list of options, rather than
    # selecting randomly.
    ${chosen}=  Set Variable  @{power_on_choices}[0]

    [return]  ${chosen}

###############################################################################


###############################################################################
Select Power Off
    [Documentation]  Randomly chooses an boot from the list of Power Off boots.

    @{power_off_choices}=  Intersect Lists  ${VALID_POWER_OFF}  ${AVAIL_BOOTS}

    ${length}=  Get Length  ${power_off_choices}

    # Currently selects the first boot in the list of options, rather than
    # selecting randomly.
    ${chosen}=  Set Variable  @{power_off_choices}[0]

    [return]  ${chosen}

###############################################################################


###############################################################################
Run Boot
    [Documentation]  Run the selected boot and mark the status when complete.
    [Arguments]  ${boot_keyword}
    [Teardown]  Set Global Variable  ${BOOT_STATUS}  ${KEYWORD STATUS}

    # boot_keyword     The name of the boot to run, which corresponds to the
    #                  keyword to run. (i.e "BMC Power On")

    Print Test Start Message  ${boot_keyword}

    Plug In Setup
    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=pre_boot
    Should Be Equal  '${rc}'  '${0}'

    @{cmd_buf}=  Create List  ${boot_keyword}
    rqpissuing_keyword  ${cmd_buf}  ${test_mode}
    Run Keyword If  '${test_mode}' == '0'  Run Keyword  @{cmd_buf}

    Plug In Setup
    ${rc}  ${shell_rc}  ${failed_plug_in_name}=  Rprocess Plug In Packages
    ...  call_point=post_boot
    Should Be Equal  '${rc}'  '${0}'

###############################################################################


###############################################################################
Print Test Start Message
    [Documentation]  Print a message indicating what boot test is about to run.
    [Arguments]  ${boot_keyword}

    ${doing_msg}=  Sprint Timen  Doing "${boot_keyword}".
    rqprint  ${doing_msg}

    Append to List  ${LAST_TEN}  ${doing_msg}
    ${length}=  Get Length  ${LAST_TEN}

    Run Keyword If  '${length}' > '${10}'  Remove From List  ${LAST_TEN}  0

###############################################################################


###############################################################################
Print Defect Report
    [Documentation]  Print a defect report.

    Rqprintn
    # indent=0, width=90, linefeed=1, char="="
    Rqprint Dashes  ${0}  ${90}  ${1}  =
    Rqprintn  Copy this data to the defect:
    Rqprintn

    Rqpvars  @{parm_list}
    Print Last Ten Boots
    Rqprintn
    Rqpvars  state

    # At some point I'd like to have the 'Call FFDC Methods' return a list
    # of files it has collected.  In that case, the following "ls" command
    # would no longer be needed.  For now, however, ls shows the files
    # named in FFDC_LIST_FILE_PATH so I will refrain from printing those
    # out (so we don't see duplicates in the list).

    ${rc}  ${output}=  Run and return RC and Output  ls ${LOG_PREFIX}*

    Run Keyword If  '${rc}' != '${0}' and '${rc}' != 'None'  rqpvars  rc
    ${status}  ${ffdc_list}=  Run Keyword and Ignore Error
    ...  OperatingSystem.Get File  ${FFDC_LIST_FILE_PATH}

    Rqprintn
    Rqprintn  FFDC data files:
    Run Keyword If  '${status_file_path}' != '${EMPTY}'
    ...  Rqprintn  ${status_file_path}
    Rqprintn  ${output}
    # Run Keyword If  '${status}' == 'PASS'  Rqprintn  ${ffdc_list}
    Rqprintn

    Rqprint Dashes  ${0}  ${90}  ${1}  =

###############################################################################


###############################################################################
Print Last Ten Boots
    [Documentation]  Logs the last ten boots that were performed with their
    ...  starting time stamp.

    # indent 0, 90 chars wide, linefeed, char is "="
    Rqprint Dashes  ${0}  ${90}
    Rqprintn  Last 10 boots:
    Rqprintn
    :FOR  ${boot_entry}  IN  @{LAST_TEN}
    \  rqprint  ${boot_entry}
    Rqprint Dashes  ${0}  ${90}

###############################################################################


