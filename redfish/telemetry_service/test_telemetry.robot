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

    Redfish Power On  stack_mode=skip
    ${id}  ${unit}  ${metric_datatype}  ${metric_type}  ${metric_properties}=
    ...  Retreieve Telemetery Data Definitions
    ...  /redfish/v1/TelemetryService/MetricDefinitions/total_power

    ${reading_type}=  Set Variable  Power

    ${status}=  Is Telementry Data Aligned With Definitions
    ...  ${id}  ${unit}  ${reading_type}  ${metric_datatype}  ${metric_type}  ${metric_properties}

    Should Be True  ${status}


*** Keywords ***

Retreieve Telemetery Data Definitions
    [Documentation]  Retreieve telemetery data definitions.
    [Arguments]  ${uri_def}

    # Description of argument(s):
    # uri_def                data definition uri of the metric.
   
    # Redfish response Example for /redfish/v1/TelemetryService/MetricDefinitions/total_power :
    # {
    #  "@odata.id": "/redfish/v1/TelemetryService/MetricDefinitions/total_power",
    #  "@odata.type": "#MetricDefinition.v1_0_3.MetricDefinition",
    #  "Id": "total_power",
    #  "IsLinear": true,
    #  "MetricProperties": [
    #    "/redfish/v1/Chassis/chassis/Sensors/total_power/Reading"
    #  ],
    #  "MetricType": "Numeric", 
    #  "Name": "total_power", 
    #  "Units": "W" 
    #  }
    # }
    ${resp}=  Redfish.Get Properties  ${uri_def}
    [return]  ${resp["Id"]}  ${resp["Units"]}  ${resp["MetricDataType"]}
    ...  ${resp["MetricType"]}  ${resp["MetricProperties"]}


Is Telementry Data Aligned With Definitions
    [Documentation]  Validate telementry data aligned with definitions.
    [Arguments]  ${id_def}  ${unit_def}  ${reading_typedef}  ${metric_datatypedef}
    ...  ${metric_typedef}  ${metric_properties}

    # Description of argument(s):
    # id_def                 id of the metric in data definition.
    # unit_def               unit of the metric in data definition.
    # reading_typedef        reading type of the metric in data definition.
    # metric_datatypedef     data type of the metric in data definition.
    # metric_typedef         type of the metric in data definition.
    # metric_properties      metric properties of the metric in data definition.

    # Example for metric_properties :
    # /redfish/v1/Chassis/chassis/Sensors/total_power/Reading
    ${url}=  ExtractURI  ${metric_properties}

    # Redfish response Example with url /redfish/v1/Chassis/chassis/Sensors/total_power :
    # {
    #  "@odata.id": "/redfish/v1/Chassis/chassis/Sensors/total_power",
    #  "@odata.type": "#Sensor.v1_0_0.Sensor",
    #  "Id": "total_power",
    #  "Name": "total power",
    #  "Reading": 758.0,
    #  "ReadingRangeMax": null,
    #  "ReadingRangeMin": null,
    #  "ReadingType": "Power",
    #  "ReadingUnits": "W",
    #  "Status": {
    #      "Health": "OK",
    #      "State": "Enabled"
    #  }
    # }
    ${resp}=  Redfish.Get Properties  ${url}

    # Confirm if metric id conforms to definition.
    Should Be Equal As Strings  ${id_def}  ${resp["Id"]}

    # Confirm if metric unit conforms to  definition.
    Should Be Equal As Strings  ${unit_def}  ${resp["ReadingUnits"]}

    # Confirm if reading type conforms to definition.
    Should Be Equal As Strings  ${reading_typedef}  ${resp["ReadingType"]}

    # Confirm if reading type conforms to definition.
    # Verify Metric Reading  ${value}  ${minVal}  ${maxVal}  ${metric_datatypedef}  ${metricTypeDef}
    Verify Metric Reading  ${resp["Reading"]}  ${resp["ReadingRangeMin"]}  ${resp["ReadingRangeMax"]}
    ...  ${metric_datatypedef}  ${metric_typedef}

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


Verify Metric Reading
    [Documentation]  Verify reading of the metric.
    [Arguments]  ${value}  ${min_val}  ${max_val}  ${metric_datatypedef}  ${metric_typedef}

    # Description of argument(s):
    # value                reading of the metric.
    # min_val              minimum reading  limit of the metric.
    # max_val              maximum reading  limit of the metric.
    # metric_datatypedef   data type of the metric in data definition.
    # metric_typedef       type of the metric in data definition.

    IF  '${metric_datatypedef}'=='Decimal'
       ${result}=  Convert To Integer  ${value}
       ${is int}=  Evaluate  isinstance($result, int)
       Should Be True  ${is int}

       IF  '${metric_typedef}'=='Gauge'
          Should Be True  ${max_val} > ${result} > ${min_val}
       END
    END


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
