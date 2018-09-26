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
# health check
# service data
#
# openbmctool.py should be in $PATH.
#
# Test Parameters:
# OPENBMC_HOST        The BMC host name or IP address.
# OPENBMC_USERNAME    The user-id to login to the BMC.
# OPENBMC_PASSWORD    Password for OPENBMC_USERNAME.

# --TODO---
# chassis tests
# sel tests
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
Resource          ../lib/resource.txt


Suite Setup  Suite Setup Execution


*** Variables ***

${min_number_items}  ${30}
${min_number_sensors}  ${15}


*** Test Cases ***

Verify Openbmctool FRU Operations
    [Documentation]  Verify fru commands work.
    [Tags]  Verify_Openbmctool_FRU_Operations

    Verify FRU Status
    Verify FRU Print
    Verify FRU List
    #Verify FRU List With Single FRU
    # Known issue - openbmctool.py fru list with single fru is not working yet.
    # See https://github.com/openbmc/openbmc-tools/issues/32.


Verify Openbmctool Sensors Operations
    [Documentation]  Verify sensors commands work.
    [Tags]  Verify_Openbmctool_Sensors_Operations

    Verify Sensors Print
    Verify Sensors List
    #Verify Sensors List With Single Sensor
    # Known issue - openbmctool.py sensors list with single sensor is
    # not working yet.  See https://github.com/openbmc/openbmc-tools/issues/33.


Verify Openbmctool Health Check Operations
    [Documentation]  Verify health check command works.
    [Tags]  Verify_Openbmctool_Health_Check_Operations

    Verify Health Check


Verify Openbmctool Service Data Operations
    [Documentation]  Verify collect service data command works.
    [Tags]  Verify_Openbmctool_Service Data Operations

    Verify Collect Service Data


*** Keywords ***


Verify FRU Status
    [Documentation]  Verify that the fru status command works.

    ${fru_status}=  Get Fru Status
    ${num_frus}=  Get Length  ${fru_status}
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU Print
    [Documentation]  Verify that the fru print command works.

    # If call 'Get Fru Print', num_frus =2 so use method immediately below.
    #${fru_print}=  Get Fru Print  parse_json=False
    #${num_frus}=  Get Length  ${fru_print}
    #Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru print | wc -l
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List
    [Documentation]  Verify that the fru list command works.

    # The output from 'fru list' is the same as 'fru print'.
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

    ${sensor_status}=  Get Sensors Print
    ${num_sensors}=  Get Length  ${sensor_status}
    Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors


Verify Sensors List
    [Documentation]  Verify that sensors list works.

    # The output from 'sensors list' is the same as 'sensors print'.
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


Verify Health Check
    [Documentation]  Verify health_check operation.

    ${rc}  ${health}=  Openbmctool Execute Command  health_check
    Rprint Vars  health
    # Sample output:
    #  Hardware Status: OK
    #  Performance: OK
    # Instead of OK could also say Degraded or Critical.
    Should Contain  ${health}  Hardware Status:
    ...  msg=No hardware status reported by health_check.
    Should Contain  ${health}  Performance:
    ...  msg=No performance reported by health_check.


Verify Collect Service Data
    [Documentation]  Verify collect_service_data operation.

    ${rc}  ${service_data}=  Openbmctool Execute Command  collect_service_data
    Rprint Vars  service_data
    # Sample output:
    # Inventory collected and stored in /tmp/9.3.21.44/inventory.txt
    # Sensor readings collected and stored in /tmp/9.3.21.44/sensorReadings.txt
    # System LED status collected and stored in /tmp/9.3.21.44/ledStatus.txt
    # sel short list collected and stored in /tmp/9.3.21.44/SELshortlist.txt
    # fully parsed sels collected and stored in /tmp/9.3.21.44/parsedSELs.txt
    # Attempting to get a full BMC enumeration
    # RAW BMC data collected and saved into /tmp/9.3.21.44/bmcFullRaw.txt
    # Collecting bmc dump files
    # data collection complete
    Should Contain  ${service_data}  inventory.txt
    ...  msg=No inventory.txt collected by collect_service_data.
    Should Contain  ${service_data}  sensorReadings.txt
    ...  msg=No sensorReadings.txt reported by health_check.
    Should Contain  ${service_data}  ledStatus.txt
    ...  msg=No ledStatus.txt reported by health_check.
    Should Contain  ${service_data}  SELshortlist.txt
    ...  msg=No SELshortlist.txt reported by health_check.
    Should Contain  ${service_data}  parsedSELs.txt
    ...  msg=No parsedSELs.txt reported by health_check.
    Should Contain  ${service_data}  bmcFullRaw.txt
    ...  msg=No bmcFullRaw.txt reported by health_check.
    Should Contain  ${service_data}  data collection complete
    ...  msg='data collection complete' not reported by health_check.


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
    #${rc}  ${openbmctool_version}=  Openbmctool Execute Command  -V  quiet=1
    #Should Be Equal As Integers  ${rc}  ${0}
    #...  msg=rc from openbmctool.py -V is non-zero.

    Rprintn
    Rprint vars  location  openbmctool_version  OPENBMC_HOST  bmc_version[1]
