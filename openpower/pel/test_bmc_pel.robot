*** Settings ***
Documentation   This suite tests Platform Event Log (PEL) functionality of OpenBMC.

Library         ../../lib/pel_utils.py
Variables       ../../data/pel_variables.py
Resource        ../../lib/list_utils.robot
Resource        ../../lib/logging_utils.robot
Resource        ../../lib/openbmc_ffdc.robot

Test Setup      Redfish.Login
Test Teardown   Run Keywords  Redfish.Logout  AND  FFDC On Test Case Fail


*** Variables ***

${CMD_INTERNAL_FAILURE}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

${CMD_FRU_CALLOUT}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.Timeout
...  xyz.openbmc_project.Logging.Entry.Level.Error 2 "TIMEOUT_IN_MSEC" "5"
...  "CALLOUT_INVENTORY_PATH" "/xyz/openbmc_project/inventory/system/chassis/motherboard"

${CMD_PROCEDURAL_SYMBOLIC_FRU_CALLOUT}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} org.open_power.Logging.Error.TestError1
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

${CMD_INFORMATIONAL_ERROR}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.TestError2
...  xyz.openbmc_project.Logging.Entry.Level.Informational 0

${CMD_INVENTORY_PREFIX}  busctl get-property xyz.openbmc_project.Inventory.Manager
...  /xyz/openbmc_project/inventory/system/chassis/motherboard

@{mandatory_pel_fileds}   Private Header  User Header  Primary SRC  Extended User Header  Failing MTMS


*** Test Cases ***

Create Test PEL Log And Verify
    [Documentation]  Create PEL log using busctl command and verify via peltool.
    [Tags]  Create_Test_PEL_Log_And_Verify

    Redfish Purge Event Log
    Create Test PEL Log
    ${pel_id}=  Get PEL Log Via BMC CLI
    Should Not Be Empty  ${pel_id}  msg=System PEL log entry is empty.


Verify PEL Log Details
    [Documentation]  Verify PEL log details via peltool.
    [Tags]  Verify_PEL_Log_Details

    Redfish Purge Event Log

    ${bmc_time1}=  CLI Get BMC DateTime
    Create Test PEL Log
    ${bmc_time2}=  CLI Get BMC DateTime

    ${pel_records}=  Peltool  -l

    # Example output from 'Peltool  -l':
    # pel_records:
    # [0x50000012]:
    #   [CreatorID]:                  BMC
    #   [CompID]:                     0x1000
    #   [PLID]:                       0x50000012
    #   [Subsystem]:                  BMC Firmware
    #   [Message]:                    An application had an internal failure
    #   [SRC]:                        BD8D1002
    #   [Commit Time]:                03/02/2020  09:35:15
    #   [Sev]:                        Unrecoverable Error

    ${ids}=  Get Dictionary Keys  ${pel_records}
    ${id}=  Get From List  ${ids}  0

    @{pel_fields}=  Create List  CreatorID  Subsystem  Message  Sev
    FOR  ${field}  IN  @{pel_fields}
      Valid Value  pel_records['${id}']['${field}']  ['${PEL_DETAILS['${field}']}']
    END

    Valid Value  pel_records['${id}']['PLID']  ['${id}']

    # Verify if "CompID" and "SRC" fields of PEL has alphanumeric value.
    Should Match Regexp  ${pel_records['${id}']['CompID']}  [a-zA-Z0-9]
    Should Match Regexp  ${pel_records['${id}']['SRC']}  [a-zA-Z0-9]

    ${pel_date_time}=  Convert Date  ${pel_records['${id}']['Commit Time']}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=yes

    # Convert BMC and PEL time to epoch time before comparing.
    ${bmc_time1_epoch}=  Convert Date  ${bmc_time1}  epoch
    ${pel_time_epoch}=  Convert Date  ${pel_date_time}  epoch
    ${bmc_time2_epoch}=  Convert Date  ${bmc_time2}  epoch

    Should Be True  ${bmc_time1_epoch} <= ${pel_time_epoch} <= ${bmc_time2_epoch}


