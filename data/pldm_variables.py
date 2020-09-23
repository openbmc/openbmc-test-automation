#!/usr/bin/python

r"""
Contains PLDM-related constants.
"""

PLDM_SUPPORTED_TYPES = ['base', 'platform', 'bios', 'fru', 'oem-ibm']

# PLDM types.
PLDM_TYPE_BASE = {'VALUE': '00', 'STRING': 'base'}
PLDM_TYPE_PLATFORM = {'VALUE': '02', 'STRING': 'platform'}
PLDM_TYPE_BIOS = {'VALUE': '03', 'STRING': 'bios'}
PLDM_TYPE_FRU = {'VALUE': '04', 'STRING': 'fru'}
PLDM_TYPE_OEM = {'VALUE': '63', 'STRING': 'oem-ibm'}

VERSION_BASE = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}
VERSION_PLATFORM = {'VALUE': ['f1', 'f2', 'f0', '00'], 'STRING': '1.2.0'}
VERSION_BIOS = {'VALUE': ['f1', 'f1', 'f1', '00'], 'STRING': '1.0.0'}
VERSION_FRU = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}
VERSION_OEM = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}


PLDM_BASE_CMDS = ['2(GetTID)', '3(GetPLDMVersion)', '4(GetPLDMTypes)', '5(GetPLDMCommands)']
PLDM_PLATFORM_CMDS = ['57(SetStateEffecterStates)', '81(GetPDR)']
PLDM_BIOS_CMDS = ['1(GetBIOSTable)', '7(SetBIOSAttributeCurrentValue)',
                  '8(GetBIOSAttributeCurrentValueByHandle)', '12(GetDateTime)',
                  '13(SetDateTime)']
PLDM_FRU_CMDS = ['1(GetFRURecordTableMetadata)', '2(GetFRURecordTable)', '4(GetFRURecordByOption)']
PLDM_OEM_CMDS = ['1(GetFileTable)', '4(ReadFile)', '5(WriteFile)', '6(ReadFileInToMemory)',
                 '7(WriteFileFromMemory)', '8(ReadFileByTypeIntoMemory)',
                 '9(WriteFileByTypeFromMemory)', '10(NewFileAvailable)',
                 '11(ReadFileByType)', '12(WriteFileByType)', '13(FileAck)',
                 '240(GetAlertStatus)']

# PLDM command format.

'''
e.g. : GetPLDMVersion usage

pldmtool base GetPLDMVersion -t <pldm_type>

pldm supported types

base->0,platform->2,bios->3,fru->4

'''
CMD_GETPLDMVERSION = 'base GetPLDMVersion -t %s'

'''
e.g. : PLDM raw command usage

pldmtool raw -d 0x80 0x00 0x03 0x00 0x00 0x00 0x00 0x01 0x00

pldm raw -d 0x<header> 0x<pldm_type> 0x<pldm_cmd_type> 0x<payload_data>
'''

CMD_PLDMTOOL_RAW = 'raw -d 0x80' + '0x%s' + ' ' + '0x%s'


# PLDM command payload data.

PAYLOAD_GetPLDMVersion = \
    ' 0x00 0x00 0x00 0x00 0x%s 0x%s'    # %(TransferOperationFlag, PLDMType)


'''
e.g. : SetDateTime usage

pldmtool bios SetDateTime -d <YYYYMMDDHHMMSS>

'''
CMD_SETDATETIME = 'bios SetDateTime -d %s'


CMD_GETPDR = 'platform GetPDR -d %s'

'''
e.g. : SetStateEffecterStates usage

pldmtool platform GetPDR -i <effter_handle> -c <count> -d <effecterID, effecterState>

pldmtool platform SetStateEffecterStates -i 1 -c 1 -d 1 1
'''

CMD_SETSTATEEFFECTERSTATES = 'platform SetStateEffecterStates -i %s -c %s -d %s'

