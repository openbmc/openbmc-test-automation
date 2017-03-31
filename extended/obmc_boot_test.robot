*** Settings ***
Documentation  Do random repeated boots based on the state of the BMC machine.

Library   state.py
Library   obmc_boot_test.py

Resource  openbmc_ffdc.robot

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
...  power_off_timeout  ffdc_only  test_mode  quiet  debug

# Initialize each program parameter.
${openbmc_host}             ${EMPTY}
${openbmc_nickname}         ${openbmc_host}
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
${state_change_timeout}     3 mins
${power_on_timeout}         14 mins
${power_off_timeout}        2 mins
${ffdc_only}                ${0}
${test_mode}                0
${quiet}                    0
${debug}                    0

# Flag variables.
# test_really_running is needed by DB_Logging plug-in.
${test_really_running}      ${1}

*** Test Cases ***
General Boot Testing
    [Documentation]  Performs repeated boot tests.
    [Tags]  General_boot_testing
    [Teardown]  Test Teardown

    # Call the Main keyword to prevent any dots from appearing in the console
    # due to top level keywords.
    Main

*** Keywords ***
###############################################################################
Main
    [Teardown]  Main Keyword Teardown

    # This is the "Main" keyword.  The advantages of having this keyword vs
    # just putting the code in the *** Test Cases *** table are:
    # 1) You won't get a green dot in the output every time you run a keyword.

    Main Py

###############################################################################
