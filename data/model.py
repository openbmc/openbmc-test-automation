#!/usr/bin/env python3 -u
import importlib.util
import string as string

from robot.libraries.BuiltIn import BuiltIn


def load_source(name, module_path):
    spec = importlib.util.spec_from_file_location(name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def get_sensor(module_name, value):
    m = load_source("module.name", module_name)

    for i in m.ID_LOOKUP["SENSOR"]:
        if m.ID_LOOKUP["SENSOR"][i] == value:
            return i

    return 0xFF


def get_inventory_sensor(module_name, value):
    m = load_source("module.name", module_name)

    value = string.replace(value, m.INVENTORY_ROOT, "<inventory_root>")

    for i in m.ID_LOOKUP["SENSOR"]:
        if m.ID_LOOKUP["SENSOR"][i] == value:
            return i

    return 0xFF


def get_inventory_list(module_name):
    inventory_list = []
    m = load_source("module.name", module_name)

    for i in m.ID_LOOKUP["FRU"]:
        s = m.ID_LOOKUP["FRU"][i]
        s = s.replace("<inventory_root>", m.INVENTORY_ROOT)
        inventory_list.append(s)

    return inventory_list


def get_inventory_fru_type_list(module_name, fru_type):
    inventory_list = []
    m = load_source("module.name", module_name)

    for i in m.FRU_INSTANCES.keys():
        if m.FRU_INSTANCES[i]["fru_type"] == fru_type:
            s = i.replace("<inventory_root>", m.INVENTORY_ROOT)
            inventory_list.append(s)

    return inventory_list


def call_keyword(keyword):
    return BuiltIn().run_keyword(keyword)


def get_FRU_component_name_list(module_name):
    name_list = []
    m = load_source("module.name", module_name)

    for name in m.FRU_COMPONENT_NAME:
        name_list.append(name)
        print(name)

    return name_list


def get_ipmi_rest_fru_field_map(module_name):
    m = load_source("module.name", module_name)

    ipmi_rest_fru_field_map = dict.copy(m.ipmi_rest_fru_field_map)

    return ipmi_rest_fru_field_map
