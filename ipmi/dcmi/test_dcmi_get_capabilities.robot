*** Settings ***

Documentation    Module to test dcmi get capabilities functionality.
Resource         ../../lib/ipmi_client.robot

Test Tags       DCMI_Get_Capabilities

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
    ...  Mandatory platform capabilities
    ...  Optional platform capabilities
    ...  Power management available
    ...  Managebility access capabilities
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

    ${output}=  Get Lines Containing String  ${cmd_output}  Slave address of device:
    ${slave_address_status_1}=  Run Keyword And Return Status
    ...  Should Be Equal  ${output.strip()}  ${slave_address_list[1]}  ignore_case=True
    ${output_1}=  Get Lines Containing String  ${cmd_output}   Channel number is
    Run Keyword IF  ${slave_address_status_1} == True
    ...    Should Be Equal  ${output_1.strip()}   ${supported_capabilities[7]}
    ...  ELSE  Should Match Regexp  ${output.strip()}  [1-9]+h
