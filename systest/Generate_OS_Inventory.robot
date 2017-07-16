***Settings***
Documentation      This module is for generating an inventory file using lshw
...                commands. It will create a JSON file and a YAML file. it
...                will get the processor, memory and specified I/O devices.
...                Requires access to lshw, and json2yaml OS commands. This
...                robot file should be run as root or sudo for lshw.

Library            String
Library            Collections
Library            OperatingSystem
Resource           ../syslib/utils_os.robot

***Variables***

# Path of the JSON Inventory file
${json_file_location}       ${EXECDIR}${/}data${/}os_inventory.json

***Test Case***

Create An Inventory
    [Documentation]    Snapshot system inventory to a JSON file
    [Tags]    Inventory Test
    Create JSON Inventory File    ${json_file_location}

