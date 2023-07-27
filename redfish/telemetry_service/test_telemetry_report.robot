*** Settings ***

Documentation       Test telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Teardown       Test Teardown Execution

*** Variables ***

${metric_definition_base_uri}  /redfish/v1/TelemetryService/MetricReportDefinitions
${metric_report_base_uri}      /redfish/v1/TelemetryService/MetricReports

*** Test Cases ***

Verify Basic Telemetry Report Creation
    [Documentation]  Verify if a telemetry basic report is created.
    [Tags]  Verify_Basic_Telemetry_Report_Creation

    ${report_name}=  Set Variable  Test_basic_report_ambient_temp
    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/TelemetryService/MetricDefinitions/Ambient_0_Temp
    ${body}=  Catenate  {"Id": "${report_name}",
    ...  "MetricReportDefinitionType": "OnRequest",
    ...  "ReportActions":["LogToMetricReportsCollection"],
    ...  "Metrics":[{"MetricProperties":${resp["MetricProperties"]}}]}
    ${body}=  Replace String  ${body}  '  "
    ${dict}  Evaluate  json.loads('''${body}''')  json

    Redfish.Post  ${metric_definition_base_uri}  body=&{dict}
     ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Get  ${metric_report_base_uri}/Test_basic_report_ambient_temp
     ...  valid_status_codes=[${HTTP_OK}]


Verify Basic Periodic Telemetry Report Creation
    [Documentation]  Verify if a telemetry basic periodic report is created.
    [Tags]  Verify_Periodic_Basic_Telemetry_Report_Creation

    ${report_name}=  Set Variable  Test_basic_periodic_report_ambient_temp
    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/TelemetryService/MetricDefinitions/Ambient_0_Temp
    ${body}=  Catenate  {"Id": "${report_name}",
    ...  "MetricReportDefinitionType": "Periodic",
    ...  "Name": "Report",
    ...  "ReportActions":["LogToMetricReportsCollection"],
    ...  "Metrics":[{"CollectionDuration": "PT30.000S",
    ...  "CollectionFunction": "Average","MetricProperties":${resp["MetricProperties"]}}],
    ...  "ReportUpdates": "AppendWrapsWhenFull",
    ...  "AppendLimit":10,
    ...  "Schedule": {"RecurrenceInterval": "PT5.000S"}}
    ${body}=  Replace String  ${body}  '  "
    ${dict}  Evaluate  json.loads('''${body}''')  json

    Redfish.Post  ${metric_definition_base_uri}  body=&{dict}
     ...  valid_status_codes=[${HTTP_CREATED}]

    Redfish.Get  ${metric_report_base_uri}/${report_name}
     ...  valid_status_codes=[${HTTP_OK}]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