Verify Mandatory Sections Of Error Log PEL
    [Documentation]  Verify mandatory sections of error log PEL.
    [Tags]  Verify_Mandatory_Sections_Of_Error_Log_PEL

    Create Test PEL Log

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${pel_id}=  Get From List  ${pel_ids}  -1
    ${pel_output}=  Peltool  -i ${pel_id}
    ${pel_sections}=  Get Dictionary Keys  ${pel_output}

    List Should Contain Sub List  ${pel_sections}  ${mandatory_pel_fileds}


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

    ${pel_ids}=  Get PEL Log Via BMC CLI

    # Example of PEL IDs from PEL logs.
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
    #    [PLID]:                       0x50000013
    #    [Subsystem]:                  BMC Firmware
    #    [Message]:                    An application had an internal failure
    #    [SRC]:                        BD8D1002
    #    [Commit Time]:                03/02/2020  09:35:15
    #    [Sev]:                        Unrecoverable Error

    Should Be True  ${pel_ids[1]} == ${pel_ids[0]}+1

Verify Machine Type Model And Serial Number
    [Documentation]  Verify machine type model and serial number from PEL.
    [Tags]  Verify_Machine_Type_Model_And_Serial_Number

    Create Test PEL Log

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${id}=  Get From List  ${pel_ids}  -1

    ${pel_serial_number}=  Get PEL Field Value  ${id}  Failing MTMS  Serial Number
    ${pel_serial_number}=  Replace String Using Regexp  ${pel_serial_number}  ^0+  ${EMPTY}
    ${pel_machine_type_model}=  Get PEL Field Value  ${id}  Failing MTMS  Machine Type Model
    ${pel_machine_type_model}=  Replace String Using Regexp  ${pel_machine_type_model}  ^0+  ${EMPTY}

    # Example of "Machine Type Model" and "Serial Number" fields value from "Failing MTMS" section of PEL.
    #  [Failing MTMS]:
    #    [Created by]:                                 0x2000
    #    [Machine Type Model]:                         1234-ABC   <---- Machine type
    #    [Section Version]:                            1
    #    [Serial Number]:                              ABCDEFG    <---- Serial number
    #    [Sub-section type]:                           0

    ${redfish_machine_model}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  Model
    ${redfish_machine_model}=  Replace String Using Regexp  ${redfish_machine_model}  ^0+  ${EMPTY}
    ${redfish_serial_number}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  SerialNumber
    ${redfish_serial_number}=  Replace String Using Regexp  ${redfish_serial_number}  ^0+  ${EMPTY}

    Valid Value  pel_machine_type_model  ['${redfish_machine_model}']
    Valid Value  pel_serial_number  ['${redfish_serial_number}']

    # Check "Machine Type Model" and "Serial Number" fields value from "Extended User Header" section of PEL.
    ${pel_machine_type_model}=  Get PEL Field Value  ${id}  Extended User Header  Reporting Machine Type
    ${pel_machine_type_model}=  Replace String Using Regexp  ${pel_machine_type_model}  ^0+  ${EMPTY}
    ${pel_serial_number}=  Get PEL Field Value  ${id}  Extended User Header  Reporting Serial Number
    ${pel_serial_number}=  Replace String Using Regexp  ${pel_serial_number}  ^0+  ${EMPTY}

    Valid Value  pel_machine_type_model  ['${redfish_machine_model}']
    Valid Value  pel_serial_number  ['${redfish_serial_number}']


Verify Host Off State From PEL
    [Documentation]  Verify Host off state from PEL.
    [Tags]  Verify_Host_Off_State_From_PEL

    Redfish Power Off  stack_mode=skip
    Create Test PEL Log

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${id}=  Get From List  ${pel_ids}  -1
    ${pel_host_state}=  Get PEL Field Value  ${id}  User Data  HostState

    Valid Value  pel_host_state  ['Off']


