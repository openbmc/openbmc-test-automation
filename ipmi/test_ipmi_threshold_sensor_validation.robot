*** Settings ***

Documentation    Test suite for IPMI default threshold sensor validation.

Resource         ../lib/resource.robot
Resource         ../lib/ipmi_client.robot
Resource         ../lib/sensor_info_record.robot
Library          ../lib/sensor_info_record.py

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Force Tags      Default_Sensor_Validation

*** Variables ***

${THRESHOLD_SENSOR_LIST}
${SENSORS_SERVICE_PATH_NOT_MAPPED_IN_SENSOR_TREE}
${SENSOR_DBUS_COMMAND_MAPPING}
${IPMI_SENSOR_NAME_SENSOR_ID_MAPPING}
${IPMI_SENSOR_THRESHOLD_VALUES}
${DBUS_THRESHOLD_VALUES}
${EXPECTED_SENSOR_LIST}

*** Test Cases *** 

Check Expected Sensors Are Showing In IPMI Sensor
    [Documentation]  Check expected sensors are listed in IPMI sensor.
    [Tags]  Check_Expected_Sensors_Are_Showing_In_IPMI_Sensor

    @{expected_sensors_not_listing_in_ipmi}=  Create List

    FOR  ${sensor_id}  IN  @{EXPECTED_SENSOR_LIST}
        ${sensor_status}=  Run Keyword And Return Status  
        ...  List Should Contain Value  ${THRESHOLD_SENSOR_LIST}  ${sensor_id}
        IF  ${sensor_status} == ${False}
            Append To List  ${expected_sensors_not_listing_in_ipmi}  ${sensor_id}
        END
    END

    ${not_listed_sensor_count}=  Get Length  ${expected_sensors_not_listing_in_ipmi}
    IF  ${not_listed_sensor_count} != 0
        Log  ${expected_sensors_not_listing_in_ipmi}
        Fail  ${not_listed_sensor_count} expected sensors are not showing in IPMI sensor.
    END

Check Any Additional Sensors Are Showing In IPMI
    [Documentation]  Check additional sensors are showing in IPMI.
    [Tags]  Check_Any_Additional_Sensors_Are_Showing_In_IPMI

    ${additional_ipmi_sensors_count}=  Get Length  ${ADDITIONAL_IPMI_SENSORS}
    IF  ${additional_ipmi_sensors_count} != 0
        Log  ${ADDITIONAL_IPMI_SENSORS}
        Fail  ${additional_ipmi_sensors_count} additional sensors are showing in IPMI sensor command.
    END

Check If Reading Value Available In IPMI
    [Documentation]  Check if reading value is not 'na' for IPMI sensor command.
    [Tags]  Check_If_Reading_Value_Available_In_IPMI

    Check IPMI Threshold Sensor Reading

Compare IPMI Sensor And D-Bus Threshold Values
    [Documentation]  Check IPMI sensor threshold values match D-Bus values.
    [Tags]  Compare_IPMI_Sensor_And_DBus_Threshold_Values

    Get Sensor Threshold Values Via Dbus
    Compare IPMI Threshold Values With Dbus Threshold Values

Validate IPMI Sensor Health State
    [Documentation]  Validate sensor health state in IPMI sensor command.
    [Tags]  Validate_IPMI_Sensor_Health_State

    Get Sensor Reading Values And Sensor State via IPMI
    Compare IPMI Reading And Threshold Values And Validate Sensor State

Get List Of Sensor ID Which Are Not Mapped In Sensor Tree
    [Documentation]  Get sensor IDs not mapped in sensor tree.
    [Tags]  Get_List_Of_Sensor_ID_Which_Are_Not_Mapped_In_Sensor_Tree

    ${sensor_id_count}=  Get Length  ${SENSORS_SERVICE_PATH_NOT_MAPPED_IN_SENSOR_TREE}
    IF  ${sensor_id_count} != 0
        Log  ${SENSORS_SERVICE_PATH_NOT_MAPPED_IN_SENSOR_TREE}
        Fail  ${sensor_id_count} sensors are not having D-Bus URI.
    END

Get List Of Sensor ID Which Doesnt Have Single Threshold Values
    [Documentation]  Get sensor IDs without single threshold values.
    [Tags]  Get_List_Of_Sensor_ID_Which_Doesnt_Have_Single_Threshold_Values

    Get Sensor ID For Sensors Not Having Single Threshold
    ${sensor_id_length}=  Get Length  ${SENSOR_ID_NOT_HAVING_SINGLE_THRESHOLD}
    IF  ${sensor_id_length} != 0
        Log  ${SENSOR_ID_NOT_HAVING_SINGLE_THRESHOLD}
        Fail  ${sensor_id_length} sensors are not having single threshold.
    END

