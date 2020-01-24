*** Settings ***
Documentation       Getting the systems power sensor readings for voltages.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Test Cases ***

Get Power Sensor Voltage Records
    [Documentation]  Get the power voltage records.
    [Tags]  Get_Power_Sensor_Voltage_Records
    [Template]  Get Voltage Records and Verify

    # record_type   reading_type
    Voltages        ReadingVolts


*** Keywords ***

Get Voltage Records and Verify
    [Documentation]  Get the power records for voltages.
    [Arguments]  ${record_type}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The sensor record type (e.g. "Voltages")
    # reading_type   The power voltage readings (e.g. "ReadingVolts")

    # A valid record will have "State" key "Enabled" and "Health" key "OK"
    ${records}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_POWER_URI}  ${record_type}

    ${num_records}=  Get Length  ${records}
    Rprint Vars  num_records  records  fmt=terse

    ${invalid_records}=  Filter Struct  ${records}
    ...  [('Health', '^OK$'), ('State', '^Enabled$'), ('${reading_type}', '')]  regex=1  invert=1
    ${num_invalid_records}=  Get Length  ${invalid_records}

    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records  fmt=terse
    Valid Value  num_invalid_records  valid_values=[0]

    ${cmd}  Catenate  [x for x in ${records}
    ...  if not x['LowerThresholdNonCritical'] <= x['ReadingVolts'] <= x['UpperThresholdNonCritical']]
    ${invalid_records}=  Evaluate  ${cmd}

    ${num_invalid_records}=  Get Length  ${invalid_records}
    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records  fmt=terse
    Valid Value  num_invalid_records  valid_values=[0]


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Redfish Power On  stack_mode=skip
    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
