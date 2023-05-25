*** Settings ***

Documentation    Module to test dcmi get capabilites functionality.
Resource         ../../lib/ipmi_client.robot

*** Variables ***
@{slave_address_list}  Slave address of device: 0h (8bits)(Satellite/External controller)
...                    Slave address of device: 20h (BMC)

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
    ...  Channel number is 0h (Primary BMC)
    ...  Device revision is 0
    # Manageability Access Attributes:
    ...  Primary LAN channel number: ${CHANNEL_NUMBER} is available
    ...  Secondary LAN channel is not available for OOB
    ...  No serial channel is available

    FOR  ${capability}  IN  @{supported_capabilities}
      Run Keyword And Continue On Failure  Should Contain  ${cmd_output}  ${capability}  ignore_case=True
      ...  msg=Supported DCMI capabilities not present.
    END

    FOR  ${slave_address}  IN  @{slave_address_list}
      ${slave_address_status}=  Run Keyword And Return Status
      ...  Should Contain  ${cmd_output}  ${slave_address}  ignore_case=True
      Exit For Loop IF  ${slave_address_status} == True
    END

    Run Keyword IF  ${slave_address_status} == False  Fail  msg=Slave address is showing wrongly.