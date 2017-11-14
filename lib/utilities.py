#!/usr/bin/python -u
import sys
from robot.libraries.BuiltIn import BuiltIn
import imp
import string
import random
import subprocess
from robot.utils import DotDict


def random_mac():
    r"""
    Return random mac address in the following format.
    Example: 00:01:6C:80:02:78
    """
    return ":".join(map(lambda x: "%02x" % x, (random.randint(0x00, 0xff)
        for _ in range(6))))

def random_ip():
    r"""
    Return random ip address in the following format.
    Example: 9.3.128.100
    """
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


def get_mtr_report(host=""):

    r"""
    Get an mtr report and return it as a dictionary of dictionaries.

    The key for the top level dictionary will be the host DNS name.  The key
    for the next level dictionary will be the field of a given row of the
    report.

    Example result:

    report:
      report[host_dummy-dnsname.com]:
        report[host_dummy-dnsname.com][row_num]:  1
        report[host_dummy-dnsname.com][host]:     host_dummy-dnsname.com
        report[host_dummy-dnsname.com][loss]:     0.0
        report[host_dummy-dnsname.com][snt]:      10
        report[host_dummy-dnsname.com][last]:     0.2
        report[host_dummy-dnsname.com][avg]:      3.5
        report[host_dummy-dnsname.com][best]:     0.2
        report[host_dummy-dnsname.com][wrst]:     32.5
        report[host_dummy-dnsname.com][stdev]:    10.2
      report[bmc-dummy-dnsname.com]:
        report[bmc-dummy-dnsname.com][row_num]:     2
        report[bmc-dummy-dnsname.com][host]:        bmc-dummy-dnsname.com
        report[bmc-dummy-dnsname.com][loss]:        0.0
        report[bmc-dummy-dnsname.com][snt]:         10
        report[bmc-dummy-dnsname.com][last]:        0.5
        report[bmc-dummy-dnsname.com][avg]:         0.5
        report[bmc-dummy-dnsname.com][best]:        0.5
        report[bmc-dummy-dnsname.com][wrst]:        0.5
        report[bmc-dummy-dnsname.com][stdev]:       0.0

    Description of arguments:
    host   The DNS name or IP address to be passed to the mtr command.
    """

    # Run the mtr command.  Exlude the header line.  Trim leading space from
    # each line.  Change all multiple spaces delims to single space delims.
    cmd_buf = "mtr --report " + host +\
        " | tail -n +2 | sed -r -e 's/^[ ]+//g' -e 's/[ ]+/ /g'"
    sub_proc = subprocess.Popen(cmd_buf, shell=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
    out_buf, err_buf = sub_proc.communicate()
    shell_rc = sub_proc.returncode

    # Split the output by line.
    rows = out_buf.rstrip('\n').split("\n")

    # Initialize report dictionary.
    report = DotDict()
    for row in rows:
        # Process each row of mtr output.
        # Create a list of fields by splitting on space delimiter.
        row_list = row.split(" ")
        # Create dictionary for the row.
        row = DotDict()
        row['row_num'] = row_list[0].rstrip('.')
        row['host'] = row_list[1]
        row['loss'] = row_list[2].rstrip('%')
        row['snt'] = row_list[3]
        row['last'] = row_list[4]
        row['avg'] = row_list[5]
        row['best'] = row_list[6]
        row['wrst'] = row_list[7]
        row['stdev'] = row_list[8]
        report[row['host']] = row

    # Return the full report as dictionary of dictionaries.
    return report


def get_mtr_row(host=""):

    r"""
    Run an mtr report and get a specified row and return it as a dictionary.

    Example result:

    row:
      row[row_num]:              2
      row[host]:                 bmc-dummy-dnsname.com
      row[loss]:                 0.0
      row[snt]:                  10
      row[last]:                 0.5
      row[avg]:                  0.5
      row[best]:                 0.4
      row[wrst]:                 0.7
      row[stdev]:                0.1

    Description of arguments:
    host   The DNS name or IP address to be passed to the mtr command as
           well as the indicating which row of the report to return.
    """

    report = get_mtr_report(host)

    # The max length of host in output is 28 chars.
    row = [value for key, value in report.items() if host[0:28] in key][0]

    return row


def list_to_set(fru_list=""):
    r"""
    Pack the list into a set tuple and return.

    It may seem that this function is rather trivial. However, it simplifies
    the code and improves robot program readability and achieve the result
    required.

    Example result:

    set(['Version', 'PartNumber', 'SerialNumber', 'FieldReplaceable',
    'BuildDate', 'Present', 'Manufacturer', 'PrettyName', 'Cached', 'Model'])

    # Description of arguments.
    fru_list   List of FRU's elements.
    """
    return set(fru_list)


def min_list_value(value_list):
    r"""
    Returns the element from the list with minimum value.
    """
    return min(value_list)
