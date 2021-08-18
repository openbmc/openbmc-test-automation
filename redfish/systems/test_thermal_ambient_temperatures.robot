*** Settings ***
Documentation       Getting the systems thermal records for temperature.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/logging_utils.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py
Library             ../../lib/logging_utils.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Redfish Purge Event Log
Test Teardown       Test Teardown Execution


*** Test Cases ***

Get Ambient Temperature Records
    [Documentation]  Get the ambient temperature records.
    [Tags]  Get_Ambient_Temperature_Records
    [Template]  Get Thermal Records and Verify

    # record_type   reading_type
    Temperatures    ReadingCelsius


Reboot And Check Ambient Temperature Records Are Valid
    [Documentation]  Check the ambient temperature records are valid after a reboot.
    [Tags]  Reboot_And_Check_Ambient_Temperature_Records_Are_Valid

    Redfish OBMC Reboot (run)
    Redfish.Login

    Get Thermal Records and Verify  Temperatures  ReadingCelsius


*** Keywords ***

Get Thermal Records and Verify
    [Documentation]  Get the thermal records for temperatures.
    [Arguments]  ${record_type}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The thermal record type (e.g. "Temperatures")
    # reading_type   The thermal temperature readings (e.g. "ReadingCelsius")

    ${records}=  Verify Valid Records  ${record_type}
    ...  ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/Thermal  ${reading_type}

    ${num_records}=  Get Length  ${records}
    Rprint Vars  num_records  records

    ${cmd}  Catenate  [x for x in ${records}
    ...  if not x['LowerThresholdNonCritical'] <= x['${reading_type}'] <= x['UpperThresholdNonCritical']]
    ${invalid_records}=  Evaluate  ${cmd}

    ${num_invalid_records}=  Get Length  ${invalid_records}
    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records
    Valid Value   num_invalid_records  valid_values=[0]

    Error Logs Should Not Exist


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Redfish.Login
    Redfish Purge Event Log


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
