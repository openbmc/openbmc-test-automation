#!/usr/bin/python -u
import sys
from robot.libraries.BuiltIn import BuiltIn
import imp
import string
import random

def random_mac():
        return ":".join(map(lambda x: "%02x" % x, (random.randint(0x00, 0xff)
                        for _ in range(6))))

def random_ip():
        return ".".join(map(str, (random.randint(0, 255)
                        for _ in range(4))))

def get_sensor(module_name, value):
    m = imp.load_source('module.name', module_name)

    for i in m.ID_LOOKUP['SENSOR']:

        if m.ID_LOOKUP['SENSOR'][i] == value:
            return i

    return 0xFF


def get_inventory_sensor (module_name, value):
    m = imp.load_source('module.name', module_name)

    value = string.replace(value, m.INVENTORY_ROOT, '<inventory_root>')

    for i in m.ID_LOOKUP['SENSOR']:

        if m.ID_LOOKUP['SENSOR'][i] == value:
            return i

    return 0xFF


################################################################
#  This will return the URI's of the FRU type
#
#  i.e.  get_inventory_list('../data/Palmetto.py')
#
#  [/org/openbmc/inventory//system/chassis/motherboard/cpu0/core0,
#   /org/openbmc/inventory/system/chassis/motherboard/dimm0]
################################################################
def get_inventory_list(module_name):

    l = []
    m = imp.load_source('module.name', module_name)


    for i in m.ID_LOOKUP['FRU']:
        s = m.ID_LOOKUP['FRU'][i]
        s = s.replace('<inventory_root>',m.INVENTORY_ROOT)
        l.append(s)

    return l


################################################################
#  This will return the URI's of the FRU type
#
#  i.e.  get_inventory_fru_type_list('../data/Barreleye.py', 'CPU')
#
#  [/org/openbmc/inventory//system/chassis/motherboard/cpu0,
#   /org/openbmc/inventory//system/chassis/motherboard/cpu1]
################################################################
def  get_inventory_fru_type_list(module_name, fru):
    l = []
    m = imp.load_source('module.name', module_name)

    for i in m.FRU_INSTANCES.keys():
        if m.FRU_INSTANCES[i]['fru_type'] == fru:
            s = i.replace('<inventory_root>',m.INVENTORY_ROOT)
            l.append(s)

    return l


################################################################
#  This will return the URI's of the FRU type that contain VPD
#
#  i.e.  get_vpd_inventory_list('../data/Palmetto.py', 'DIMM')
#
#  [/org/openbmc/inventory/system/chassis/motherboard/dimm0,
#   /org/openbmc/inventory/system/chassis/motherboard/dimm1]
################################################################
def  get_vpd_inventory_list(module_name, fru):
    l = []
    m = imp.load_source('module.name', module_name)

    for i in m.ID_LOOKUP['FRU_STR']:
        x = m.ID_LOOKUP['FRU_STR'][i]

        if m.FRU_INSTANCES[x]['fru_type'] == fru:
            s = x.replace('<inventory_root>',m.INVENTORY_ROOT)
            l.append(s)

    return l


def call_keyword(keyword):
    return BuiltIn().run_keyword(keyword)


def main():
    print get_vpd_inventory_list('../data/Palmetto.py', 'DIMM')


if __name__ == "__main__":
   main()
