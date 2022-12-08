#!/usr/bin/env python3


import os
import sys

# ---------Set sys.path for pluqin execution---------------------------------------
# Absolute path to this plugin
abs_path = os.path.abspath(os.path.dirname(sys.argv[0]))
# full_path to plugins parent directory
full_path = abs_path.split('plugins')[0]
sys.path.append(full_path)
# Walk path and append to sys.path
for root, dirs, files in os.walk(full_path):
    for found_dir in dirs:
        sys.path.append(os.path.join(root, found_dir))

# ssh_utility is in ../lib
from ssh_utility import SSHRemoteclient


def scp_remote_file(hostname,
                    username,
                    password,
                    filename,
                    local_dir_path):
    r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to files
        password        Password for user on remote host
        filename        Filename with full path on remote host
                        Filename can contain wild cards for multiple files
        local_dir_path  Location to store file on local host
    """
    ssh_remoteclient = SSHRemoteclient(hostname,
                                       username,
                                       password)

    if ssh_remoteclient.ssh_remoteclient_login():

        # Obtain scp connection.
        ssh_remoteclient.scp_connection()
        if ssh_remoteclient.scpclient:
            if isinstance(filename, list):
                for each_file in filename:
                    ssh_remoteclient.scp_file_from_remote(each_file, local_dir_path)
            else:
                ssh_remoteclient.scp_file_from_remote(filename, local_dir_path)

    # Close ssh/scp session
    if ssh_remoteclient:
        ssh_remoteclient.ssh_remoteclient_disconnect()
