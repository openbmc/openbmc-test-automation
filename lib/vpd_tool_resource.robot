*** Settings ***
Documentation   Utility file for system Vital Product Data (VPD) using vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py
Resource        ../../lib/boot_utils.robot


*** Variables ***

${DR_WRITE_VALUE}              XYZ Component
${PN_WRITE_VALUE}              XYZ1234
${SN_WRITE_VALUE}              ABCD12345678
@{fields}                      PN  SN  LocationCode
@{vpd_fields}                  PN  SN


*** Keywords ***

Verify VPD Component Read Operation
    [Documentation]  Verify reading VPD details of given component via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${vpd_records}=  Vpdtool  -o -O ${component}

    # Example output from 'Vpdtool  -o -O /system/chassis/motherboard/vdd_vrm1':
    #  [/system/chassis/motherboard/vdd_vrm1]:
    #    [DR]:                                         CPU POWER CARD
    #    [type]:                                       xyz.openbmc_project.Inventory.Item.Vrm
    #    [CC]:                                         E123
    #    [FN]:                                         F123456
    #    [LocationCode]:                               ABCD.XY1.1234567-P0
    #    [SN]:                                         YL2E32010000
    #    [PN]:                                         PN12345

    ${vpdtool_res}=  Set To Dictionary  ${vpd_records}[${component}]
    FOR  ${vpd_field}  IN  @{fields}
        ${match_key_exists}=  Run Keyword And Return Status
        ...  Dictionary Should Contain Key  ${vpdtool_res}  ${vpd_field}
          IF  '${match_key_exists}' == 'True'
              #  drive components busctl field response in ascii due to that checking only locationcode.
              IF  'drive' in '${component}'
                  ${vpd_field}=  Set Variable  LocationCode
              END
              # Skip check if VPD field is empty.
              IF  '${vpd_records['${component}']['${vpd_field}']}' == ''  CONTINUE

              # Get VPD field values via busctl.
              ${busctl_field}=  Set Variable If
              ...  '${vpd_field}' == 'LocationCode'  com.ibm.ipzvpd.Location LocationCode
              ...  '${vpd_field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
              ...  '${vpd_field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber
              ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY}
              ...  /xyz/openbmc_project/inventory${component} ${busctl_field}
              ${cmd_output}=  BMC Execute Command  ${cmd}
              # Check whether the vpdtool response and busctl response matching.
              Valid Value  vpd_records['${component}']['${vpd_field}']
              ...  ['${cmd_output[0].split('"')[1].strip('"')}']
          ELSE
             CONTINUE
          END
    END


Verify VPD Field Read Operation
    [Documentation]  Verify reading all VPD fields for given component via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${vpd_records}=  Vpdtool  -o -O ${component}
    ${vpdtool_res}=  Set To Dictionary  ${vpd_records}[${component}]
    FOR  ${field}  IN  @{vpd_fields}
         ${match_key_exists}=  Run Keyword And Return Status
         ...  Dictionary Should Contain Key  ${vpdtool_res}  ${field}
         IF  '${match_key_exists}' == 'True'
             ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}
             # Skip check if field value is empty.
             IF  '${vpd_records['${component}']['${field}']}' == ''  CONTINUE

             ${busctl_field}=  Set Variable If
             ...  '${field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
             ...  '${field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber
             ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY}
             ...  /xyz/openbmc_project/inventory${component} ${busctl_field}
             ${cmd_output}=  BMC Execute Command  ${cmd}

             # Check vpdtool response and busctl response for the component field.
             Valid Value  vpd_records['${component}']['${field}']
             ...  ['${cmd_output[0].split('"')[1].strip('"')}']
         ELSE
            CONTINUE
         END
    END


Verify VPD Field Write Operation
    [Documentation]  Verify writing VPD fields for given component via vpdtool.
    [Arguments]  ${component}  ${field}
    [Teardown]  Restore VPD Value  ${component}  ${field}  ${old_field_value}

    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD component field (e.g. PN, SN)

    ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}
    Set Test Variable  ${old_field_value}  ${vpd_records['${component}']['${field}']}

    ${write_value}=  Set Variable If
    ...  '${field}' == 'DR'  ${DR_WRITE_VALUE}
    ...  '${field}' == 'PN'  ${PN_WRITE_VALUE}
    ...  '${field}' == 'SN'  ${SN_WRITE_VALUE}

    Vpdtool  -w -O ${component} -R VINI -K ${field} --value ${write_value}

    Verify VPD Field Value  ${component}  ${field}


Restore VPD Value
    [Documentation]  Restore VPD's field value of given component.
    [Arguments]  ${component}  ${field}  ${value}
    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD component field (e.g. PN, SN)
    # value           VPD value to be restore.

    Vpdtool  -w -O ${component} -R VINI -K ${field} --value ${value}


Verify VPD Field Value
    [Documentation]  Verify VPD field value via vpdtool.
    [Arguments]  ${component}  ${field}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD field (e.g. DR, SN, PN)

    Redfish OBMC Reboot (off)  stack_mode=normal
    ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}

    ${busctl_field}=  Set Variable If
    ...  '${field}' == 'DR'  xyz.openbmc_project.Inventory.Item PrettyName
    ...  '${field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
    ...  '${field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber

    ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY} /xyz/openbmc_project/inventory${component}
    ...  ${busctl_field}
    ${cmd_output}=  BMC Execute Command  ${cmd}

    Valid Value  vpd_records['${component}']['${field}']  ['${cmd_output[0].split('"')[1].strip('"')}']


Verify VPD Data Via Vpdtool
    [Documentation]  Get VPD details of given component via vpdtool and verify it
    ...              using busctl command.
    [Arguments]  ${component}  ${field}
    # Description of arguments:
    # component       VPD component (e.g. System,Chassis etc).
    # field           VPD field (e.g. Serialnumber,LocationCode etc).

    ${component_url}=  Set Variable If
    ...  '${component}' == 'System'  /system

    # Get VPD details of given component via vpd-tool.
    ${vpd_records}=  Vpdtool  -o -O ${component_url}

    # Get VPD details of given component via busctl command.
    ${busctl_field}=  Set Variable If
    ...  '${field}' == 'LocationCode'  com.ibm.ipzvpd.Location LocationCode
    ...  '${field}' == 'Model'  xyz.openbmc_project.Inventory.Decorator.Asset Model
    ...  '${field}' == 'SerialNumber'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber

    ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY} /xyz/openbmc_project/inventory/system
    ...  ${busctl_field}
    ${cmd_output}=  BMC Execute Command  ${cmd}
    # Example of cmd_output:
    #   [0]:                                            s "ABCD.XY1.1234567-P0"
    #   [1]:
    #   [2]:                                            0

    # Cross check vpdtool output with busctl response.
    Should Be Equal As Strings  ${vpd_records["/system"]["${field}"]}
    ...  ${cmd_output[0].split('"')[1].strip('"')}
