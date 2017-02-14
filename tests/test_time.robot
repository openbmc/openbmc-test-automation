*** Settings ***
Documentation          This suite is for testing System time in Open BMC.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/state_manager.robot
Resource               ../lib/resource.txt

Library                OperatingSystem
Library                DateTime

#Suite Setup            Open Connection And Log In
#Suite Teardown         Close All Connections
#Test Teardown          Post Test Execution

*** Variables ***
${SYSTEM_TIME_INVALID}      01/01/1969 00:00:00
${SYSTEM_TIME_VALID}        02/29/2016 09:10:00
${SYSTEM_TIME_VALID_EPOCH}  1456737000  #Equivalent epoch time for 02/29/2016 09:10:00
${ALLOWED_TIME_DIFF}        3
${SETTING_HOST}             ${SETTINGS_URI}host0

*** Test Cases ***

Test Host Reboot
    [Tags]  Test_Host_Reboot

    Initiate Host Reboot

*** Keywords ***

Get BMC Time Using IPMI
    [Documentation]  Returns BMC time of the system via IPMI

    ${stdout}  ${stderr}  ${output}=
    ...  Execute Command  date "+%m/%d/%Y %H:%M:%S"
    ...  return_stdout=True  return_stderr= True  return_rc=True
    Should Be Equal  ${output}  ${0}  msg=${stderr}

    ${resp}=  Convert Date  ${stdout}  date_format=%m/%d/%Y %H:%M:%S
    ...  exclude_millis=yes
    Should Not Be Empty  ${resp}
    [Return]  ${resp}

Set Time Owner
    [Arguments]  ${args}
    [Documentation]  Set time owner of the system via REST

    ${timeowner}=  Set Variable  ${args}
    ${valueDict}=  Create Dictionary  data=${timeowner}

    ${resp}=  OpenBMC Put Request
    ...  ${SETTING_HOST}/attr/time_owner  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}

    ${host_state}=  Get Host State

    Run Keyword If  '${host_state}' == 'Off'
    ...  Log  System is in off state so owner change will get applied.
    ...  ELSE   Run keyword
    ...  Initiate Host PowerOff

    ${owner}=  Read Attribute  ${SETTING_HOST}  time_owner
    Should Be Equal  ${owner}  ${args}

    ${current_mode}=
    ...  Read Attribute  ${TIME_MANAGER_URI.rstrip("/")}  curr_time_owner
    Should Be Equal  ${current_mode}  ${args}

    [Return]  ${jsondata['status']}

Set Time Mode
    [Arguments]  ${args}
    [Documentation]  Set time mode of the system via REST

    ${timemode}=  Set Variable  ${args}
    ${valueDict}=  Create Dictionary  data=${timemode}

    ${resp}=  OpenBMC Put Request
    ...  ${SETTING_HOST}/attr/time_mode  data=${valueDict}
    ${jsondata}=  to JSON  ${resp.content}
    Sleep  5s

    ${mode}=  Read Attribute  ${SETTING_HOST}  time_mode
    Should Be Equal  ${mode}  ${args}

    ${current_mode}=
    ...  Read Attribute  ${TIME_MANAGER_URI.rstrip("/")}  curr_time_mode
    Should Be Equal  ${current_mode}  ${args}

Get BMC Time Using REST
    [Documentation]  Returns BMC time of the system via REST
    ...              Time Format : YYYY-MM-DD hh:mm:ss.mil
    ...              eg. 2016-12-14 07:09:58.000

    @{time_owner}=  Create List  BMC
    ${data}=  Create Dictionary  data=@{time_owner}
    ${resp}=  OpenBMC Post Request
    ...  ${TIME_MANAGER_URI}action/GetTime  data=${data}
    ${jsondata}=  To JSON  ${resp.content}
    ${time_epoch}=  Get From List  ${jsondata["data"]}  0
    ${resp}=  Convert Date
    ...  ${time_epoch}  date_format=%a %b %d %H:%M:%S %Y %Z
    [Return]  ${resp}

