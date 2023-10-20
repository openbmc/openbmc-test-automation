*** Settings ***
Documentation       This suite tests IPMI POH Counter Support in OpenBMC.
...                 Feature: IPMI POH Counter Support
...
...                 POH (Power-On Hours) counter is the incremental count of power ON
...                 hours in the system.
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
...                 Wait Time given - 1 hour, 1 hour 30minutes when Host power OFF, 1 hour
...                 after Host Power ON
...
...                 Comparison between Initial POH Counter reading and reading after wait
...                 time / Power operation.


Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             Collections
Library             ../lib/ipmi_utils.py
Variables           ../data/ipmi_raw_cmd_table.py
Test Tags           IPMI

Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown Execution

Test Teardown    FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

Get POH Counter Command Via IPMI
    [Documentation]  Verify get POH counter command Via IPMI.
    [Tags]  Get_POH_Counter_Command_Via_IPMI

    # Verify get POH counter command via IPMI.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Get']['POH_Counter'][1]}


Verify Get POH Counter With Invalid Data Request Via IPMI
    [Documentation]  Verify get POH counter with invalid data request via IPMI.
    [Tags]  Verify_Get_POH_Counter_With_Invalid_Data_Request_Via_IPMI

    # verify get POH counter command with invalid data request Via IPMI.
    ${resp}=  Run Keyword and Expect Error  *Request data length invalid*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]} 0x00


Verify POH Counter Reading With Wait Time
    [Documentation]  Verify POH counter reading with wait time via IPMI.
    [Tags]  Verify_POH_Counter_Reading_With_Wait_Time

    # Get initial POH command counter reading.
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    # Sleep for given time.
    Sleep  1h

    # Get POH Counter Reading after waiting for given time period.
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    # Verify difference between initial and present counter readings.
    # The counter reading should always be incremented by 1 for each hour.
    ${difference}=  Evaluate   ${poh_counter_2} - ${poh_counter_1}
    Should Be Equal As Integers  ${difference}  1


Verify POH Counter Reading With Host Power Off
    [Documentation]  Verify POH counter reading with wait time after host power off.
    [Tags]  Verify_POH_Counter_Reading_With_Host_Power_Off

    # Get initial POH command counter reading.
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    # Power off the system.
    IPMI Power Off

    # Sleep for given time.
    Sleep  1 hours 30 minutes

    # Get POH counter reading after waiting for given time period.
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    # Once the system is powered off,
    # the poh counter reading should not increment.
    Should Be Equal As Integers  ${poh_counter_2}  ${poh_counter_1}


Verify POH Counter Reading With Host Power On
    [Documentation]  Verify Get POH Counter with wait time after host power on.
    [Tags]  Verify_POH_Counter_Reading_With_Host_Power_On

    # Get initial POH command counter reading.
    ${poh_counter_1}=  Run Get POH Command And Return Counter Reading

    # Power on the system.
    IPMI Power On

    # Sleep for given time.
    Sleep  1h

    # Get POH Counter reading after waiting for given time period.
    ${poh_counter_2}=  Run Get POH Command And Return Counter Reading

    # Once the system is powered on,
    # the pon counter reading should increment by 1.
    ${difference}=  Evaluate   ${poh_counter_2} - ${poh_counter_1}
    Should Be Equal As Integers  ${difference}  1


*** Keywords ***

Run Get POH Command And Return Counter Reading
    [Documentation]  Run the IPMI command to Get POH Counter.

    # Get POH counter Via IPMI.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Get']['POH_Counter'][0]}

    # Verify Minutes per count.
    ${data}=  Split String  ${resp}
    Should Be Equal  ${data[0]}  3c

    # Get POH Command counter reading.
    ${poh_counter_reading}=  Set Variable  ${data[1:]}
    Reverse List  ${poh_counter_reading}
    ${poh_counter_reading}=  Evaluate  "".join(${poh_counter_reading})
    ${poh_counter_reading}=  Convert To Integer  ${poh_counter_reading}  16

    [Return]  ${poh_counter_reading}


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    # Check Host current status.
    ${current_host_state}=  Get Host State Via Redfish

    # If Host state is 'On' then the condition will not be executed.
    # Host may take approx 5 - 6 minutes to complete power ON process.
    Run Keyword If  '${current_host_state}' == 'Off'
    ...  IPMI Power On


Suite Teardown Execution
    [Documentation]  Suite Teardown Execution.

    IPMI Power On
    Redfish.Logout
