#!/usr/bin/python -u
import sys
from robot.libraries.BuiltIn import BuiltIn
import imp
import string


def get_sensor(module_name, value):
    m = imp.load_source('module.name', module_name)

    for i in m.ID_LOOKUP['SENSOR']:

        if m.ID_LOOKUP['SENSOR'][i] == value:
            return i

    return 0xFF


def get_inventory_sensor(module_name, value):
    m = imp.load_source('module.name', module_name)

    value = string.replace(value, m.INVENTORY_ROOT, '<inventory_root>')

    for i in m.ID_LOOKUP['SENSOR']:

        if m.ID_LOOKUP['SENSOR'][i] == value:
            return i

    return 0xFF


def get_inventory_list(module_name):

    inventory_list = []
    m = imp.load_source('module.name', module_name)

    for i in m.ID_LOOKUP['FRU']:
        s = m.ID_LOOKUP['FRU'][i]
        s = s.replace('<inventory_root>', m.INVENTORY_ROOT)
        inventory_list.append(s)

    return inventory_list


def get_inventory_fru_type_list(module_name, fru_type):

    inventory_list = []
    m = imp.load_source('module.name', module_name)

    for i in m.FRU_INSTANCES.keys():
        if m.FRU_INSTANCES[i]['fru_type'] == fru_type:
            s = i.replace('<inventory_root>', m.INVENTORY_ROOT)
            inventory_list.append(s)

    return inventory_list


def call_keyword(keyword):
    return BuiltIn().run_keyword(keyword)
