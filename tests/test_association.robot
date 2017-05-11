*** Settings ***
Documentation       Test Error callout association.

Resource            ../lib/connection_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Suite Setup         Run Keywords  Verify callout-test  AND
...                 Boot Host  AND
...                 Clear Existing Error Logs
Test Setup          Open Connection And Log In
Test Teardown       Close All Connections
Suite Teardown      Clear Existing Error Logs

***Variables***
${sys_data}  /sys/devices/platform/fsi-master/slave@00:00

*** Test Cases ***

Create Test Error Callout And Verify
    [Documentation]  Create error log callout and verify via REST.
    [Tags]  Create_Test_Error_Callout_And_Verify

    Create Test Error With Callout
    Verify Test Error Log And Callout

Create Test Error Callout And Verify Device Path
    [Documentation]  Create Test Error Callout And Verify Device Path.
    [Tags]  Create_Test_Error_Callout_And_Verify_Device_Path

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ]

    Delete Error logs
    Create Test Error With Callout
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    ${jsondata}=  To JSON  ${resp.content}
    Should Contain  ${jsondata}["data"]["AdditionalData"]}  ${sys_data}

    Create Test Error Callout And Delete
    [Documentation]  Create Test Error Callout And Delete.
    [Tags]  Create_Test_Error_Callout_And_Delete

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/1/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    Clear Existing Error Logs
    Create Test Error With Callout
    Delete Error logs
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}/callout
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

Create Two Test Error Callout And Delete
    [Documentation]  Create Two Test Error Callout And Delete.
    [Tags]  Create_Two_Test_Error_Callout_And_Delete

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/1/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/2": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 2,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/2/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    Delete Error logs
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    ${type}=  Evaluate  type(${HTTP_NOT_FOUND})
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    Create Test Error With Callout
    ${error_id}=  Return jsondata
    ${dict_values}=  Get From Dictionary  ${error_id}  data
    ${entry_id}=  Get From List  ${dict_values}  0
    ${id_num}=  Split String  ${entry_id}  /
    ${id_number_1}=  Get From List  ${id_num}  -1
    Create Test Error With Callout
    ${error_id}=  Return jsondata
    ${dict_values}=  Get From Dictionary  ${error_id}  data
    ${entry_id}=  Get From List  ${dict_values}  1
    ${id_num}=  Split String  ${entry_id}  /
    ${id_number_2}=  Get From List  ${id_num}  -1
    Delete Error Log Entry  ${BMC_LOGGING_ENTRY}${id_number_2}
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    ${jsondata}=  To JSON  ${resp.content}
    ${data_1}=  Get From List  ${jsondata["data"]}  0
    Should Contain  ${data_1}  ${BMC_LOGGING_ENTRY}${id_number_1}

*** Keywords ***

Verify callout-test
    [Documentation]  Verify existence of prerequisite callout-test.

    Open Connection And Log In
    ${out}  ${stderr}=  Execute Command  which callout-test  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${out}  callout-test

Clear Existing Error Logs
    [Documentation]  If error log isn't empty, restart the logging service on
    ...              the BMC

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

Create Test Error With Callout
    [Documentation]  Generate test error log with callout for CPU0.

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/4": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 4,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/4/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    Execute Command On BMC
    ...  callout-test /sys/devices/platform/fsi-master/slave@00:00


Verify Test Error Log And Callout
    [Documentation]  Verify test error log entries.
    ${content}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Message
    Should Be Equal  ${content}
    ...  example.xyz.openbmc_project.Example.Elog.TestCallout
    ${content}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Severity
    Should Be Equal  ${content}
    ...  xyz.openbmc_project.Logging.Entry.Level.Error
    ${content}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}/callout  endpoints
    Should Be Equal  ${content[0]}
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0

Boot Host
    [Documentation]  Boot the host if current state is "Off".
    ${current_state}=  Get Host State
    Run Keyword If  '${current_state}' == 'Off'
    ...  Initiate Host Boot

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is OS Starting

Return jsondata
    [Documentation]  Return jsondata.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list
    ${jsondata}=  To JSON  ${resp.content}
    Log To Console  ${jsondata}
    [Return]  ${jsondata}
