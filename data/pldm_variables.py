#!/usr/bin/env python3

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
PLDM_SUPPORTED_TYPES = ['0(base)', '2(platform)', '3(bios)', '4(fru)', '63(oem-ibm)']

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
    'PDRHeaderVersion': [1],
    'PDRType': ['State Effecter PDR'],
    'recordChangeNumber': [0],
    'effecterID': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'entityType': ['Virtual Machine Manager', 'System chassis (main enclosure)',
                   'System Firmware', 'Processor Module', '32801(OEM)',
                   'Management Controller', '24577(OEM)'],
    'entityInstanceNumber': [0, 1, 2, 3, 4],
    'containerID': [0, 1],
    'effecterSemanticID': [0],
    'effecterInit': ['noInit'],
    'effecterDescriptionPDR': [False],
    'compositeEffecterCount': [1]}

RESPONSE_DICT_GETPDR_FRURECORDSETIDENTIFIER = {
    'PDRHeaderVersion': [1],
    'PDRType': ['FRU Record Set PDR'],
    'recordChangeNumber': [0],
    'dataLength': [10],
    'entityType': ['System Board', 'Chassis front panel board (control panel)',
                   'Management Controller', 'OEM', 'Power converter',
                   'System (logical)', 'System chassis (main enclosure)',
                   'Chassis front panel board (control panel)',
                   'Processor Module', 'Memory Module', 'Power Supply',
                   '24576(OEM)', '60(OEM)', 'Processor', '142(OEM)'],
    'containerID': [0, 1, 2, 3]}

RESPONSE_DICT_GETPDR_PDRENTITYASSOCIATION = {
    'PDRHeaderVersion': [1],
    'PDRType': ['Entity Association PDR'],
    'recordChangeNumber': [0],
    'containerID': [1, 2, 3],
    'associationtype': ['Physical'],
    'containerentityType': ['System Board', 'System (logical)',
                            'System chassis (main enclosure)']}

RESPONSE_DICT_GETPDR_STATESENSORPDR = {
    'entityType': ['Communication Channel', 'Connector', 'Processor Module',
                   '32774(OEM)', '57346(OEM)', '57347(OEM)', '32801(OEM)',
                   '91(OEM)', '5(OEM)', '24577(OEM)'],
    'sensorInit': ['noInit'],
    'sensorAuxiliaryNamesPDR': [False]}

RESPONSE_DICT_GETPDR_TERMINUSLOCATORPDR = {
    'PDRHeaderVersion': [1],
    'PDRType': ['Terminus Locator PDR'],
    'recordChangeNumber': [0],
    'validity': ['valid'],
    'TID': [0, 1, 208],
    'containerID': [0, 1],
    'terminusLocatorType': ['MCTP_EID'],
    'terminusLocatorValueSize': [1]}

RESPONSE_DICT_GETPDR_NUMERICEFFECTERPDR = {
    'PDRHeaderVersion': [1],
    'PDRType': ['Numeric Effecter PDR'],
    'recordChangeNumber': [0],
    'entityInstanceNumber': [0, 1],
    'containerID': [0],
    'effecterSemanticID': [0],
    'effecterInit': [0],
    'effecterAuxiliaryNames': [False],
    'baseUnit': [0, 72, 21],
    'unitModifier': [0],
    'baseOEMUnitHandle': [0],
    'auxUnit': [0],
    'auxUnitModifier': [0],
    'auxrateUnit': [0],
    'auxOEMUnitHandle': [0],
    'resolution': [1, 0],
    'offset': [0],
    'accuracy': [0],
    'plusTolerance': [0],
    'minusTolerance': [0],
    'stateTransitionInterval': [0],
    'TransitionInterval': [0],
    'minSettable': [0],
    'rangeFieldSupport': [0],
    'nominalValue': [0],
    'normalMax': [0],
    'normalMin': [0],
    'ratedMax': [0],
    'ratedMin': [0]}

PLDM_PDR_TYPES = {
    'PLDM_STATE_EFFECTER_PDR': 'State Effecter PDR',
    'PLDM_PDR_FRU_RECORD_SET': 'FRU Record Set PDR',
    'PLDM_PDR_ENTITY_ASSOCIATION': 'Entity Association PDR',
    'PLDM_STATE_SENSOR_PDR': 'State Sensor PDR',
    'PLDM_NUMERIC_EFFECTER_PDR': 'Numeric Effecter PDR',
    'PLDM_TERMINUS_LOCATOR_PDR': 'Terminus Locator PDR',
    'PLDM_COMPACT_NUMERIC_SENSOR_PDR': '21'}

RESPONSE_LIST_GETBIOSTABLE_ATTRVALTABLE = [
    'BIOSString', 'BIOSInteger', 'BIOSEnumeration']
