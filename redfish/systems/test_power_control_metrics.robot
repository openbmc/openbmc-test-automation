** Settings ***
Documentation       Get the systems power supply voltage readings.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify Power Control Consumed Watts
    [Documentation]  Verify there are no invalid power control consumed watt records.
    [Tags]  Verify_Power_Control_Consumed_Watts
    [Template]  Verify Power Metric Records

    # record_type   redfish_uri                   reading_type
    PowerControl    ${REDFISH_CHASSIS_POWER_URI}  PowerConsumedWatts


*** Keywords ***

Verify Power Metric Records
    [Documentation]  Verify the power voltage records.
    [Arguments]  ${record_type}  ${redfish_uri}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The sensor record type (e.g. "Voltages")
    # redfish_uri    The power supply URI (e.g. /redfish/v1/Chassis/chassis/Power)
    # reading_type   The power voltage readings (e.g. "ReadingVolts")

    Verify Valid Records  ${record_type}  ${redfish_uri}  ${reading_type}

    ${records}=  Redfish.Get Attribute  ${redfish_uri}  ${record_type}

    ${invalid_records}=  Evaluate
    ...  [x for x in ${records} if not x['${reading_type}'] <= x['PowerMetrics']['MaxConsumedWatts']]

    ${num_invalid_records}=  Get Length  ${invalid_records}
    Run Keyword If  ${num_invalid_records} > ${0}
    ...  Rprint Vars  num_invalid_records  invalid_records
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

