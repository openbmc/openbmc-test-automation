*** Settings ***
Documentation       Get the system power supply voltage readings.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Test Cases ***

Verify Power Supplies Input Watts
    [Documentation]  Verify there are no invalid power supply input watt records.
    [Tags]  Verify_Power_Supplies_Input_Watts
    [Template]  Verify Watts Record

    # record_type   redfish_uri                       reading_type
    PowerSupplies   ${REDFISH_CHASSIS_POWER_URI}      PowerInputWatts


Verify Power Supplies Input Output Voltages
    [Documentation]  Verify there are no invalid power supply voltage records.
    [Tags]  Verify_Power_Supplies_Input_Output_Voltages
    [Template]  Verify Voltage Records

    # record_type   redfish_uri                        reading_type
    Voltages        ${REDFISH_CHASSIS_POWER_URI}       ReadingVolts


*** Keywords ***

Verify Watts Record
    [Documentation]  Verify the power watt records.
    [Arguments]  ${record_type}  ${redfish_uri}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The sensor record type (e.g. "PowerSupplies")
    # redfish_uri    The power supply URI (e.g. /redfish/v1/Chassis/chassis/Power)
    # reading_type   The power watt readings (e.g. "PowerInputWatts")

    Verify Valid Records  ${record_type}  ${redfish_uri}  ${reading_type}


Verify Voltage Records
    [Documentation]  Verify the power voltage records.
    [Arguments]  ${record_type}  ${redfish_uri}  ${reading_type}

    # Description of Arguments(s):
    # record_type    The sensor record type (e.g. "Voltages")
    # redfish_uri    The power supply URI (e.g. /redfish/v1/Chassis/chassis/Power)
    # reading_type   The power voltage readings (e.g. "ReadingVolts")

    Verify Valid Records  ${record_type}  ${redfish_uri}  ${reading_type}

    ${records}=  Redfish.Get Attribute  ${redfish_uri}  ${record_type}

    ${invalid_records}=  Evaluate
    ...  [x for x in ${records} if not x['LowerThresholdNonCritical'] <= x['${reading_type}'] <= x['UpperThresholdNonCritical']]

    Valid Length  invalid_records  max_length=0

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
