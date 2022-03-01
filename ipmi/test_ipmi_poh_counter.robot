*** Settings ***
Documentation       This suite tests IPMI POH Counter Support in OpenBMC.
...                 Feature: IPMI POH Counter Support
...
...                 POH (Power-On Hours) counter is the incremental count of power ON hours in the system.
...
...                 Request and Response data defined under data/ipmi_raw_cmd_table.py
...
...                 Testcases added -
...                 Get POH Counter Command Via IPMI
...                 Verify Get POH Counter With Invalid Data Request Via IPMI
...                 Verify POH Counter Reading With Wait Time
...                 Verify POH Counter Reading With Host Power Off
...                 Verify POH Counter Reading With Host Power On
...
...                 Script compares Minutes per count and Counter reading for the above scenarios.
...
...                 Minutes per count usually 60 minutes.
...
...                 Wait Time given - 1 hour, 1 hour 30minutes when Host power OFF, 1 hour after Host Power ON
...
...                 Comparison between Initial POH Counter reading and reading after wait time / Power operation.


Library             Collections
Library             ../lib/ipmi_utils.py
Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py

Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown Execution

Test Teardown    FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

Get POH Counter Command Via IPMI
    [Documentation]  Verify Get POH Counter Command Via IPMI
    [Tags]  Get_POH_Counter_Command_Via_IPMI

    # Get POH counter Via IPMI
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Get']['POH_Counter'][1]}


Verify Get POH Counter With Invalid Data Request Via IPMI
    [Documentation]  Verify Get POH Counter With Invalid Data Request Via IPMI
    [Tags]  Verify_Get_POH_Counter_With_Invalid_Data_Request_Via_IPMI

    # Get POH counter with Invalid data request Via IPMI
    ${resp}=  Run Keyword and Expect Error  *Request data length invalid*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]} 0x00

    Should Contain  ${resp}  ${IPMI_RAW_CMD['Get']['POH_Counter'][2]}


Verify POH Counter Reading With Wait Time
    [Documentation]  Verify Get POH Counter With Wait Time Via IPMI
    [Tags]  Verify_POH_Counter_Reading_With_Wait_Time

    # Get Initial POH Command Counter Reading
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    # Sleep for given time
    Wait Timer   1 hour

    # Get POH Counter Reading after waiting for given time period
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    ${difference}=  Evaluate   ${poh_counter_2} - ${poh_counter_1}
    Should Be Equal As Integers  ${difference}  1


Verify POH Counter Reading With Host Power Off
    [Documentation]  Verify Get POH Counter After Host Power Off 
    ...              and Wait for given time then verify time Via IPMI
    [Tags]  Verify_POH_Counter_Reading_With_Host_Power_Off

    # Get Initial POH Command Counter Reading
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    Redfish Power Off

    # Sleep for given time
    Wait Timer   1 hour 30 minutes

    # Get POH Counter Reading after waiting for given time period
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    Should Be Equal As Integers  ${poh_counter_2}  ${poh_counter_1}


Verify POH Counter Reading With Host Power On
    [Documentation]  Verify Get POH Counter After Host Power On 
    ...              and Wait for given time then verify time Via IPMI
    [Tags]  Verify_POH_Counter_Reading_With_Host_Power_On

    # Get Initial POH Command Counter Reading
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    Redfish Power On

    # Sleep for given time
    Wait Timer   1 hour

    # Get POH Counter Reading after waiting for given time period
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    ${difference}=  Evaluate   ${poh_counter_2} - ${poh_counter_1}
    Should Be Equal As Integers  ${difference}  1


*** Keywords ***

Run Get POH Command And Return Counter Reading
    [Documentation]  Run the IPMI command to Get POH Counter.

    # Get POH counter Via IPMI
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]}

    ${data}=  Split String  ${resp}
    Should Be Equal  ${data[0]}  3c

    # Get POH Command Counter Reading
    ${poh_counter_reading}=  Set Variable  ${data[1:]}
    Reverse List  ${poh_counter_reading}
    ${poh_counter_reading}=  Evaluate  "".join(${poh_counter_reading})
    ${poh_counter_reading}=  Convert To Integer  ${poh_counter_reading}  16

    [Return]  ${poh_counter_reading}


Wait Timer
    [Documentation]  Sleep for given time and Execute IPMI command to Get POH Counter Reading.
    [Arguments]   ${timer}

    ${timer}=  Convert Time  ${timer}
    ${timer}=  Convert To Integer  ${timer}
    Sleep  ${timer}s


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    # Check Host current status
    ${current_host_state}=  Get Host State Via Redfish

    # If Host state is 'On' then the condition will not be executed
    # Host takes approx 5 - 6 minutes to complete power ON process.
    Run Keyword If  '${current_host_state}' == 'Off'
    ...  Redfish Power On


Suite Teardown Execution
    [Documentation]  Suite Teardown Execution.

    Redfish Power On
    Redfish.Logout
