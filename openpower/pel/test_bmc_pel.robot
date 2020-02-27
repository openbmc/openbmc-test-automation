*** Settings ***
Documentation   This suite tests Platform Event Log (PEL) functionality of OpenBMC.

Library         ../../lib/pel_utils.py
Resource        ../../lib/openbmc_ffdc.robot

Test Setup      Run Keywords  Redfish.Login  AND  Redfish Purge Event Log
Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_INTERNAL_FAILURE}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0


*** Test Cases ***

Create Test PEL Log And Verify
    [Documentation]  Create PEL log using busctl command and verify via peltool.
    [Tags]  Create_Test_PEL_Log_And_Verify

    Create Test PEL Log
    PEL Log Should Exist


Verify PEL Log Details
    [Documentation]  Verify PEL log details via peltool.
    [Tags]  Verify_PEL_Log_Details

    Redfish Purge Event Log
    Create Test PEL Log
    ${pel_id}=  Get PEL Log Via BMC CLI
    ${pel_details}=  Get PEL Log Details  ${pel_id}

    Valid Value  pel_details[SRC]  BD8D1002
    Valid Value  pel_details[Message]  An application had an internal failure
    Valid Value  pel_details[CreatorID]  BMC
    Valid Value  pel_details[Subsystem]  BMC Firmware
    Valid Value  pel_details[Sev]  Unrecoverable Error
    Valid Value  pel_details[CompID]  0x1000


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


PEL Log Should Exist
    [Documentation]  PEL log entries should exist.

    ${pel_records}=  Peltool  -l
    Should Not Be Empty  ${pel_records}  msg=System PEL log entry is not empty.


Get PEL Log Details
    [Documentation]  Return details regarding given PEL id.

    ${pel_records}=  Peltool  -l
    ${output}=  Get Dictionary Values  ${pel_id}

    [Return]  ${output}