Verify BMC Version From PEL
    [Documentation]  Verify BMC Version from PEL.
    [Tags]  Verify_BMC_Version_From_PEL

    Create Test PEL Log

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${id}=  Get From List  ${pel_ids}  -1
    ${pel_bmc_version}=  Get PEL Field Value  ${id}  User Data  BMC Version ID

    ${bmc_version}=  Get BMC Version
    Valid Value  bmc_version  ['${bmc_version}']


Verify PEL Log After Host Poweron
    [Documentation]  Verify PEL log generation while booting host.
    [Tags]  Verify_PEL_Log_After_Host_Poweron

    Redfish Power Off  stack_mode=skip
    Redfish Purge Event Log
    Redfish Power On  stack_mode=skip

    ${pel_informational_error}=  Get PEL Log IDs  User Header  Event Severity  Informational Event
    ${pel_bmc_created_error}=  Get PEL Log IDs  Private Header  Creator Subsystem  BMC

    # Get BMC created non-infomational error.
    ${pel_bmc_error}=  Subtract Lists  ${pel_bmc_created_error}  ${pel_informational_error}

    Should Be Empty  ${pel_bmc_error}  msg=Unexpected error log generated during Host poweron.


Verify BMC Event Log ID
    [Documentation]  Verify BMC Event Log ID from PEL.
    [Tags]  Verify_BMC_Event_Log_ID

    Redfish Purge Event Log
    Create Test PEL Log

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${pel_bmc_event_log_id}=  Get PEL Field Value  ${pel_ids[0]}  Private Header  BMC Event Log Id

    # Example "BMC Event Log Id" field value from "Private Header" section of PEL.
    #  [Private Header]:
    #    [Created at]:                 08/24/1928 12:04:06
    #    [Created by]:                 0x584D
    #    [Sub-section type]:           0
    #    [Entry Id]:                   0x50000BB7
    #    [Platform Log Id]:            0x8200061D
    #    [CSSVER]:
    #    [Section Version]:            1
    #    [Creator Subsystem]:          PHYP
    #    [BMC Event Log Id]:           341      <---- BMC event log id value
    #    [Committed at]:               03/25/1920 12:06:22

    ${redfish_event_logs}=  Redfish.Get Properties  /redfish/v1/Systems/system/LogServices/EventLog/Entries

    # Example of redfish_event_logs output:
    # redfish_event_logs:
    #  [@odata.id]:                    /redfish/v1/Systems/system/LogServices/EventLog/Entries
    #  [Name]:                         System Event Log Entries
    #  [Members@odata.count]:          1
    #  [@odata.type]:                  #LogEntryCollection.LogEntryCollection
    #  [Description]:                  Collection of System Event Log Entries
    #  [Members]:
    #    [0]:
    #      [@odata.id]:                /redfish/v1/Systems/system/LogServices/EventLog/Entries/235
    #      [Name]:                     System Event Log Entry
    #      [Severity]:                 Critical
    #      [EntryType]:                Event
    #      [Created]:                  2020-04-02T07:25:13+00:00
    #      [@odata.type]:              #LogEntry.v1_5_1.LogEntry
    #      [Id]:                       235          <----- Event log ID
    #      [Message]:                  xyz.openbmc_project.Common.Error.InternalFailure

    Valid Value  pel_bmc_event_log_id  ['${redfish_event_logs['Members'][0]['Id']}']


