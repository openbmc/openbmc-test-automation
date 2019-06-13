*** Settings ***
Documentation       Getting the systems thermal records for temperature.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Teardown       Test Teardown Execution


*** Test Cases ***

Get Ambient Temperature Records
    [Documentation]  Get the ambient temperature records.
    [Tags]  Get_Ambient_Temperature_Records
    [Template]  Get Thermal Records and Verify

    #Record Type    Reading Type
    Temperatures    ReadingCelsius


*** Keywords ***

Get Thermal Records and Verify
    [Documentation]  Get the thermal records for temperatures.
    [Arguments]  ${record_type}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The thermal record type for Temperatures
    # reading_type   The thermal temperature readings
    #
    # A valid record will have "State" key "Enabled" and "Health" key "OK"

    ${records}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Chassis/chassis/Thermal  ${record_type}
    Rprint Vars  records

    ${num_records}=  Get Length  ${records}

    ${valid_records}=  Filter Struct  ${records}
    ...  [('Health', '^OK$'), ('State', '^Enabled$'), ('${reading_type}', '')]  regex=1

    ${num_valid_records}=  Get Length  ${valid_records}

    Rprint Vars  num_records  records  valid_records
    ...  num_valid_records  fmt=terse

    Should Be Equal As Integers  ${num_records}  ${num_valid_records}

Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    ${resp}=  Redfish.Get  ${REDFISH_BASE_URI}Chassis/chassis/Thermal
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
