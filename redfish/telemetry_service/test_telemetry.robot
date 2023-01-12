*** Settings ***

Documentation       Test telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Teardown       Test Teardown Execution

*** Variables ***



*** Test Cases ***

Verify Total Power Telemetry Data From BMC
    [Documentation]  Verify total power telemetry data from BMC.
    [Tags]  Verify_Total_Power_Telemetry_Data_From_BMC

    ${uri}=  Set Variable
    ...  /redfish/v1/TelemetryService/MetricDefinitions/total_power

    ${id}  ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}=
    ...  Retreieve Telemetery Data Definitions  ${uri}

    ${readingType}=  Set Variable  Power

    ${validated}=  Validate Telementry Data Aligned With Definitions
    ...  ${id}  ${unit}  ${readingType}  ${metricDataType}  ${metricType}  ${metricProperties}

    Should Be True  ${validated}


*** Keywords ***

Retreieve Telemetery Data Definitions
    [Documentation]  Retreieve telemetery data definitions.
    [Arguments]  ${uriDef}

    # Description of argument(s):
    # uriDef                data definition uri of the metric.

    ${resp}=  Redfish.Get Properties  ${uriDef}
    ${metricDataType}=  Set Variable  ${resp["MetricDataType"]}
    ${metricType}=  Set Variable  ${resp["MetricType"]}
    ${metricProperties}=  Set Variable  ${resp["MetricProperties"]}
    ${unit}=  Set Variable  ${resp["Units"]}
    ${id}=  Set Variable  ${resp["Id"]}
    [return]  ${id}  ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}


Validate Telementry Data Aligned With Definitions
    [Documentation]  Validate telementry data aligned with definitions.
    [Arguments]  ${idDef}  ${unitDef}  ${readingTypeDef}  ${metricDataTypeDef}  ${metricTypeDef}
    ...  ${metricProperties}

    # Description of argument(s):
    # idDef                 id of the metric in data definition.
    # unitdef               unit of the metric in data definition.
    # readingTypeDef        reading type of the metric in data definition.
    # metricDataTypeDef     data type of the metric in data definition.
    # metricTypeDef         type of the metric in data definition.
    # metricProperties      metric properties of the metric in data definition.

    ${url}=  ExtractURI  ${metricProperties}
    ${resp}=  Redfish.Get Properties  ${url}
    ${metricID}=  Set Variable  ${resp["Id"]}
    ${readUnits}=  Set Variable  ${resp["ReadingUnits"]}
    ${value}=  Set Variable  ${resp["Reading"]}
    ${minVal}=  Set Variable  ${resp["ReadingRangeMin"]}
    ${maxVal}=  Set Variable  ${resp["ReadingRangeMax"]}
    ${readType}=  Set Variable  ${resp["ReadingType"]}

    # Confirm if metric id conforms to definition.
    Should Be Equal As Strings  ${idDef}  ${metricID}

    # Confirm if metric unit conforms to  definition.
    Should Be Equal As Strings  ${readUnits}  ${unitDef}

    # Confirm if reading type conforms to definition.
    Should Be Equal As Strings  ${readingTypeDef}  ${readType}

    # Confirm if reading type conforms to definition.
    VerifyMetricReading  ${value}  ${minVal}  ${maxVal}  ${metricDataTypeDef}  ${metricTypeDef}

    [return]  True


ExtractURI
    [Documentation]  Extract URI from metric property in data definition.
    [Arguments]  ${metricProperties}

    # Description of argument(s):
    # metricProperties     metric property in data definition.

    ${metricPropertiesStr}=  Convert To String  ${metricProperties}
    ${metricPropertiesStr}=  Remove String  ${metricPropertiesStr}  Reading
    ${metricPropertiesStr}=  Remove String  ${metricPropertiesStr}  "

    ${urlDict}=  Create Dictionary  url  ${metricPropertiesStr}
    ${urlDict}=  Convert To String  ${urlDict}

    ${json_string}=  Remove String  ${urlDict}  [  ]
    ${json_string}=  Remove String  ${json_string}  "
    ${json_string}=  Replace String  ${json_string}  '  "

    ${json_object}=  Evaluate  json.loads('''${json_string}''')  json
    [return]  ${json_object}[url]


VerifyMetricReading
    [Documentation]  Verify reading of the metric.
    [Arguments]  ${value}  ${minVal}  ${maxVal}  ${metricDataTypeDef}  ${metricTypeDef}

    # Description of argument(s):
    # value                reading of the metric.
    # minVal               minimum reading  limit of the metric.
    # maxVal               maximum reading  limit of the metric.
    # metricDataTypeDef    data type of the metric in data definition.
    # metricTypeDef        type of the metric in data definition.

    IF  '${metricDataTypeDef}'=='Decimal'
       ${result}=    Convert To Integer  ${value}
       ${is int}=      Evaluate     isinstance($result, int)
       Should Be True  ${is int}

       IF  '${metricTypeDef}'=='Gauge'
          Should Be True  ${maxVal} > ${result} > ${minVal}
       END
    END


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish Power On  stack_mode=skip
    Redfish.Login


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
