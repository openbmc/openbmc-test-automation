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

    # record_type   reading_type
    Temperatures    ReadingCelsius


*** Keywords ***

Get Thermal Records and Verify
    [Documentation]  Get the thermal records for temperatures.
    [Arguments]  ${record_type}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The thermal record type (e.g. "Temperatures")
    # reading_type   The thermal temperature readings (e.g. "ReadingCelsius")

    # A valid record will have "State" key "Enabled" and "Health" key "OK"

    ${records}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_THERMAL_URI}  ${record_type}

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

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
