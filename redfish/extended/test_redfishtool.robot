*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
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
# local_users queryenabled
#
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


Library                 String
Library                 OperatingSystem

Suite Setup             Suite Setup Execution

*** Variables ***

${cmd_prefix}           redfishtool -r $OPENBMC_HOST -u $OPENBMC_USERNAME -p $OPENBMC_PASSWORD -S Always raw
${min_number_sensors}   ${15}

*** Test Cases ***

Verify Redfishtool Sensors Commands
    [Documentation]  Verify sensors commands work.
    [Tags]  Verify_Redfishtool_Sensors_Commands

    Verify Sensors Print
    Verify Sensors List
    # Verify Sensors List With Single Sensor
    #     # Known issue - openbmctool.py sensors list with single sensor is
    #         # not working yet.  See https://github.com/openbmc/openbmc-tools/issues/33.

*** Keywords ***


Verify Sensors List
    [Documentation]  Verify that sensors list works.
    ${sensor_status}=    Run  ${cmd_prefix} GET /redfish/v1/Chassis/chassis/Sensors 
    ${num_sensors}=  Get Length  ${sensor_status}
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors


Verify Sensors Print
    [Documentation]  Verify that sensors print works. It is understood be same as sensors list works
    ${sensor_status}=    Run  ${cmd_prefix} GET /redfish/v1/Chassis/chassis/Sensors 
    ${num_sensors}=  Get Length  ${sensor_status}
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors


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
    ${output}=  Run  which redfishtool
    Should Not Be Empty  ${output}