Check Default Threshold Values Alignment As Per IPMI Spec
    [Documentation]  Validate threshold values alignment per IPMI spec.
    [Tags]  Check_Default_Threshold_Values_Alignment_As_Per_IPMI_Spec

    Validate Default Threshold Values Alignment As Per IPMI Spec  ${IPMI_SENSOR_THRESHOLD_VALUES}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Initialize variables and prepare test environment.

    ${ADDITIONAL_IPMI_SENSORS}=  Create List
    Set Suite Variable  ${ADDITIONAL_IPMI_SENSORS}
    ${DBUS_SENSOR_LIST}=  Create List
    ${SENSOR_NAME_DICT}=  Create Dictionary

    # Host needs to be powered on for validating sensors.
    IPMI Power On  stack_mode=skip  quiet=${1}

    ${sensor_list}=  Create Expected Sensor List
    ${ipmi_sensor_command_response}=  Run IPMI Standard Command  sensor
    @{ipmi_sensor_response}=  Split To Lines  ${ipmi_sensor_command_response}

    FOR  ${ipmi_sensor_details}  IN  @{ipmi_sensor_response}
        ${sensor_status}=  Run Keyword And Return Status  Should Not Contain  ${ipmi_sensor_details}  discrete
        Continue For Loop If  ${sensor_status} == ${False}
        @{ipmi_sensor}=  Split String  ${ipmi_sensor_details}  |
        ${get_ipmi_sensor_name}=  Get From List  ${ipmi_sensor}  0
        ${sensor_name}=  Set Variable  ${get_ipmi_sensor_name.strip()}

        FOR  ${expected_sensor_name}  IN  @{sensor_list}
            ${expected_sensor_id}=  Convert Sensor Name As Per IPMI Spec  ${expected_sensor_name}
            ${sensor_id_status}=  Run Keyword And Return Status  
            ...  List Should Not Contain Value  ${EXPECTED_SENSOR_LIST}  ${expected_sensor_id}
            IF  ${sensor_id_status} == ${True}
                Append To List  ${EXPECTED_SENSOR_LIST}  ${expected_sensor_id}
            END
            ${host_bmc_sensor_status}=  Run Keyword And Return Status  
            ...  Should Be Equal  ${sensor_name}  ${expected_sensor_id}
            Exit For Loop If  ${host_bmc_sensor_status} == ${True}
        END

        IF  ${host_bmc_sensor_status} == ${False}
            Append To List  ${ADDITIONAL_IPMI_SENSORS}  ${sensor_name}
            Continue For Loop
        END
        Append To List  ${THRESHOLD_SENSOR_LIST}  ${sensor_name}
        Append To List  ${DBUS_SENSOR_LIST}  ${expected_sensor_name}
        Set To Dictionary  ${SENSOR_NAME_DICT}  ${expected_sensor_name}  ${sensor_name}
    END

    ${dbus_command_mapping}  ${sensors_not_mapped_in_sensor_tree}=
    ...  Create A Dictionary With Sensor ID And Dbus Command For Sensors  ${DBUS_SENSOR_LIST}

    FOR  ${sensor_name}  ${dbus_uri}  IN  &{dbus_command_mapping}
        ${sensor_id}=  Get From Dictionary  ${SENSOR_NAME_DICT}  ${sensor_name}
        Set To Dictionary  ${SENSOR_DBUS_COMMAND_MAPPING}  ${sensor_id}  ${dbus_uri}
    END

    FOR  ${sensor_name}  IN  @{sensors_not_mapped_in_sensor_tree}
        ${sensor_id}=  Get From Dictionary  ${SENSOR_NAME_DICT}  ${sensor_name}
        Append To List  ${SENSORS_SERVICE_PATH_NOT_MAPPED_IN_SENSOR_TREE}  ${sensor_id}
    END

    Get Sensor Threshold Values Via IPMI

Check IPMI Threshold Sensor Reading
    [Documentation]  Check reading values for IPMI threshold sensors.

    FOR  ${ipmi_sensor_id}  IN  @{THRESHOLD_SENSOR_LIST}
        ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
        ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor | grep -i "${sensor_id}"
        @{ipmi_sensor}=  Split String  ${ipmi_sensor_response}  |
        ${ipmi_sensor_reading}=  Set Variable  ${ipmi_sensor[1].strip()}
        ${ipmi_sensor_unit}=  Set Variable  ${ipmi_sensor[2].strip()}
        Run Keyword And Continue On Failure  Should Not Be Equal As Strings  ${ipmi_sensor_reading}  na
        ...  msg=${ipmi_sensor_id} sensor reading value is 'na' in IPMI.
        IF  '${ipmi_sensor_reading}' != 'na'
            Run Keyword And Continue On Failure  
            ...  Check Reading Value Length  ${ipmi_sensor_reading}  ${ipmi_sensor_id}  ${ipmi_sensor_unit}
        END
    END

Get Sensor Threshold Values Via IPMI
    [Documentation]  Get threshold values via IPMI.

    ${ipmi_sensor_response}=  Run IPMI Standard Command  sensor
    FOR  ${ipmi_sensor_id}  IN  @{THRESHOLD_SENSOR_LIST}
        ${ipmi_sensor_id_status}=  Run Keyword And Return Status  
        ...  List Should Not Contain Value  ${SENSORS_SERVICE_PATH_NOT_MAPPED_IN_SENSOR_TREE}  ${ipmi_sensor_id}
        Continue For Loop If  ${ipmi_sensor_id_status} == ${False}
        ${sensor_id}=  Evaluate  '${ipmi_sensor_id}'.replace('_',' ')
        ${get_ipmi_sensor_details}=  Get Lines Containing String  ${ipmi_sensor_response}  ${sensor_id}
        @{ipmi_sensor}=  Split String  ${get_ipmi_sensor_details}  |
        &{tmp_dict}=  Create Dictionary

        ${threshold_fields}=  Create List  FatalLow  CriticalLow  WarningLow  WarningHigh  CriticalHigh  FatalHigh
        FOR  ${idx}  ${field}  IN ENUMERATE  @{threshold_fields}
            ${value}=  Set Variable  ${ipmi_sensor[${idx}+4].strip()}
            IF  '${value}' != 'na'
                Set To Dictionary  ${tmp_dict}  ${field}  ${value}
            END
        END
        Set To Dictionary  ${IPMI_SENSOR_THRESHOLD_VALUES}  ${ipmi_sensor_id}  ${tmp_dict}
    END

# Remaining keywords follow similar pattern (DBus -> D-Bus, variable renames, IF/END blocks)