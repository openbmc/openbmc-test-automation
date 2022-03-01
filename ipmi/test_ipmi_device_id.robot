*** Settings ***
Documentation       This suite tests IPMI Payload in OpenBMC.
...                 This script verifies Get Device ID IPMI command.
...
...                 Response data validated for each and every byte,
...                 with respect to expected response.
...
...                 Following data validated in response bytes :
...                 Device ID, Device Revision, Firmware Revision 1 & 2,
...                 IPMI Version, Manufacture ID, Product ID,
...                 Auxiliary Firmware Revision Information
...
...                 Request Data for Get Device ID defined under,
...                       - data/ipmi_raw_cmd_table.py
...                 

Library             Collections
Library             ../lib/ipmi_utils.py
Library             ../lib/var_funcs.py
Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py


*** Test Cases ***

Get Device ID Via IPMI
    [Documentation]  Verify Get Device ID using IPMI
    [Tags]  Get_Device_ID_Via_IPMI

    # Verify Get Device ID
    ${resp}=  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Device_ID']['Get'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Device_ID']['Get'][1]}


Verify Get Device ID With Invalid Data Request
    [Documentation]  Verify Get Device ID With Invalid Data Request Via IPMI
    [Tags]  Verify_Get_Device_ID_With_Invalid_Data_Request

    # Run IPMI Get Device ID command with Invalid Request Data byte
    ${resp}=  Run Keyword and Expect Error  *Request data length invalid*
    ...  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device_ID']['Get'][0]} 0x00
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_ID']['Get'][2]}


Verify Device ID Response Data Via IPMI
    [Documentation]  Verify Get Device ID Response Data Bytes using IPMI.
    [Tags]  Verify_Device_ID_Response_Data_Via_IPMI

    # Get Device ID IPMI command
    ${resp}=  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['Device_ID']['Get'][0]}

    # Split each and every byte and form list
    ${resp}=  Split String  ${resp}

    # Checking Device ID
    Run Keyword And Continue On Failure  Should Not Be Equal  ${resp[0]}  00
    ...  msg=Device ID cannot be Unspecified

    # Verify Device Revision
    ${device_rev}=  Set Variable  ${resp[1]}
    ${device_rev}=  Convert To Binary  ${device_rev}  base=16
    ${device_rev}=  Zfill Data  ${device_rev}  8
    # Comparing The reserved bits from Device Revision
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${device_rev[1:4]}  000

    # Get version Details from /etc/os-release
    ${os_release}=  Get BMC OS Release Details
    ${version}=  Get Version Details From BMC OS Release  ${os_release}

    # Verify Firmware Revision 1
    ${firmware_rev1}=  Set Variable  ${version[0]}
    Run Keyword And Continue On Failure  Should Be Equal  ${resp[2]}  0${firmware_rev1}

    # Verify Firmware Revision 2
    ${firmware_rev2}=  Set Variable  ${version[1]}
    Run Keyword And Continue On Failure  Should Be Equal  ${resp[3]}  0${firmware_rev2}

    # Verify IPMI Version
    Run Keyword And Continue On Failure  Should Be Equal  ${resp[4]}  02

    # Verify Manufacture ID
    ${manufacture_id}=  Set Variable  ${resp[6:9]}
    ${manufacture_id}=  Evaluate  "".join(${manufacture_id})
    ${manufacture_data}=  Convert To Binary  ${manufacture_id}  base=16
    # Manufacure ID has Most significant four bits - reserved (0000b)
    Run Keyword And Continue On Failure  Should Be Equal  ${manufacture_data[-5:-1]}  0000

    # Verify Product ID
    ${product_id}=  Set Variable  ${resp[9:11]}
    ${product_id}=  Evaluate   "".join(${product_id})
    Run Keyword And Continue On Failure  Should Not Be Equal  ${product_id}  0000
    ...  msg=Product ID cannot be Zero

    # Verify Auxiliary Firmware Revision Information
    # etc/os-release - from bmc
    ${auxiliary_info}=  Get Auxiliary Firmware Revision Information

    # Get Auxiliary Firmware Revision Information from IPMI response
    ${auxiliary_rev_version}=  Set Variable  ${resp[11:]}
    Reverse List  ${auxiliary_rev_version}
    ${auxiliary_rev_version}=  Evaluate  "".join(${auxiliary_rev_version})
    ${auxiliary_rev_version}=  Convert To Integer  ${auxiliary_rev_version}  16

    # Compare both IPMI aux version and dev_id.json aux version
    ${dev_id_data}=  Get Device Info From BMC
    ${aux_info}=  Get From Dictionary  ${dev_id_data}  aux
    Run Keyword And Continue On Failure  Should Be Equal  ${aux_info}  ${auxiliary_rev_version}

    # Compare both IPMI version and /etc/os-release version
    Run Keyword And Continue On Failure  Should Be Equal  ${auxiliary_info}  ${auxiliary_rev_version}


*** Keywords ***

Reverse List And Return Integer
    [Documentation]  Gets the list of Hexa decimal data bytes,
    ...              Reverses the list and converts the HEX value to integer
    [Arguments]  ${list}

    ${rev_list}=  Reverse List  ${list}
    ${integer}=  Convert To Integer  ${rev_list}  16

    [Return]  ${integer}


Get BMC OS Release Details
    [Documentation]  To get the release details from bmc etc/os-release

    ${os_release}=  Get BMC Release Info
    ${os_release}=  Convert To Dictionary  ${os_release}

    [Return]  ${os_release}


Get Version Details From BMC OS Release
    [Documentation]  To get the Version details from bmc etc/os-release
    [Arguments]  ${os_release}

    ${version}=  Set Variable  ${os_release['version']}
    ${version}=  Split String  ${version}  .

    [Return]  ${version}


Get Auxiliary Firmware Revision Information
    [Documentation]  To Get the Auxiliary Firmware Revision Information form BMC etc/os-release
    
    # Get the Auxiliary Firmware Revision Information version from etc/os-release
    ${os_release}=  Get BMC OS Release Details

    # Fetch the version from dictionary response and identify Auxilliary version
    ${version}=  Get Version Details From BMC OS Release  ${os_release}
    ${aux_rev}=  Set Variable  ${version[2]}

    # Remove extra special character
    ${aux_rev}=  Replace String  ${aux_rev}  -  ${EMPTY}
    ${aux_rev}=  Convert To Integer  ${aux_rev}

    [Return]  ${aux_rev}


Get Device Info From BMC
    [Documentation]  To Get the Device Information form BMC 

    # Get Device ID informations from BMC
    ${data}=  Bmc Execute Command   cat /usr/share/ipmi-providers/dev_id.json
    ${data}=  Convert To List  ${data}

    # Fetching dictionary from the response
    ${info}=  Set Variable  ${data[0]}
    ${info}=  Evaluate  dict(${info})

    [Return]  ${info}
