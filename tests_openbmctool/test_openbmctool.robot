*** Settings ***
Documentation    Verify openbmctool.py functionality.

# This module tests the functionality of openbmctool.py.
# The following tests are perfomed:
#
# FRU status
# FRU print
# FRU list
# FRU list of a single FRU
# sensors print
# sensors list
# sensors list of a single sensor
# health check
# service data
# remote logging
#
# It is the responsibility of the user to include openbmctool.py's
# directory PATH in $PATH.
#
# Test Parameters:
# OPENBMC_HOST          The BMC host name or IP address.
# OPENBMC_USERNAME      The username to login to the BMC.
# OPENBMC_PASSWORD      Password for OPENBMC_USERNAME.

# TODO:
# chassis tests
# sel tests
# dump
# bmc (same as mc)
# gardclear
# firmware commands


Library                 String
Library                 OperatingSystem
Library                 ../lib/gen_print.py
Library                 ../lib/gen_robot_print.py
Library                 ../lib/openbmctool_utils.py
Library                 ../lib/gen_misc.py
Resource                ../syslib/utils_os.robot
Resource                ../lib/resource.txt


Suite Setup             Suite Setup Execution


*** Variables ***

${min_number_items}     ${30}
${min_number_sensors}   ${15}
${verify}               ${True}


*** Test Cases ***

Verify Openbmctool FRU Commands
    [Documentation]  Verify FRU commands work.
    [Tags]  Verify_Openbmctool_FRU_Commands

    Verify FRU Status
    Verify FRU Print
    Verify FRU List
    # Verify FRU List With Single FRU
    # Known issue - openbmctool.py FRU list with single FRU is not working yet.
    # See https://github.com/openbmc/openbmc-tools/issues/32.


Verify Openbmctool Sensors Commands
    [Documentation]  Verify sensors commands work.
    [Tags]  Verify_Openbmctool_Sensors_Commands

    Verify Sensors Print
    Verify Sensors List
    # Verify Sensors List With Single Sensor
    # Known issue - openbmctool.py sensors list with single sensor is
    # not working yet.  See https://github.com/openbmc/openbmc-tools/issues/33.


Verify Openbmctool Health Check Commands
    [Documentation]  Verify health check command works.
    [Tags]  Verify_Openbmctool_Health_Check_Commands

    ${health_results}=  Get Health Check  ${verify}
    Rprint Vars  health_results


Verify Openbmctool Service Data Commands
    [Documentation]  Verify collect service data command works.
    [Tags]  Verify_Openbmctool_Service Data Commands

    ${service_paths}=  Collect Service Data  ${verify}
    Rprint Vars  service_paths


Verify Openbmctool Remote Logging Operations
    [Documentation]  Verify fru commands work.
    [Tags]  Verify_Openbmctool_Remote_logging_Operations

    # Settings used for this test, input parameters or defaults.
    ${test_log_host}=  Get Variable Value  ${LOGGING_HOST}  10.10.10.10
    ${test_log_port}=  Get Variable Value  ${LOGGING_PORT}  514
    Rprint Vars  test_log_host  test_log_port

    Verify Logging View

    # Save previous remote logging settings, if any.
    Save Current Remote Logging Settings
    # Binary variables addr_was_set and port_was_set are set if there
    # were any remote logging parameters set on the BMC. Their
    # values are saved to settings['Address'] and settings['Port'].

    # Enable remote logging and verify.
    Verify Logging Parameters  ${test_log_host}  ${test_log_port}

    # Disable remote logging and verify.  Disable will clear any
    # previous settings.
    Verify Logging Disable  ${test_log_host}

    # Set original parameters back, if any.
    Run Keyword If  ${addr_was_set} and ${port_was_set}
    ...  Verify Logging Parameters  ${settings['Address']}  ${settings['Port']}


*** Keywords ***


Verify FRU Status
    [Documentation]  Verify that the 'fru status' command works.

    ${fru_status}=  Get Fru Status
    ${num_frus}=  Get Length  ${fru_status}
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU Print
    [Documentation]  Verify that the 'fru print' command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru print | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List
    [Documentation]  Verify that the 'fru list' command works.

    # Note: The output from 'fru list' is the same as 'fru print'.
    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru list | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List With Single FRU
    [Documentation]  Verify that 'fru list' with parameter works.

    # Get the name of one FRU, in this case the first one listed.
    ${fru_status}=  Get Fru Status
    ${fruname}=  Set Variable  ${fru_status[0]['component']}
    Rprint Vars  fruname
    Should Not Be Empty  ${fruname}  msg=Could not find a FRU.
    # Get a fru list specifiying just the FRU.
    ${rc}  ${output}=  Openbmctool Execute Command
    ...  fru list ${fruname} | wc -l
    ${fru_detail}=  Convert to Integer  ${output}
    Rprint Vars  fru_detail
    Should Be True  ${fru_detail} <= ${min_number_items}
    ...  msg=Too many lines reported for fru status ${fruname}
    Should Be True  ${fru_detail} > ${4}
    ...  msg=Too few lines reported for fru status ${fruname}


Verify Sensors Print
    [Documentation]  Verify that sensors print works.

    ${sensor_status}=  Get Sensors Print
    ${num_sensors}=  Get Length  ${sensor_status}
    Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors


