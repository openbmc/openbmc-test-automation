*** Settings ***
Documentation   This suite tests Platform Event Log (PEL) functionality of OpenBMC.

Library         ../../lib/pel_utils.py
Resource        ../../lib/openbmc_ffdc.robot

Test Setup      Redfish.Login
Test Teardown   Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail


*** Variables ***

${CMD_INTERNAL_FAILURE}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0


*** Test Cases ***

Create Test PEL Log And Verify
    [Documentation]  Create PEL log using busctl command and verify via peltool.
    [Tags]  Create_Test_PEL_Log_And_Verify

    Redfish Purge Event Log
    Create Test PEL Log
    ${pel_id}=  Get PEL Log Via BMC CLI
    Should Not Be Empty  ${pel_id}  msg=System PEL log entry is empty.


Verify PEL Log Persistence After BMC Reboot
    [Documentation]  Verify PEL log persistence after BMC reboot.
    [Tags]  Verify_PEL_Log_Persistence_After_BMC_Reboot

    Create Test PEL Log
    ${pel_before_reboot}=  Get PEL Log Via BMC CLI

    Redfish OBMC Reboot (off)
    ${pel_after_reboot}=  Get PEL Log Via BMC CLI

    List Should Contain Sub List  ${pel_after_reboot}  ${pel_before_reboot}


Verify PEL ID Numbering
    [Documentation]  Verify PEL ID numbering.
    [Tags]  Verify_PEL_ID_Numbering

    Redfish Purge Event Log
    Create Test PEL Log
    Create Test PEL Log

    # pel_records:
    #  [0x50000012]:             <--- First PEL ID
    #    [CreatorID]:                  BMC
    #    [CompID]:                     0x1000
    #    [PLID]:                       0x50000012
    #    [Subsystem]:                  BMC Firmware
    #    [Message]:                    An application had an internal failure
    #    [SRC]:                        BD8D1002
    #    [Commit Time]:                03/02/2020  09:35:15
    #    [Sev]:                        Unrecoverable Error
    #
    #  [0x50000013]:             <--- Second PEL ID
    #    [CreatorID]:                  BMC
    #    [CompID]:                     0x1000
    #    [PLID]:                       0x50000012
    #    [Subsystem]:                  BMC Firmware
    #    [Message]:                    An application had an internal failure
    #    [SRC]:                        BD8D1002
    #    [Commit Time]:                03/02/2020  09:35:15
    #    [Sev]:                        Unrecoverable Error

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${first_pel_id}=  Get From List  ${pel_ids}  0
    ${second_pel_id}=  Get From List  ${pel_ids}  1
    Should Be True  ${first_pel_id}+1 == ${second_pel_id}


*** Keywords ***

Create Test PEL Log
    [Documentation]  Generate test PEL log.

    # Test PEL log entry example:
    # {
    #    "0x5000002D": {
    #            "SRC": "BD8D1002",
    #            "Message": "An application had an internal failure",
    #            "PLID": "0x5000002D",
    #            "CreatorID": "BMC",
    #            "Subsystem": "BMC Firmware",
    #            "Commit Time": "02/25/2020  04:47:09",
    #            "Sev": "Unrecoverable Error",
    #            "CompID": "0x1000"
    #    }
    # }

    BMC Execute Command  ${CMD_INTERNAL_FAILURE}


Get PEL Log Via BMC CLI
    [Documentation]  Returns the list of PEL IDs using BMC CLI.

    ${pel_records}=  Peltool  -l
    ${ids}=  Get Dictionary Keys  ${pel_records}

    [Return]  ${ids}