Verify FRU Callout
    [Documentation]  Verify FRU callout entries from PEL log.
    [Tags]  Verify_FRU_Callout

    Create Test PEL Log  FRU Callout

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${id}=  Get From List  ${pel_ids}  -1
    ${pel_callout_section}=  Get PEL Field Value  ${id}  Primary SRC  Callout Section

    # Example of PEL Callout Section from "peltool -i <id>" command.
    #  [Callouts]:
    #    [0]:
    #      [FRU Type]:                 Normal Hardware FRU
    #      [Priority]:                 Mandatory, replace all with this type as a unit
    #      [Location Code]:            U78DA.ND1.1234567-P0
    #      [Part Number]:              F191014
    #      [CCIN]:                     2E2D
    #      [Serial Number]:            YL2E2D010000
    #  [Callout Count]:                1

    Valid Value  pel_callout_section['Callout Count']  ['1']
    Valid Value  pel_callout_section['Callouts'][0]['FRU Type']  ['Normal Hardware FRU']
    Should Contain  ${pel_callout_section['Callouts'][0]['Priority']}  Mandatory

    # Verify Location Code field of PEL callout with motherboard's Location Code.
    ${busctl_output}=  BMC Execute Command  ${CMD_INVENTORY_PREFIX} com.ibm.ipzvpd.Location LocationCode
    Should Be Equal  ${pel_callout_section['Callouts'][0]['Location Code']}
    ...  ${busctl_output[0].split('"')[1].strip('"')}

    # TODO: Compare CCIN and part number fields of PEL callout with Redfish or busctl output.
    Should Match Regexp  ${pel_callout_section['Callouts'][0]['CCIN']}  [a-zA-Z0-9]
    Should Match Regexp  ${pel_callout_section['Callouts'][0]['Part Number']}  [a-zA-Z0-9]

    # Verify Serial Number field of PEL callout with motherboard's Serial Number.
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX} xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber
    Should Be Equal  ${pel_callout_section['Callouts'][0]['Serial Number']}
    ...  ${busctl_output[0].split('"')[1].strip('"')}


Verify Procedure And Symbolic FRU Callout
    [Documentation]  Verify procedure and symbolic FRU callout from PEL log.
    [Tags]  Verify_Procedure_And_Symbolic_FRU_Callout

    Create Test PEL Log   Procedure And Symbolic FRU Callout

    ${pel_ids}=  Get PEL Log Via BMC CLI
    ${id}=  Get From List  ${pel_ids}  -1
    ${pel_callout_section}=  Get PEL Field Value  ${id}  Primary SRC  Callout Section

    # Example of PEL Callout Section from "peltool -i <id>" command.
    #  [Callouts]:
    #    [0]:
    #      [Priority]:                                 Mandatory, replace all with this type as a unit
    #      [Procedure Number]:                         BMCSP02
    #      [FRU Type]:                                 Maintenance Procedure Required
    #    [1]:
    #      [Priority]:                                 Medium Priority
    #      [Part Number]:                              SVCDOCS
    #      [FRU Type]:                                 Symbolic FRU
    #  [Callout Count]:                                2

    Valid Value  pel_callout_section['Callout Count']  ['2']

    # Verify procedural callout info.

    Valid Value  pel_callout_section['Callouts'][0]['FRU Type']  ['Maintenance Procedure Required']
    Should Contain  ${pel_callout_section['Callouts'][0]['Priority']}  Mandatory
    # Verify if "Procedure Number" field of PEL has an alphanumeric value.
    Should Match Regexp  ${pel_callout_section['Callouts'][0]['Procedure Number']}  [a-zA-Z0-9]

    # Verify procedural callout info.

    Valid Value  pel_callout_section['Callouts'][1]['FRU Type']  ['Symbolic FRU']
    Should Contain  ${pel_callout_section['Callouts'][1]['Priority']}  Medium Priority
    # Verify if "Part Number" field of Symbolic FRU has an alphanumeric value.
    Should Match Regexp  ${pel_callout_section['Callouts'][1]['Part Number']}  [a-zA-Z0-9]


