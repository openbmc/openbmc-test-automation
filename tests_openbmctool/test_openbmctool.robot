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
# LOGGING_HOST          The hostname or IP address of the remote
#                       logging server.  The default value is
#                       '10.10.10.10'.
# LOGGING_PORT          The port number for remote logging on the
#                       LOGGING_HOST.  The default value is '514'.


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
Library                 ../lib/gen_robot_valid.py
Resource                ../syslib/utils_os.robot
Resource                ../lib/resource.txt


Suite Setup             Suite Setup Execution
Test Setup              Rprintn

*** Variables ***

${min_number_items}     ${30}
${min_number_sensors}   ${15}
${LOGGING_HOST}         10.10.10.10
${LOGGING_PORT}         514


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

    ${health_results}=  Get Health Check  verify=${1}
    Rprint Vars  health_results


Verify Openbmctool Service Data Commands
    [Documentation]  Verify collect service data command works.
    [Tags]  Verify_Openbmctool_Service_Data_Commands

    ${service_paths}=  Collect Service Data  verify=${1}
    Rprint Vars  service_paths


Verify Openbmctool Remote Logging Operations
    [Documentation]  Verify logging commands work.
    [Tags]  Verify_Openbmctool_Remote_Logging_Operations

    #Verify Logging View
    ${remote_logging_view}=  Get Remote Logging View  verify=${True}

    # Save previous remote logging settings, if any.
    ${remote_config}=  Get Remote Logging Settings

    # Enable remote logging and verify.
    Verify Logging Parameters  ${LOGGING_HOST}  ${LOGGING_PORT}

    # Disable remote logging and verify.  Disable will clear any
    # previous settings.
    Verify Logging Disable  ${LOGGING_HOST}

    # Set original parameters back, if any.
    Run Keyword If  ${remote_config}
    ...  Verify Logging Parameters
    ...  ${remote_config['Address']}  ${remote_config['Port']}


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


Verify Logging Parameters
    [Documentation]  Verify remote_logging_config.
    [Arguments]  ${log_host}  ${log_port}

    # Description of argument(s):
    # log_host  The host name or IP address of remote logging server.
    # log_port  The port number for remote logging on log_host.

    ${rc}  ${result}=  Openbmctool Execute Command JSON
    ...  logging remote_logging_config -a ${log_host} -p ${log_port}
    ...  print_output=${False}  ignore_err=${False}

    ${remote_logging_view}=  Get Remote Logging View  verify=${True}

    Rvalid Value  remote_logging_view['Address']  valid_values=['${log_host}']
    Rvalid Value  remote_logging_view['Port']  valid_values=[int(${log_port})]


Verify Logging Disable
    [Documentation]  Verify remote_logging disable
    [Arguments]  ${log_host}

    # Description of argument(s):
    # log_host  The host name or IP address of remote logging server.

    ${rc}  ${result}=  Openbmctool Execute Command JSON
    ...  logging remote_logging disable

    ${remote_logging_view}=  Get Remote Logging View  verify=${True}
    Rvalid Value  remote_logging_view['Address']  valid_values=['']


get Remote Logging Settings
    [Documentation]  Return the remote config settings as a dictionary
    ...              if active.  Otherwise, return ${False}.

    ${remote_config}=  Read Properties  ${BMC_LOGGING_URI}config/remote
    Return From Keyword If
    ...  '${remote_config["Address"]}' == '' or '${remote_config["Port"]}' == '0'
    ...  ${False}

    [Return]  ${remote_config}


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
