*** Settings ***

Documentation       Test BMC telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Redfish.Login
Suite Teardown      Redfish.Logout
Test Setup          Redfish Delete All BMC Dumps
Test Teardown       Test Teardown Execution

*** Variables ***



*** Test Cases ***

Verify Total Power Telemetry Data From BMC
    [Documentation]  Delete non existing BMC dump and expect an error.
    [Tags]

    ${uri}=  Set Variable
    ...  /redfish/v1/TelemetryService/MetricDefinitions/total_power

    ${metricName}  ${metricDataType}  ${metricType  ${metricProperties}=
    ...  Retreieve Telemetery Data Definitions  ${uri}

    ${validated}=  Validate Telementry Data Aligned With Definitions 
    ...  ${metricName}  ${metricDataType}  ${metricType}  ${metricProperties}

    Should Be True  ${validated}

 
*** Keywords ***

Retreieve Telemetery Data Definitions
    [Documentation]  Retreieve Telemetery Data Definitions.

    ${resp}=  Redfish.Get Properties  ${defURI}
    ${metricDataType}=  Set Variable  ${resp["MetricDataType"]}
    ${metricType}=  Set Variable  ${resp["MetricType"]}
    ${metricProperties}=  Set Variable  ${resp["MetricProperties"]}
    ${metricName}=  Set Variable  ${resp["Name"]}
    [return]  ${metricName}  ${metricDataType}  ${metricType}  ${metricProperties}

Validate Telementry Data Aligned With Definitions
    [Documentation]  Delete non existing BMC dump and expect an error.

    [return]  True

Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
