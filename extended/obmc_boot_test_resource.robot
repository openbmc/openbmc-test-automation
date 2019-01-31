*** Settings ***
Documentation  This file is resourced by obmc_boot_test.py to set initial
...            variable values, etc.

Resource  ../lib/openbmc_ffdc.robot
Library   ../lib/state.py

Library   ../lib/obmc_boot_test.py
Library   Collections

*** Variables ***
# Initialize program parameters variables.
# Create parm_list containing all of our program parameters.  This is used by
# 'Rqprint Pgm Header'
@{parm_list}                openbmc_nickname  openbmc_host  openbmc_username
...  openbmc_password  rest_username  rest_password  ipmi_username
...  ipmi_password  os_host  os_username  os_password  pdu_host  pdu_username
...  pdu_password  pdu_slot_no  openbmc_serial_host  openbmc_serial_port
...  stack_mode  boot_stack  boot_list  max_num_tests  plug_in_dir_paths
...  status_file_path  openbmc_model  boot_pass  boot_fail  ffdc_dir_path_style
...  ffdc_check  ffdc_only  ffdc_function_list  state_change_timeout
...  power_on_timeout  power_off_timeout  boot_fail_threshold  delete_errlogs
...  call_post_stack_plug  test_mode  quiet  debug

# Initialize each program parameter.
${openbmc_host}             ${EMPTY}
${openbmc_nickname}         ${openbmc_host}
${openbmc_username}         root
${openbmc_password}         0penBmc
${rest_username}            ${openbmc_username}
${rest_password}            ${openbmc_password}
${ipmi_username}            ${openbmc_username}
${ipmi_password}            ${openbmc_password}
${os_host}                  ${EMPTY}
${os_username}              root
${os_password}              P@ssw0rd
${pdu_host}                 ${EMPTY}
${pdu_username}             admin
${pdu_password}             admin
${pdu_slot_no}              ${EMPTY}
${openbmc_serial_host}      ${EMPTY}
${openbmc_serial_port}      ${EMPTY}
${stack_mode}               normal
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
${ffdc_only}                ${0}
${ffdc_function_list}       ${EMPTY}
${state_change_timeout}     3 mins
${power_on_timeout}         14 mins
${power_off_timeout}        2 mins
# If the number of boot failures, exceeds boot_fail_threshold, this program
# returns non-zero.
${boot_fail_threshold}      ${0}
${delete_errlogs}           ${0}
# This variable indicates whether post_stack plug-in processing should be done.
${call_post_stack_plug}     ${1}
${test_mode}                0
${quiet}                    0
${debug}                    0

# Flag variables.
# test_really_running is needed by DB_Logging plug-in.
${test_really_running}      ${1}


*** Keywords ***
OBMC Boot Test
    [Documentation]  Run the OBMC boot test.
    [Teardown]  OBMC Boot Test Teardown
    [Arguments]  ${pos_arg1}=${EMPTY}  &{arguments}

    # Note: If I knew how to specify a keyword teardown in python, I would
    # rename the "OBMC Boot Test Py" python function to "OBMC Boot Test" and
    # do away with this robot keyword.

    Run Keyword If  '${pos_arg1}' != '${EMPTY}'
    ...  Set To Dictionary  ${arguments}  loc_boot_stack=${pos_arg1}

    OBMC Boot Test Py  &{arguments}