# GetPDR parsed response message for record handle.
# Dictionary value array holds the expected output for record handle 1, 2.
#
# Note :
#      Record handle - 0 is default &  has same behaviour as record handle 1
#      Only record handle 0, 1, 2 are supported as of now.

RESPONSE_DICT_GETPDR_SETSTATEEFFECTER = {
    'responsecount': ['29', '30'],
    'pdrheaderversion': ['1'],
    'pdrtype': ['State Effecter PDR(11)'],
    'recordchangenumber': ['0'],
    'datalength': ['19', '20'],
    'pldmterminushandle': ['0'],
    'effecterid': ['1', '2', '3'],
    'entitytype': ['33', '45', '31'],
    'entityinstancenumber': ['0'],
    'containerid': ['0'],
    'effectersemanticid': ['0'],
    'effecterinit': ['0'],
    'effecterdescriptionpdr': ['false'],
    'compositeeffectercount': ['1'],
    'statesetid': ['Boot Progress(196)',
                   'System Power State(260)', 'Software Termination Status(129)'],
    'possiblestatessize': ['1', '2'],
    'possiblestates': ['6', '0', '64']}

RESPONSE_DICT_GETPDR_FRURECORDSETIDENTIFIER = {
    'responsecount': ['20'],
    'pdrheaderversion': ['1'],
    'pdrtype': ['FRU Record Set PDR(20)'],
    'recordchangenumber': ['0'],
    'datalength': ['10'],
    'pldmterminushandle': ['0', '2'],
    'entitytype': ['System Board', 'Chassis front panel board (control panel)',
                   'Management Controller', 'OEM', 'Power converter',
                   'System (logical)', 'System chassis (main enclosure)',
                   'Chassis front panel board (control panel)',
                   'Processor Module', 'Memory Module', 'Power Supply'],
    'containerid': ['0', '1', '2', '3']}

RESPONSE_DICT_GETPDR_PDRENTITYASSOCIATION = {
    'pdrheaderversion': ['1'],
    'pdrtype': ['Entity Association PDR(15)'],
    'recordchangenumber': ['0'],
    'containerid': ['1', '2', '3'],
    'associationtype': ['Physical'],
    'containerentitytype': ['System Board', 'System (logical)',
                            'System chassis (main enclosure)']
}

RESPONSE_DICT_GETPDR_STATESENSORPDR = {
    'entitytype': ['Communication Channel', 'Connector', 'Processor Module'],
    'sensorinit': ['noInit'],
    'sensorauxiliarynamespdr': ['false'],
    'statesetid': ['Availability(2)', 'Configuration State(15)',
                   'Operational Running Status(11)']
}

PLDM_PDR_TYPES = {
    'PLDM_STATE_EFFECTER_PDR': 'State Effecter PDR(11)',
    'PLDM_PDR_FRU_RECORD_SET': 'FRU Record Set PDR(20)',
    'PLDM_PDR_ENTITY_ASSOCIATION': 'Entity Association PDR(15)',
    'PLDM_STATE_SENSOR_PDR': 'State Sensor PDR(4)',
    'PLDM_NUMERIC_EFFECTER_PDR': 'Numeric Effecter PDR(9)',
    'PLDM_TERMINUS_LOCATOR_PDR': 'Terminus Locator PDR(1)'}

RESPONSE_LIST_GETBIOSTABLE_STRTABLE = [
    'Allowed', 'Disabled', 'Enabled', 'IPv4DHCP', 'IPv4Static', 'Not Allowed',
    'Perm', 'Temp', 'pvm-fw-boot-side', 'pvm-inband-code-update', 'pvm-os-boot-side',
    'pvm-pcie-error-inject', 'pvm-surveillance', 'pvm-system-name', 'vmi-hostname',
    'vmi-if-count', 'vmi-if0-ipv4-ipaddr', 'vmi-if0-ipv4-method',
    'vmi-if0-ipv4-prefix-length', 'vmi-if1-ipv4-ipaddr', 'vmi-if1-ipv4-method',
    'vmi-if1-ipv4-prefix-length', 'vmi-ipv4-gateway']
