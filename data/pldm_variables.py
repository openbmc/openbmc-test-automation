#!/usr/bin/python

r"""
Contains PLDM-related constants.
"""

PLDM_SUPPORTED_TYPES = ['base', 'platform', 'bios']

# PLDM types.
PLDM_TYPE_BASE = {'VALUE': '00', 'STRING': 'base'}
PLDM_TYPE_PLATFORM = {'VALUE': '02', 'STRING': 'platform'}
PLDM_TYPE_BIOS = {'VALUE': '03', 'STRING': 'bios'}
PLDM_TYPE_FRU = {'VALUE': '04', 'STRING': 'fru'}
PLDM_TYPE_OEM = {'VALUE': '3F', 'STRING': 'oem'}

VERSION_BASE = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}
VERSION_PLATFORM = {'VALUE': ['f1', 'f2', 'f0', '00'], 'STRING': '1.2.0'}
VERSION_BIOS = {'VALUE': ['f1', 'f1', 'f1', '00'], 'STRING': '1.0.0'}
VERSION_FRU = {'VALUE': ['f1', 'f0', 'f0', '00'], 'STRING': '1.0.0'}


PLDM_BASE_CMDS = ['2(GetTID)', '3(GetPLDMVersion)', '4(GetPLDMTypes)', '5(GetPLDMCommands)']
PLDM_PLATFORM_CMDS = ['57(SetStateEffecterStates)', '81(GetPDR)']
PLDM_BIOS_CMDS = ['1(GetBIOSTable)', '7(SetBIOSAttributeCurrentValue)',
                  '8(GetBIOSAttributeCurrentValueByHandle)', '12(GetDateTime)',
                  '13(SetDateTime)']
PLDM_FRU_CMDS = ['1(GetFRURecordTableMetadata)', '2(GetFRURecordTable)']

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
    'pdrtype': ['11'],
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
    'statesetid': ['196', '260', '129'],
    'possiblestatessize': ['1', '2'],
    'possiblestates': ['6', '0', '64']}

RESPONSE_DICT_GETPDR_FRURECORDSETIDENTIFIER = {
    'responsecount': ['20'],
    'pdrheaderversion': ['1'],
    'pdrtype': ['20'],
    'recordchangenumber': ['0'],
    'datalength': ['10'],
    'pldmterminushandle': ['0'],
    'entitytype': ['System Board', 'Chassis front panel board (control panel)',
                   'Management Controller', '208(OEM)', 'Power converter'],
    'containerid': ['0', '1']}

RESPONSE_DICT_GETPDR_PDRENTITYASSOCIATION = {
    'pdrheaderversion': ['1'],
    'pdrtype': ['15'],
    'recordchangenumber': ['0'],
    'containerid': ['1'],
    'associationtype': ['Physical'],
    'containerentitytype': ['System Board'],
}

PLDM_PDR_TYPES = {
    'PLDM_STATE_EFFECTER_PDR': '11',
    'PLDM_PDR_FRU_RECORD_SET': '20',
    'PLDM_PDR_ENTITY_ASSOCIATION': '15'}
