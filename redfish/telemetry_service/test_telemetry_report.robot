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
    [Teardown]  Redfish.Delete  ${metric_definition_base_uri}/${report_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

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
    [Tags]  Verify_Basic_Periodic_Telemetry_Report_Creation
    [Teardown]  Redfish.Delete  ${metric_definition_base_uri}/${report_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

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

    ${resp}=  Redfish.Get  ${metric_definition_base_uri}/${report_name}
    Should Be True  '${resp.dict["MetricReportDefinitionType"]}' == 'Periodic'


Verify Error After Exceeding Maximum Report Creation
    [Documentation]  Verify Error After Exceeding Maximum Report Creation
    [Tags]  Verify_Error_After_Exceeding_Maximum_Report_Creation

    ${resp}=  Redfish.Get Properties  /redfish/v1/TelemetryService
    ${report_name}=  Set Variable  Testreport

    # Create maximum number of reports.
    FOR  ${i}  IN RANGE  ${resp["MaxReports"]}
        Create Basic Telemetry Report   Ambient_0_Temp   ${report_name}${i}  success
    END

    # Attempt another report creation and it should fail.
    Create Basic Telemetry Report   Ambient_0_Temp   ${report_name}${resp["MaxReports"]}  fail

    # Now delete the reports created.
    FOR  ${i}  IN RANGE  ${resp["MaxReports"]} 
        Redfish.Delete  ${metric_definition_base_uri}/${report_name}${i}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    END


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail


Create Basic Telemetry Report
    [Arguments]  ${metric}   ${report_name}  ${result}=success

    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/TelemetryService/MetricDefinitions/${metric}
    ${body}=  Catenate  {"Id": "${report_name}",
    ...  "MetricReportDefinitionType": "OnRequest",
    ...  "ReportActions":["LogToMetricReportsCollection"],
    ...  "Metrics":[{"MetricProperties":${resp["MetricProperties"]}}]}
    ${body}=  Replace String  ${body}  '  "
    ${dict}  Evaluate  json.loads('''${body}''')  json

    ${status_code_expected}=  Set Variable If
    ...  '${result}' == 'success'  [${HTTP_CREATED}, ${HTTP_OK}]
    ...  '${result}' == 'fail'  [${HTTP_BAD_REQUEST}, ${HTTP_NOT_FOUND}]

    Redfish.Post  ${metric_definition_base_uri}  body=&{dict}
     ...  valid_status_codes=${status_code_expected}

    Redfish.Get  ${metric_report_base_uri}/${report_name}
     ...  valid_status_codes=${status_code_expected}
