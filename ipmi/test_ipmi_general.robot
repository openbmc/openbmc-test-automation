*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify Get DCMI Capabilities
    [Documentation]  Verify get DCMI capabilities command output.
    [Tags]  Verify_Get_DCMI_Capabilities
    ${cmd_output}=  Run IPMI Standard Command  dcmi discover

    @{supported_capabilities}=  Create List
    # Supported DCMI capabilities:
    ...  Mandatory platform capabilties
    ...  Optional platform capabilties
    ...  Power management available
    ...  Managebility access capabilties
    ...  In-band KCS channel available
    # Mandatory platform attributes:
    ...  200 SEL entries
    ...  SEL automatic rollover is enabled
    # Optional Platform Attributes:
    ...  Slave address of device: 0h (8bits)(Satellite/External controller)
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: 1 is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    FOR  ${capability}  IN  @{supported_capabilities}
      Should Contain  ${cmd_output}  ${capability}  ignore_case=True
      ...  msg=Supported DCMI capabilities not present.
    END


Test Get Self Test Results via IPMI Raw Command
    [Documentation]  Get self test results via IPMI raw command and verify the output.
    [Tags]  Test_Get_Self_Test_Results_via_IPMI

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Self_Test_Results']['Get'][0]}

    # 55h = No error. All Self Tests Passed.
    # 56h = Self Test function not implemented in this controller.
    Should Contain Any  ${resp}  55 00  56 00


Test Get Device GUID Via IPMI Raw Command
    [Documentation]  Get device GUID via IPMI raw command and verify it using Redfish.
    [Tags]  Test_Get_Device_GUID_via_IPMI_and_Verify_via_Redfish
    [Teardown]  Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail
    # Get GUIDS via IPMI.
    # This should match the /redfish/v1/Managers/bmc's UUID data.
    ${guids}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Device GUID']['Get'][0]}
    # Reverse the order and remove space delims.
    ${guids}=  Split String  ${guids}
    Reverse List  ${guids}
    ${guids}=  Evaluate  "".join(${guids})

    Redfish.Login
    ${uuid}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  UUID
    ${uuid}=  Remove String  ${uuid}  -

    Rprint Vars  guids  uuid
    Valid Value  uuid  ['${guids}']
