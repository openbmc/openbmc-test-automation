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


Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             Collections
Library             ../lib/ipmi_utils.py
Library             ../lib/var_funcs.py
Variables           ../data/ipmi_raw_cmd_table.py

Test Tags           IPMI_Device_ID

*** Test Cases ***

Get Device ID Via IPMI
    [Documentation]  Verify Get Device ID using IPMI and check whether a response is received.
    [Tags]  Get_Device_ID_Via_IPMI

    # Verify Get Device ID.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Device ID']['Get'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Device ID']['Get'][1]}


Verify Get Device ID With Invalid Data Request
    [Documentation]  Verify Get Device ID with invalid data request via IPMI.
    [Tags]  Verify_Get_Device_ID_With_Invalid_Data_Request

    # Run IPMI Get Device ID command with invalid request data byte.
    ${resp}=  Run Keyword And Expect Error  *Request data length invalid*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]} 0x00
    # Verify error code in 'rsp='.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device ID']['Get'][2]}


Verify Device ID Response Data Via IPMI
    [Documentation]  Verify Get Device ID response data bytes using IPMI.
    [Tags]  Verify_Device_ID_Response_Data_Via_IPMI

    # Get Device ID IPMI command.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    # Split each and every byte and form list.
    ${resp}=  Split String  ${resp}

    # Checking Device ID.
    Run Keyword And Continue On Failure  Should Not Be Equal  ${resp[0]}  00
    ...  msg=Device ID cannot be Unspecified

    # Verify Device Revision.
    ${device_rev}=  Set Variable  ${resp[1]}
    ${device_rev}=  Convert To Binary  ${device_rev}  base=16
    ${device_rev}=  Zfill Data  ${device_rev}  8
    # Comparing the reserved bits from Device Revision.
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${device_rev[1:4]}  000

    # Get version details from /etc/os-release.
    ${os_release}=  Get BMC OS Release Details
    ${version}=  Get Bmc Major Minor Version  ${os_release['version']}

    # Verify Firmware Revision 1.
    ${firmware_rev1}=  Set Variable  ${version[0]}
    ${ipmi_rsp_firmware_rev1}=  Convert To Integer  ${resp[2]}  base=16
    Run Keyword And Continue On Failure  Should Be Equal As Integers
    ...  ${ipmi_rsp_firmware_rev1}  ${firmware_rev1}

    # Verify Firmware Revision 2.
    ${firmware_rev2}=  Set Variable  ${version[1]}
    ${ipmi_rsp_firmware_rev2}=  Convert To Integer  ${resp[3]}  base=16
    Run Keyword And Continue On Failure  Should Be Equal As Integers
    ...  ${ipmi_rsp_firmware_rev2}  ${firmware_rev2}

    # Verify IPMI Version.
    Run Keyword And Continue On Failure  Should Be Equal  ${resp[4]}  02

    # Verify Manufacture ID.
    ${manufacture_id}=  Set Variable  ${resp[6:9]}
    ${manufacture_id}=  Evaluate  "".join(${manufacture_id})
    ${manufacture_data}=  Convert To Binary  ${manufacture_id}  base=16
    # Manufacure ID has Most significant four bits - reserved (0000b)
    Run Keyword And Continue On Failure  Should Be Equal  ${manufacture_data[-5:-1]}  0000

    # Verify Product ID.
    ${product_id}=  Set Variable  ${resp[9:11]}
    ${product_id}=  Evaluate   "".join(${product_id})
    Run Keyword And Continue On Failure  Should Not Be Equal  ${product_id}  0000
    ...  msg=Product ID cannot be Zero

    # Get Auxiliary Firmware Revision Information from IPMI response.
    ${auxiliary_rev_version}=  Set Variable  ${resp[11:]}
    Reverse List  ${auxiliary_rev_version}
    ${auxiliary_rev_version}=  Evaluate  "".join(${auxiliary_rev_version})
    ${auxiliary_rev_version}=  Convert To Integer  ${auxiliary_rev_version}  16

    # Compare both IPMI aux version and dev_id.json aux version.
    ${dev_id_data}=  Get Device Info From BMC
    ${aux_info}=  Get From Dictionary  ${dev_id_data}  aux
    Run Keyword And Continue On Failure  Should Be Equal  ${aux_info}  ${auxiliary_rev_version}


*** Keywords ***

Get BMC OS Release Details
    [Documentation]  To get the release details from bmc etc/os-release.

    # The BMC OS Release information will be,
    # for example,
    # ID=openbmc-phosphor
    # NAME="ADCD EFG BMC (OpenBMC     Project Reference Distro)"
    # VERSION="2.9.1-2719"
    # VERSION_ID=2.9.1-2719-xxxxxxxx
    # PRETTY_NAME="ABCD EFG BMC (OpenBMC     Project Reference Distro) 2.9.1-2719"
    # BUILD_ID="xxxxxxxxxx"
    # OPENBMC_TARGET_MACHINE="efg"

    ${os_release}=  Get BMC Release Info
    ${os_release}=  Convert To Dictionary  ${os_release}

    RETURN  ${os_release}


Get Device Info From BMC
    [Documentation]  To get the device information from BMC.

    # Get Device ID information from BMC.
    ${data}=  Bmc Execute Command   cat /usr/share/ipmi-providers/dev_id.json
    ${data}=  Convert To List  ${data}

    # Fetching dictionary from the response.
    ${info}=  Set Variable  ${data[0]}
    ${info}=  Evaluate  dict(${info})

    RETURN  ${info}
