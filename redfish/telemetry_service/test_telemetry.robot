*** Settings ***

Documentation       Test BMC telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             String
Library             Collections

Suite Setup         Redfish.Login
Suite Teardown      Redfish.Logout
Test Teardown       Test Teardown Execution

*** Variables ***



*** Test Cases ***

Verify Total Power Telemetry Data From BMC
    [Tags]

    ${uri}=  Set Variable
    ...  /redfish/v1/TelemetryService/MetricDefinitions/total_power

    ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}=
    ...  Retreieve Telemetery Data Definitions  ${uri}

    ${validated}=  Validate Telementry Data Aligned With Definitions 
    ...  ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}

    Should Be True  ${validated}

 
*** Keywords ***

Retreieve Telemetery Data Definitions
    [Documentation]  Retreieve Telemetery Data Definitions.
    [Arguments]  ${defURI}

    ${resp}=  Redfish.Get Properties  ${defURI}
    ${metricDataType}=  Set Variable  ${resp["MetricDataType"]}
    ${metricType}=  Set Variable  ${resp["MetricType"]}
    ${metricProperties}=  Set Variable  ${resp["MetricProperties"]}
    ${unit}=  Set Variable  ${resp["Units"]}
    [return]  ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}


Validate Telementry Data Aligned With Definitions
    [Documentation]  Delete non existing BMC dump and expect an error.
    [Arguments]  ${unit}  ${metricDataType}  ${metricType}  ${metricProperties}

    # Description of argument(s):
    # metricName           metricName.
    # metricDataType  
    # metricType           
    # metricProperties  

    ${url}=  ExtractURI  ${metricProperties} 
    ${resp}=  Redfish.Get Properties  ${url}
    ${readUnits}=  Set Variable  ${resp["ReadingUnits"]}
    
    # Read Unit should be the same as schema unit
    Should Be Equal As Strings  ${readUnits}  ${unit}
    [return]  True


ExtractURI
    [Arguments]  ${metricProperties}

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


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
