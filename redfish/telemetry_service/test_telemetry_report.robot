*** Settings ***

Documentation       Test telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Teardown       Test Teardown Execution

*** Variables ***

${metric_proprty_uri_base}     /redfish/v1/Chassis/chassis/Sensors
${metric_definition_uri_base}  /redfish/v1/TelemetryService/MetricReportDefinitions

*** Test Cases ***

Verify Basic Telemetry Report Creation
    [Documentation]  Verify if a telemetry basic report is created.
    [Tags]  Verify_Basic_Telemetry_Report_Creation

    ${report_name}=  Set Variable  Test_basic_report_ambient_temp2
    ${sensor_name}=  Set Variable  temperature_Ambient_0_Temp

    ${body}=  Catenate  {"Id": "${report_name}",
    ...  "MetricReportDefinitionType": "OnRequest",
    ...  "ReportActions":["LogToMetricReportsCollection"],
    ...  "Metrics":[{"MetricProperties":["${metric_proprty_uri_base}/${sensor_name}"]}]}

    ${dict}    Evaluate    json.loads('''${body}''')    json

    Redfish.Post  ${metric_definition_uri_base}  body=&{dict}
     ...  valid_status_codes=[${HTTP_CREATED}]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
