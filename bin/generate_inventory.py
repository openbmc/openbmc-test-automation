#!/usr/bin/env python
r"""
    Generate a inventory variable file containing list of properties
    field from the YAML phosphor-dbus-interfaces repository.
"""
import os
import sys
import yaml
import json

############################################################################
# This list will be more as an when more development codes are available.
############################################################################
INVENTORY_ITEMS = ['FRU']
print "Properties for", str(INVENTORY_ITEMS)
FRU_INVENTORY_FILE = 'inventory.py'
print "Inventory file to be generated:", FRU_INVENTORY_FILE

# Properties master list
yaml_master_list = []

############################################################################
# Clone the phosphor-dbus-interfaces repository
############################################################################
cmd_buf = 'git clone https://github.com/openbmc/phosphor-dbus-interfaces'
os.system(cmd_buf)

repo_path = '/phosphor-dbus-interfaces/xyz/openbmc_project/Inventory/'
base_path = os.getcwd() + repo_path

############################################################################
# yaml paths for FRU
############################################################################
Item_yaml_file = base_path + 'Item.interface.yaml'
Asset_yaml_file = base_path + 'Decorator/Asset.interface.yaml'
Revision_yaml_file = base_path + 'Decorator/Revision.interface.yaml'

# FRU list
yaml_fru_list = []
yaml_fru_list.append(Item_yaml_file)
yaml_fru_list.append(Asset_yaml_file)
yaml_fru_list.append(Revision_yaml_file)

# Append to master list
yaml_master_list.append(yaml_fru_list)

############################################################################
# Populate Inventory data
############################################################################
INVENTORY_DICT = {}

for master_index in range(0, len(yaml_master_list)):
    INVENTORY_DICT[str(INVENTORY_ITEMS[master_index])] = []
    for yaml_file in yaml_master_list[master_index]:

        # Get the yaml dictionary data
        print "Load:", yaml_file
        f = open(yaml_file)
        yaml_data = yaml.load(f)
        f.close()
        for item in range(0, len(yaml_data['properties'])):
            tmp_data = yaml_data['properties'][item]['name']
            INVENTORY_DICT[str(INVENTORY_ITEMS[master_index])].append(tmp_data)

# Prety print json formatter
data = json.dumps(INVENTORY_DICT, indent=4, sort_keys=True, default=str)

# Check if there is mismatch in data vs expect list
if len(INVENTORY_DICT) != len(INVENTORY_ITEMS):
    print "ERROR: Check inventory master list populated"
    print data
    print str(INVENTORY_ITEMS)
    sys.exit()

############################################################################
# Write dictionary data to inventory file
############################################################################
print "\nGenerated Inventory item json format\n"
print data
out = open(FRU_INVENTORY_FILE, 'w')
out.write('INVENTORY_DICT = ')
out.write(data)

out.close()
print "\nGenerated Inventory File : ", FRU_INVENTORY_FILE