Verify PEL Log Entry For Event Log
    [Documentation]  Create an event log and verify PEL log entry in BMC for the same.
    [Tags]  Verify_PEL_Log_Entry_For_Event_Log

    Redfish Purge Event Log
    # Create an internal failure error log.
    BMC Execute Command  ${CMD_INTERNAL_FAILURE}

    ${elog_entry}=  Get Event Logs
    # Example of Redfish event logs:
    # elog_entry:
    #  [0]:
    #    [Message]:                                    xyz.openbmc_project.Common.Error.InternalFailure
    #    [Created]:                                    2020-04-20T01:55:22+00:00
    #    [Id]:                                         1
    #    [@odata.id]:                                  /redfish/v1/Systems/system/LogServices/EventLog/Entries/1
    #    [@odata.type]:                                #LogEntry.v1_4_0.LogEntry
    #    [EntryType]:                                  Event
    #    [Severity]:                                   Critical
    #    [Name]:                                       System Event Log Entry

    ${redfish_log_time}=  Convert Date  ${elog_entry[0]["Created"]}  epoch

    ${pel_records}=  Peltool  -l
    # Example output from 'Peltool  -l':
    # pel_records:
    # [0x50000023]:
    #   [SRC]:                                        BD8D1002
    #   [CreatorID]:                                  BMC
    #   [Message]:                                    An application had an internal failure
    #   [CompID]:                                     0x1000
    #   [PLID]:                                       0x50000023
    #   [Commit Time]:                                04/20/2020 01:55:22
    #   [Subsystem]:                                  BMC Firmware
    #   [Sev]:                                        Unrecoverable Error

    ${ids}=  Get Dictionary Keys  ${pel_records}
    ${id}=  Get From List  ${ids}  0
    ${pel_log_time}=  Convert Date  ${pel_records['${id}']['Commit Time']}  epoch
    ...  date_format=%m/%d/%Y %H:%M:%S

    # Verify that both Redfish event and PEL has log entry for internal error with same time stamp.
    Should Contain Any  ${pel_records['${id}']['Message']}  internal failure  ignore_case=True
    Should Contain Any  ${elog_entry[0]['Message']}  InternalFailure  ignore_case=True

    Should Be Equal  ${redfish_log_time}  ${pel_log_time}


Verify Delete All PEL
    [Documentation]  Verify deleting all PEL logs.
    [Tags]  Verify_Delete_All_PEL

    Create Test PEL Log
    Create Test PEL Log
    Peltool  --delete-all  False

    ${pel_ids}=  Get PEL Log Via BMC CLI
    Should Be Empty  ${pel_ids}


Verify Informational Error Log
    [Documentation]  Create an informational error log and verify.
    [Tags]  Verify_Informational_Error_Log

    Redfish Purge Event Log
    # Create an informational error log.
    BMC Execute Command  ${CMD_INFORMATIONAL_ERROR}
    ${pel_records}=  Peltool  -lfh

    # An example of information error log data:
    # {
    #    "0x500006A0": {
    #            "SRC": "BD8D1002",
    #            "Message": "An application had an internal failure",
    #            "PLID": "0x500006A0",
    #            "CreatorID": "BMC",
    #            "Subsystem": "BMC Firmware",
    #            "Commit Time": "10/14/2020 11:41:38",
    #            "Sev": "Informational Event",
    #            "CompID": "0x1000"
    #    }
    # }

    ${ids}=  Get Dictionary Keys  ${pel_records}
    ${id}=  Get From List  ${ids}  0
    Should Contain  ${pel_records['${id}']['Sev']}  Informational


*** Keywords ***

Create Test PEL Log
    [Documentation]  Generate test PEL log.
    [Arguments]  ${pel_type}=Internal Failure

    # Description of argument(s):
    # pel_type      The PEL type (e.g. Internal Failure, FRU Callout, Procedural Callout).

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

    Run Keyword If  '${pel_type}' == 'Internal Failure'
    ...   BMC Execute Command  ${CMD_INTERNAL_FAILURE}
    ...  ELSE IF  '${pel_type}' == 'FRU Callout'
    ...   BMC Execute Command  ${CMD_FRU_CALLOUT}
    ...  ELSE IF  '${pel_type}' == 'Procedure And Symbolic FRU Callout'
    ...   BMC Execute Command  ${CMD_PROCEDURAL_SYMBOLIC_FRU_CALLOUT}


