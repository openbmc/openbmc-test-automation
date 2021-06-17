#!/usr/bin/env python

import paramiko
from paramiko.ssh_exception import AuthenticationException
from paramiko.ssh_exception import NoValidConnectionsError
from paramiko.ssh_exception import SSHException
from paramiko.ssh_exception import BadHostKeyException
from paramiko.buffered_pipe import PipeTimeout as PipeTimeout
from scp import SCPClient, SCPException
import sys
import socket
from socket import timeout as SocketTimeout


class SSHRemoteclient:
    r"""
    Class to create ssh connection to remote host
    for remote host command execution and scp.
    """

    def __init__(self, hostname, username, password):

        r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        """

        self.ssh_output = None
        self.ssh_error = None
        self.sshclient = None
        self.scpclient = None
        self.hostname = hostname
        self.username = username
        self.password = password

    def ssh_remoteclient_login(self):

        r"""
        Method to create a ssh connection to remote host.
        """

        try:
            # SSHClient to make connections to the remote server
            self.sshclient = paramiko.SSHClient()
            # setting set_missing_host_key_policy() to allow any host
            self.sshclient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            # Connect to the server
            self.sshclient.connect(hostname=self.hostname,
                                   username=self.username,
                                   password=self.password,
                                   look_for_keys=False)

        except (BadHostKeyException, AuthenticationException,
                SSHException, NoValidConnectionsError, socket.error) as e:
            print("\n>>>>>\tERROR: Unable to SSH to %s %s %s\n\n" % (self.hostname, e.__class__, e))
            sys.exit(-1)

    def ssh_remoteclient_disconnect(self):

        r"""
        Clean up.
        """

        if self.sshclient:
            self.sshclient.close()

        if self.scpclient:
            self.scpclient.close()

    def execute_command(self, command):
        """
        Execute command on the remote host.

        Description of argument(s):
        command                Command string sent to remote host

        """

        try:
            stdin, stdout, stderr = self.sshclient.exec_command(command)
            stdout.channel.recv_exit_status()
            response = stdout.readlines()
            return response
        except (paramiko.AuthenticationException, paramiko.SSHException,
                paramiko.ChannelException) as e:
            # Log command with error. Return to caller for next command, if any.
            print("\n>>>>>\tERROR: Fail remote command %s %s %s\n\n" % (command, e.__class__, e))

    def scp_connection(self):

        r"""
        Create a scp connection for file transfer.
        """
        try:
            self.scpclient = SCPClient(self.sshclient.get_transport())
            print("\n\t[Check] %s SCP transport established.\t [OK]" % self.hostname)
        except (SCPException, SocketTimeout, PipeTimeout) as e:
            self.scpclient = None
            print("\n>>>>>\tERROR: SCP get_transport has failed. %s %s" % (e.__class__, e))
            print(">>>>>\tScript continues generating FFDC on %s." % self.hostname)
            print(">>>>>\tCollected data will need to be manually offloaded.")

    def scp_file_from_remote(self, remote_file, local_file):

        r"""
        scp file in remote system to local with date-prefixed filename.

        Description of argument(s):
        remote_file            Full path filename on the remote host

        local_file             Full path filename on the local host
                               local filename = date-time_remote filename

        """

        try:
            self.scpclient.get(remote_file, local_file)
        except (SCPException, SocketTimeout, PipeTimeout) as e:
            # Log command with error. Return to caller for next file, if any.
            print("\n>>>>>\tERROR: Fail scp %s from remotehost %s %s\n\n" % (remote_file, e.__class__, e))
            return False

        # Return True for file accounting
        return True