Get HOST Time Using REST
    [Documentation]  Returns HOST time of the system via REST
    ...              Time Format : YYYY-MM-DD hh:mm:ss.mil
    ...              eg. 2016-12-14 07:09:58.000

    @{time_owner}=  Create List  HOST
    ${data}=  Create Dictionary  data=@{time_owner}
    ${resp}=  OpenBMC Post Request
    ...  ${TIME_MANAGER_URI}action/GetTime  data=${data}
    ${jsondata}=  To JSON  ${resp.content}
    ${time_epoch}=  Get From List  ${jsondata["data"]}   0
    ${resp}=  Convert Date
    ...  ${time_epoch}  date_format=%a %b %d %H:%M:%S %Y %Z
    [Return]  ${resp}

Set Time Using REST
    [Arguments]  ${operation}  ${owner}  ${mode}  ${status}  ${bmc_time}
    ...  ${host_time}
    [Documentation]  Set BMC or Host time on system via REST.
    ...              Description of arguments:
    ...              operation :  Set BMC/Host time
    ...              owner: Time owner
    ...              mode:  Time mode
    ...              status:   Expected status of set BMC time URI
    ...              bmc_time:   Status of BMC time after operation
    ...              host_time:  Status of HOST time after operation
    ...                Set - Given time is set
    ...                Not Set - Given time is not set
    ...                Change - time is change
    ...                No Change - time is not change

    Set Time Owner  ${owner}
    Set Time Mode  ${mode}

    ${setdate}=  Convert Date  ${SYSTEM_TIME_VALID}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=yes

    @{bmc_date_list}=  Create List  BMC  ${setdate}
    @{host_date_list}=  Create List  HOST  ${SYSTEM_TIME_VALID_EPOCH}

    ${time_owner_date}=  Set Variable If
    ...  '${operation}' == 'Set BMC Time'  ${bmc_date_list}
    ...  '${operation}' == 'Set Host Time'  ${host_date_list}

    ${old_bmc_time}=  Get BMC Time Using REST
    ${old_host_time}=  Get HOST Time Using REST

    ${data}=  Create Dictionary  data=${time_owner_date}
    ${resp}=  OpenBMC Post Request
    ...  ${TIME_MANAGER_URI}action/SetTime  data=${data}
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${jsondata['status']}  ${status}

    ${new_bmc_time}=  Get BMC Time Using REST
    ${new_host_time}=  Get HOST Time Using REST

    ${bmc_diff_set_new}=
    ...  Subtract Date From Date  ${setdate}  ${new_bmc_time}
    ${bmc_diff_set_new}=  Evaluate  abs(${bmc_diff_set_new})
    ${bmc_diff_old_new}=
    ...  Subtract Date From Date  ${old_bmc_time}  ${new_bmc_time}
    ${bmc_diff_old_new}=  Evaluate  abs(${bmc_diff_old_new})

    ${host_diff_set_new}=
    ...  Subtract Date From Date  ${setdate}  ${new_host_time}
    ${host_diff_set_new}=  Evaluate  abs(${host_diff_set_new})
    ${host_diff_old_new}=
    ...  Subtract Date From Date  ${old_host_time}  ${new_host_time}
    ${host_diff_old_new}=  Evaluate  abs(${host_diff_old_new})

    Run Keyword If   '${bmc_time}' == 'Not Set'
    ...    Should Be True  ${bmc_diff_set_new} >= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${bmc_time}' == 'Set'
    ...    Should Be True  ${bmc_diff_set_new} <= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${bmc_time}' == 'No Change'
    ...    Should Be True  ${bmc_diff_old_new} <= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${bmc_time}' == 'Change'
    ...    Should Be True  ${bmc_diff_old_new} >= ${ALLOWED_TIME_DIFF}

    Run Keyword If  '${host_time}' == 'No Change'
    ...    Should Be True  ${host_diff_old_new} <= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${host_time}' == 'Change'
    ...    Should Be True  ${host_diff_old_new} >= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${host_time}' == 'Not Set'
    ...    Should Be True  ${host_diff_set_new} >= ${ALLOWED_TIME_DIFF}
    ...  ELSE IF  '${host_time}' == 'Set'
    ...    Should Be True  ${host_diff_set_new} <= ${ALLOWED_TIME_DIFF}


Post Test Execution
    [Documentation]  Perform operations after test execution. Capture FFDC
    ...  in case of test case failure and sets default values for time mode
    ...  and owner.

    Run Keyword If Test Failed  FFDC On Test Case Fail
    Set Time Owner  BMC
    Set Time Mode  NTP
