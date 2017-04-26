#!/usr/bin/env python

r"""
This module contains utility functions for BMC useful
to robot python programs.
"""

import paramiko
from robot.libraries.BuiltIn import BuiltIn

###############################################################################
def delete_file_if_exist(filepath):
    r"""
    Deletes the given file from the BMC.
    """
    cmd = "rm -rf " + filepath
    execute_command_bmc(cmd)
###############################################################################

###############################################################################
def check_if_file_exist(filepath):
    r"""
    Checks if the given file exists on the BMC. Returns true/false.
    """
    cmd = "ls -l " + filepath
    output = execute_command_bmc(cmd)
    if ("No such file or directory" in output):
        return 1
    else:
        return 0
###############################################################################

###############################################################################
def execute_command_bmc(cmd):
    r"""
    Executes a command on to the BMC.
    """
    OPENBMC_HOST=BuiltIn().get_variable_value("${OPENBMC_HOST}")
    OPENBMC_USERNAME=BuiltIn().get_variable_value("${OPENBMC_USERNAME}")
    OPENBMC_PASSWORD=BuiltIn().get_variable_value("${OPENBMC_PASSWORD}")

    client1=paramiko.SSHClient()
    #Add missing client key
    client1.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    #connect to switch
    client1.connect(OPENBMC_HOST,username=OPENBMC_USERNAME,
                    password=OPENBMC_PASSWORD)
    print "SSH connection to %s established" %OPENBMC_HOST
    #Gather commands and read the output from stdout
    stdin, stdout, stderr = client1.exec_command(cmd)
    print stdout.read()
    client1.close()
    print "Logged out of device %s" %OPENBMC_HOST
    return stdout.read()
###############################################################################
