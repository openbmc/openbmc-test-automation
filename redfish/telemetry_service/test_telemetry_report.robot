*** Settings ***

Documentation       Test telemetry functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Redfish.Logout
Test Setup          Delete All Telemetry Reports
Test Teardown       Test Teardown Execution

*** Variables ***

${metric_definition_base_uri}  /redfish/v1/TelemetryService/MetricReportDefinitions
${metric_report_base_uri}      /redfish/v1/TelemetryService/MetricReports


*** Test Cases ***

Verify Basic Telemetry Report Creation
    [Documentation]  Verify basic telemetry report creations for different metrics.
    [Tags]  Verify_Basic_Telemetry_Report_Creation
    [Template]  Create Basic Telemetry Report

    # metric definition MetricReportDefinitionType   ReportActions       AppendLimit 
    total_power         OnRequest         LogToMetricReportsCollection
    Battery_Voltage     Periodic          LogToMetricReportsCollection   100
    Ambient_0_Temp      OnRequest         LogToMetricReportsCollection
    proc0_core1_1_temp  Periodic          LogToMetricReportsCollection   500
    PCIE_0_Temp         OnRequest         LogToMetricReportsCollection
    dimm0_pmic_temp     Periodic          LogToMetricReportsCollection   1000
    Relative_Humidity   OnRequest         LogToMetricReportsCollection
    pcie_dcm0_power     Periodic          LogToMetricReportsCollection   32768
    io_dcm0_power       OnRequest         LogToMetricReportsCollection


Verify Error After Exceeding Maximum Report Creation
    [Documentation]  Verify error while creating telemetry report more than max report limit.
    [Tags]  Verify_Error_After_Exceeding_Maximum_Report_Creation

    ${report_name}=  Set Variable  Testreport

    # Delete any existing reports.
    Delete All Telemetry Reports

    # Create maximum number of reports.
    ${resp}=  Redfish.Get Properties  /redfish/v1/TelemetryService
    FOR  ${i}  IN RANGE  ${resp["MaxReports"]}
        Create Basic Telemetry Report   total_power  Periodic  LogToMetricReportsCollection
    END

    # Attempt another report creation and it should fail.
    Create Basic Telemetry Report   total_power  Periodic  LogToMetricReportsCollection  fail

    # Now delete the reports created.
    Delete All Telemetry Reports


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Redfish Power On  stack_mode=skip


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Delete All Telemetry Reports


Create Basic Telemetry Report
    [Documentation]  Create a basic telemetry report with single metric.
    [Arguments]  ${metric_definition_name}  ${metric_definition_type}  ${report_action}  ${append_limit}=10  ${expected_result}=success

    # Description of argument(s):
    # metric_definition_name    Name of metric definition like Ambient_0_Temp.
    # metric_definition_type    Name of telemetry report which needs to be created.
    # report_action             Telemetry report action.
    # append_limit              Append limit of the metric data in the report. 
    # expected_result           Expected result of report creation - success or fail.

    ${resp}=  Redfish.Get Properties
    ...  /redfish/v1/TelemetryService/MetricDefinitions/${metric_definition_name}
    # Example of response from above Redfish GET request.
    # "@odata.id": "/redfish/v1/TelemetryService/MetricDefinitions/Ambient_0_Temp",
    # "@odata.type": "#MetricDefinition.v1_0_3.MetricDefinition",
    # "Id": "Ambient_0_Temp",
    # "IsLinear": true,
    # "MaxReadingRange": 127.0,
    # "MetricDataType": "Decimal",
    # "MetricProperties": [
    #     "/redfish/v1/Chassis/chassis/Sensors/temperature_Ambient_0_Temp"
    # ],
    # "MetricType": "Gauge",
    # "MinReadingRange": -128.0,
    # "Name": "Ambient_0_Temp",
    # "Units": "Cel"

    ${report_name}=  Generate Random String  16  [NUMBERS]abcdef
    ${body}=  Catenate  {"Id": "${report_name}",
    ...  "MetricReportDefinitionType": "${metric_definition_type}",
    ...  "Name": "Report",
    ...  "ReportActions":["${report_action}"],
    ...  "Metrics":[{"CollectionDuration": "PT30.000S",
    ...  "MetricProperties":${resp["MetricProperties"]}}],
    ...  "ReportUpdates": "AppendWrapsWhenFull",
    ...  "AppendLimit": ${append_limit},
    ...  "Schedule": {"RecurrenceInterval": "PT5.000S"}}

    ${body}=  Replace String  ${body}  '  "
    ${dict}  Evaluate  json.loads('''${body}''')  json

    ${status_code_expected}=  Set Variable If
    ...  '${expected_result}' == 'success'  [${HTTP_CREATED}]
    ...  '${expected_result}' == 'fail'  [${HTTP_BAD_REQUEST}]

    Redfish.Post  ${metric_definition_base_uri}  body=&{dict}
     ...  valid_status_codes=${status_code_expected}

    IF  '${expected_result}' == 'success'
        # Verify definition of report has attributes provided at the time of creation.
        ${resp_report}=  Redfish.Get  ${metric_definition_base_uri}/${report_name}
        ...  valid_status_codes=[${HTTP_OK}]
        Should Be True  '${resp_report.dict["MetricReportDefinitionType"]}' == '${metric_definition_type}'
        Should Be True  '${resp_report.dict["AppendLimit"]}' == '${AppendLimit}'
        Should Be True  '${resp_report.dict["ReportActions"][0]}' == '${report_action}'
        Should Be True  '${resp_report.dict["Metrics"]}[0][MetricProperties][0]' == '${resp["MetricProperties"][0]}'
    END


Delete All Telemetry Reports
    [Documentation]  Delete all existing telemetry reports.

    ${report_list}=  Redfish_Utils.Get Member List  /redfish/v1/TelemetryService/MetricReportDefinitions
    FOR  ${report}  IN  @{report_list}
      Redfish.Delete  ${report}  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    END
