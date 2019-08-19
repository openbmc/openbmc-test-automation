*** Settings ***
Documentation       Getting the systems thermal records for temperature.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
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
    Rprint Vars  num_records  records

    ${invalid_records}=  Filter Struct  ${records}
    ...  [('Health', '^OK$'), ('State', '^Enabled$'), ('${reading_type}', '')]  regex=1  invert=1
    ${num_invalid_records}=  Get Length  ${invalid_records}

    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records
    Valid Value  num_invalid_records  valid_values=[0]

    ${invalid_records}=  Evaluate
    ...  [x for x in ${records} if not x['LowerThresholdNonCritical'] <= x['ReadingCelsius'] <= x['UpperThresholdNonCritical']]

    ${num_invalid_records}=  Get Length  ${invalid_records}
    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records
    Valid Value   num_invalid_records  valid_values=[0]

Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Redfish.Login

Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
