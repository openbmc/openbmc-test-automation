*** Settings ***
Documentation    Verify openbmctool.py functionality.

# This module tests the functionality of the openbmctool.
# The following tests are perfomed:
#
# fru status
# fru print
# fru list
# fru list of a single fru
# sensors print
# sensors list
# sensors list of a single sensor
#
# openbmctool.py should be in your current $PATH.
#
# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OPENBMC_USERNAME    The user-id to login to the BMC.
# OPENBMC_PASSWORD    Password for OPENBMC_USERNAME.

# --TODO---
# chassis tests
# sel tests
# collect service data tests
# health check
# dump
# bmc (same as mc)
# gardclear
# firmware


Library          ../lib/gen_print.py
Library          ../lib/gen_robot_print.py
Library          ../lib/openbmctool_utils.py
Library          String
Library          OperatingSystem

Resource         ../syslib/utils_os.robot


Suite Setup  Suite Setup Execution


*** Variables ***

${min_number_items}  ${30}
${min_number_temperature_sensors}  ${7}


*** Test Cases ***

Verify Openbmctool FRU Operations
    [Documentation]  Verify fru commands work.
    [Tags]  Verify_Openbmctool_FRU_Operations

    Verify FRU Status
    Verify FRU Print
    Verify FRU List
    # Known issue - openbmctool.py fru list with single fru is not working yet.
    # See https://github.com/openbmc/openbmc-tools/issues/32.
    #Verify FRU List With Single FRU


Verify Openbmctool Sensors Operations
    [Documentation]  Verify sensors commands work.
    [Tags]  Verify_Openbmctool_Sensors_Operations

    Verify Sensors Print
    Verify Sensors List
    # Known issue - openbmctool.py sensors list with single sensor is
    # not working yet.  See https://github.com/openbmc/openbmc-tools/issues/33.
    #Verify Sensors List With Single Sensor


*** Keywords ***


Verify FRU Status
    [Documentation]  Verify that the fru status command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru status | egrep -v '^$|^Component' | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU Print
    [Documentation]  Verify that the fru print command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru print | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List
    [Documentation]  Verify that the fru list command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru list | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List With Single FRU
    [Documentation]  Verify that fru list with parameter works.

    # Get the name of one fru, in this case the first fan listed.
    ${rc}  ${fruname}=  Openbmctool Execute Command
    ...  fru status | grep fan | head -1 | cut -c1-5
    ${fruname}=  Strip String  ${fruname}
    Rprint Vars  fruname
    Should Not Be Empty  ${fruname}  msg=Could not find a fan in fru status.
    # Get a fru list specifiying just the fan.
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

    ${rc}  ${num_sensors}=  Openbmctool Execute Command
    ...  sensors print | grep temp | wc -l
    Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}
    ...  ${min_number_temperature_sensors}  sensors


Verify Sensors List
    [Documentation]  Verify that sensors list works.

    ${rc}  ${num_sensors}=  Openbmctool Execute Command
    ...  sensors list | grep temp | wc -l
    Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}
    ...  ${min_number_temperature_sensors}  sensors


Verify Sensors List With Single Sensor
    [Documentation]  Verify that sensors list with parameter works.

    ${sensor}=  Set Variable  ambient
    ${rc}  ${num_sensors}=  Openbmctool Execute Command
    ...  sensors list ${sensor} | wc -l
    Rprint Vars  sensor  num_sensors
    ${num_sensors}=  Convert to Integer  ${num_sensors}
    Should Be True  ${num_sensors} < ${10}
    ...  msg=Too many lines reported for list sensor ${sensor}


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
    [Documentation]  Verify connectivity and can run opbmctool commands.

    # Verify connectivity to the BMC host.
    ${bmc_version}=  Run Keyword And Ignore Error  Get BMC Version
    Run Keyword If  '${bmc_version[0]}' == 'FAIL'  Fail
    ...  msg=Could not connect to BMC ${OPENBMC_HOST} to get firmware version.

    # Verify can find the openbmctool.
    ${rc}  ${location}=  Run and Return RC and Output   which openbmctool.py
    Should Be Equal As Integers  ${rc}  ${0}  msg=Could not find openbmtool.py

    # Get the version number from openbmctool.
    ${openbmctool_version}=  Get Openbmctool Version

    Rprintn
    Rprint vars  location  openbmctool_version  OPENBMC_HOST  bmc_version[1]
