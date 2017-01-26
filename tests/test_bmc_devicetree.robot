*** Settings ***
Documentation       This suite is for Verifying BMC device tree

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource 	    ../lib/ipmi_client.robot
Library	            String

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       FFDC On Test Case Fail


*** Variables ***
${devicetree_base}  /sys/firmware/devicetree/base/
${bmc_model}  witherspoon

*** Test Cases ***

[TC-001]-Check BMC Model Is Set
    [Documentation]     Verify if the BMC Model is populated in the device
    ...                 tree
    [Tags]  TC-001-Check_BMC_Model_Is_Set

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  model
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length  ${output}


[TC-002]-Check BMC Name Property Is Set
    [Documentation]     Verify if the BMC name property is populated
    [Tags]  [TC-002]-Check_BMC_Name_Property_Is_Set

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  name
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length  ${output}

[TC-003]-Check For Right BMC Model Is Set
    [Documentation]     Verify if right BMC Model is populated in the device
    ...                 tree
    [Tags]  [TC-003]-Check_For_Right_BMC_Model_Is_Set

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  model
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Should Not Be Empty  ${output}
    ${tmp_bmc_model}=  Fetch From Right  ${OPENBMC_MODEL}  /
    ${tmp_bmc_model}=  Fetch From Left  ${tmp_bmc_model}  .
    Set Suite Variable  ${bmc_model}  ${tmp_bmc_model}
    Should Contain  ${output}  ${bmc_model}  ignore_case=True


[TC-004]-Check BMC CPU Name Property Is Set And Validate
    [Documentation]     Verify if the BMC CPU name property is populated
    [Tags]  [TC-004]-Check_BMC_CPU_Name_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  cpus/name
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  cpus


[TC-005]-Check BMC Compatible Property Is Set And Validate
    [Documentation]     Verify if the BMC CPU name property is populated
    [Tags]  [TC-005]-Check_BMC_Compatible_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  compatible
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  ${bmc_model}
    Run Keyword if  '${bmc_model}' == 'Witherspoon'
    ...    Should Contain  ${output}  ast2500  ignore_case=True
    ...  ELSE  Should Contain  ${output}  ast2400  ignore_case=True

[TC-006]-Check BMC CPU Compatible Property Is Set And Validate
    [Documentation]     Verify if the BMC CPU name property is populated
    [Tags]  [TC-006]-Check_BMC_CPU_Compatible_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  cpus/cpu@0/compatible
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  arm

[TC-007]-Check BMC Memory Device_type Property Is Set And Validate
    [Documentation]     Verify if the BMC Memory device-type property is
    ...                 populated
    [Tags]
    ...  [TC-007]-Check_BMC_Memory_Device_type_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  memory/device_type
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  memory

[TC-008]-Check BMC Memory Name Property Is Set And Validate
    [Documentation]     Verify if the BMC Memory name property is populated
    [Tags]
    ...  [TC-008]-Check_BMC_Memory_Name_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  memory/name
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  memory

[TC-009]-Check BMC FSI Name Property Is Set And Validate
    [Documentation]  Verify if the BMC FSI name property is populated
    [Tags]
    ...  [TC-009]-Check_BMC_FSI_Name_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  fsi-master/name
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  fsi-master

[TC-010]-Check BMC FSI Compatible Property Is Set And Validate
    [Documentation]  Verify if the BMC FSI Compatible property is populated
    [Tags]
    ...  [TC-010]-Check_BMC_FSI_Compatible_Property_Is_Set_And_Validate

    ${devicetree_path}=  Catenate  SEPARATOR=
    ...  ${devicetree_base}  fsi-master/compatible
    ${output}   ${stderr}=  Execute Command  cat ${devicetree_path}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Verify Property Length And Content  ${output}  ibm,fsi-master

*** Keywords ***

Verify Property Length
    [Documentation]  Check for Property Length and should be > 1
    [Arguments]   ${output}

    Should Not Be Empty  ${output}
    ${length}=  Get Length  ${output}
    Should Be True  ${length} > 1

Verify Property Length And Content
    [Documentation]  Check for Content & Property Length and should be > 1
    [Arguments]   ${output}  ${property_name}
    Log To Console  ${output}
    Log To Console  ${property_name}
    Verify Property Length  {output}
    Should Contain  ${output}  ${property_name}  ignore_case=True