Get PEL Log IDs
    [Documentation]  Returns the list of PEL log IDs which contains given field's value.
    [Arguments]  ${pel_section}  ${pel_field}  @{pel_field_value}

    # Description of argument(s):
    # pel_section      The section of PEL (e.g. Private Header, User Header).
    # pel_field        The PEL field (e.g. Event Severity, Event Type).
    # pel_field_value  The list of PEL's field value (e.g. Unrecoverable Error).

    ${pel_ids}=  Get PEL Log Via BMC CLI
    @{pel_id_list}=  Create List

    FOR  ${id}  IN  @{pel_ids}
      ${pel_output}=  Peltool  -i ${id}
      # Example of PEL output from "peltool -i <id>" command.
      #  [Private Header]:
      #    [Created at]:                                 08/24/1928 12:04:06
      #    [Created by]:                                 0x584D
      #    [Sub-section type]:                           0
      #    [Entry Id]:                                   0x50000BB7
      #    [Platform Log Id]:                            0x8200061D
      #    [CSSVER]:
      #    [Section Version]:                            1
      #    [Creator Subsystem]:                          PHYP
      #    [BMC Event Log Id]:                           341
      #    [Committed at]:                               03/25/1920 12:06:22
      #  [User Header]:
      #    [Log Committed by]:                           0x4552
      #    [Action Flags]:
      #      [0]:                                        Report Externally
      #    [Subsystem]:                                  I/O Subsystem
      #    [Event Type]:                                 Miscellaneous, Informational Only
      #    [Sub-section type]:                           0
      #    [Event Scope]:                                Entire Platform
      #    [Event Severity]:                             Informational Event
      #    [Host Transmission]:                          Not Sent
      #    [Section Version]:                            1

      ${pel_section_output}=  Get From Dictionary  ${pel_output}  ${pel_section}
      ${pel_field_output}=  Get From Dictionary  ${pel_section_output}  ${pel_field}
      Run Keyword If  '${pel_field_output}' in @{pel_field_value}  Append To List  ${pel_id_list}  ${id}
    END
    Sort List  ${pel_id_list}

    [Return]  ${pel_id_list}


Get PEL Log Via BMC CLI
    [Documentation]  Returns the list of PEL IDs using BMC CLI.

    ${pel_records}=  Peltool  -l
    ${ids}=  Get Dictionary Keys  ${pel_records}
    Sort List  ${ids}

    [Return]  ${ids}


Get PEL Field Value
    [Documentation]  Returns the value of given PEL's field.
    [Arguments]  ${pel_id}  ${pel_section}  ${pel_field}

    # Description of argument(s):
    # pel_id           The ID of PEL (e.g. 0x5000002D, 0x5000002E).
    # pel_section      The section of PEL (e.g. Private Header, User Header)
    # pel_field        The PEL field (e.g. Event Severity, Event Type).

    ${pel_output}=  Peltool  -i ${pel_id}

    # Example of PEL output from "peltool -i <id>" command.
    #  [Private Header]:
    #    [Created at]:                                 08/24/1928 12:04:06
    #    [Created by]:                                 0x584D
    #    [Sub-section type]:                           0
    #    [Entry Id]:                                   0x50000BB7
    #    [Platform Log Id]:                            0x8200061D
    #    [CSSVER]:
    #    [Section Version]:                            1
    #    [Creator Subsystem]:                          PHYP
    #    [BMC Event Log Id]:                           341
    #    [Committed at]:                               03/25/1920 12:06:22
    #  [User Header]:
    #    [Log Committed by]:                           0x4552
    #    [Action Flags]:
    #      [0]:                                        Report Externally
    #    [Subsystem]:                                  I/O Subsystem
    #    [Event Type]:                                 Miscellaneous, Informational Only
    #    [Sub-section type]:                           0
    #    [Event Scope]:                                Entire Platform
    #    [Event Severity]:                             Informational Event
    #    [Host Transmission]:                          Not Sent
    #    [Section Version]:                            1

    ${pel_section_output}=  Get From Dictionary  ${pel_output}  ${pel_section}
    ${pel_field_output}=  Get From Dictionary  ${pel_section_output}  ${pel_field}

    [Return]  ${pel_field_output}