Verify Sensors List
    [Documentation]  Verify that sensors list works.

    # Note: The output from 'sensors list' is the same as 'sensors print'.
    ${sensor_status}=  Get Sensors List
    ${num_sensors}=  Get Length  ${sensor_status}
    Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors


Verify Sensors List With Single Sensor
    [Documentation]  Verify that sensors list with parameter works.

    ${sensor}=  Set Variable  ambient
    ${rc}  ${num_sensors}=  Openbmctool Execute Command
    ...  sensors list ${sensor} | wc -l
    Rprint Vars  sensor  num_sensors
    ${num_sensors}=  Convert to Integer  ${num_sensors}
    Should Be True  ${num_sensors} < ${10}
    ...  msg=Too many lines reported for list sensor ${sensor}


Verify Logging View
    [Documentation]  Verify remote_logging view.

    ${rc}  ${logging_status}=  Openbmctool Execute Command
    ...  logging remote_logging view
    Should Contain  ${logging_status}  Address
    ...  msg=Openbmctool 'remote_logging view' returned unexpected result.


Verify Logging Parameters
    [Documentation]  Verify remote_logging_config.
    [Arguments]  ${log_host}  ${log_port}

    # Description of argument(s):
    # log_host  The host name or IP address of remote logging server.
    # log_port  The port number for remote logging on log_host.

    ${rc}  ${result}=  Openbmctool Execute Command
    ...  logging remote_logging_config -a ${log_host} -p ${log_port}
    Should Contain  ${result}  OK
    ...  msg=Openbmctool 'remote_logging config' returned unexpected result.

    ${rc}  ${logging_status}=  Openbmctool Execute Command
    ...  logging remote_logging view
    Should Contain  ${logging_status}  ${log_host}
    ...  msg=Openbmctool 'remote_logging view' should contain ${log_host}.

    ${log_port_string}=  Convert To String  ${log_port}
    Should Contain  ${logging_status}  ${log_port_string}
    ...  msg=Openbmctool 'remote_logging view' should contain ${log_port}.


Verify Logging Disable
    [Documentation]  Verify remote_logging disable
    [Arguments]  ${log_host}

    # Description of argument(s):
    # log_host  The host name or IP address of remote logging server.

    ${rc}  ${result}=  Openbmctool Execute Command
    ...  logging remote_logging disable
    Should Contain  ${result}  OK
    ...  msg=Openbmctool 'remote_logging disable' returned unexpected result.

    ${rc}  ${logging_status}=  Openbmctool Execute Command
    ...  logging remote_logging view
    Should Contain  ${logging_status}  Address
    ...  msg=Openbmctool 'remote_logging view' returned unexpected result.
    Should Not Contain  ${logging_status}  ${log_host}
    ...  msg=Openbmctool 'remote_logging view' contains ${log_host}.


Save Current Remote Logging Settings
    [Documentation]  Save the current remote logging settings, if any.

    # Save the current settings to  settings['Address'] and  settings['Port'].
    # Set addr_was_set if settings['Address'] was non-blank and non-zero.
    # Set port_was_set if settings['Port'] was non-blank and non-zero.

    # Get current remote logging settings from the BMC.
    ${settings}=  Read Properties  ${BMC_LOGGING_URI}config/remote
    Rprint Vars  settings['Address']  settings['Port']

    Set Suite Variable  ${settings['Address']}
    Set Suite Variable  ${settings['Port']}

    # Determine if remote logging address was previously set.
    ${addr_was_set}=  Run Keyword If
    ...  '${settings['Address']}' != '0' and '${settings['Address']}' != ''
    ...  Set Variable  True  ELSE  Set Variable  False
    Set Suite Variable  ${addr_was_set}

    # Determine if remote logging port was previously set.
    ${port_was_set}=  Run Keyword If
    ...  '${settings['Port']}' != '0' and '${settings['Port']}' != ''
    ...  Set Variable  True  ELSE  Set Variable  False
    Set Suite Variable  ${port_was_set}


Check Greater Than Minimum
    [Documentation]  Value should be greater than minimum, otherwise fail.
    [Arguments]  ${value_to_test}  ${minimum_value}  ${label}

    # Description of argument(s):
    # value_to_test  Value to compare to the minimum.
    # minimum_value  The minimum acceptable value.
    # label          Name to print if failure.

    ${value_to_test}=  Convert to Integer  ${value_to_test}
    Should Be True  ${value_to_test} > ${minimum_value}
    ...  msg=There should be at least ${minimum_value} ${label}.


Suite Setup Execution
    [Documentation]  Verify connectivity to run openbmctool commands.

    # Verify connectivity to the BMC host.
    ${bmc_version}=  Run Keyword And Ignore Error  Get BMC Version
    Run Keyword If  '${bmc_version[0]}' == 'FAIL'  Fail
    ...  msg=Could not connect to BMC ${OPENBMC_HOST} to get firmware version.

    # Verify can find the openbmctool.
    ${openbmctool_file_path}=  which  openbmctool.py
    Rprintn
    Rprint Vars  openbmctool_file_path

    # Get the version number from openbmctool.
    ${openbmctool_version}=  Get Openbmctool Version

    Rprint Vars  openbmctool_version  OPENBMC_HOST  bmc_version[1]
