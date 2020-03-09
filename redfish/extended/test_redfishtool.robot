*** Settings ***
Documentation    Verify Redfish tool functionality.

# This module tests the functionality of openbmctool.py.
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


Library                 String
Library                 OperatingSystem

Suite Setup             Suite Setup Execution

*** Variables ***


${min_number_sensors}   ${15}

*** Test Cases ***

Verify Openbmctool FRU Commands
    [Documentation]  Verify FRU commands work.
    [Tags]  Verify_Openbmctool_FRU_Commands

    Verify FRU Status
    Verify FRU Print
    Verify FRU List

Verify Sensors List
    [Documentation]  Verify that sensors list works.

    # Note: The output from 'sensors list' is the same as 'sensors print'.
    #${sensor_status}=  Get Sensors List
    ${sensor_status}=    Run 
    ...   redfishtool -r $OPENBMC_HOST -u $OPENBMC_USERNAME -p $OPENBMC_PASSWORD -S Always raw GET /redfish/v1/Chassis/chassis/Sensors
    #...   redfishtool -r wsbmc007.aus.stglabs.ibm.com -u root -p 0penBmc123 -S Always raw GET /redfish/v1/Chassis/chassis/Sensors 
    ${num_sensors}=  Get Length  ${sensor_status}
    #Rprint Vars  num_sensors
    Check Greater Than Minimum  ${num_sensors}  ${min_number_sensors}  sensors

*** Keywords ***


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

Verify FRU Status
    [Documentation]  Verify that the 'fru status' command works.
    
    Log To Console   "Dummy Keyword - To Do"
    #${fru_status}=  Get Fru Status
    #${num_frus}=  Get Length  ${fru_status}
    #Rprint Vars  num_frus
    #Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU Print
    [Documentation]  Verify that the 'fru print' command works.

    Log To Console  "Dummy Keyword - To Do"
    #${rc}  ${num_frus}=  Openbmctool Execute Command
    #...  fru print | wc -l
    #Rprint Vars  num_frus
    #Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Verify FRU List
    [Documentation]  Verify that the 'fru list' command works.

    Log To Console  "Dummy Keyword - To Do"
    # Note: The output from 'fru list' is the same as 'fru print'.
    #${rc}  ${num_frus}=  Openbmctool Execute Command
    #...  fru list | wc -l
    #Rprint Vars  num_frus
    #Check Greater Than Minimum  ${num_frus}  ${min_number_items}  frus


Suite Setup Execution
    [Documentation]  Verify connectivity to run openbmctool commands.
    ${output}=  Run  which redfishtool 
    Should Not Be Empty  ${output}
    #Printn
