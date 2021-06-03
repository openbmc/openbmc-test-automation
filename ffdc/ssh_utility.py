#!/usr/bin/env python

import paramiko
from paramiko.ssh_exception import AuthenticationException, NoValidConnectionsError, SSHException
from paramiko.buffered_pipe import PipeTimeout as PipeTimeout
import scp
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

        hostname                name/ip of the remote (targetting) host
        username                user on the remote host with access to FFCD files
        password                password for user on remote host
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
            # setting set_missing_host_key_policy() to allow any host.
            self.sshclient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            # Connect to the server
            self.sshclient.connect(hostname=self.hostname,
                                   username=self.username,
                                   password=self.password)

        except AuthenticationException:
            print("\n>>>>>\tERROR: Authentication failed, please verify your login credentials")
        except SSHException:
            print("\n>>>>>\tERROR: Failures in SSH2 protocol negotiation or logic errors.")
        except NoValidConnectionsError:
            print('\n>>>>>\tERROR: No Valid SSH Connection after multiple attempts.')
        except socket.error:
            print("\n>>>>>\tERROR: SSH Connection refused.")
        except Exception:
            raise Exception("\n>>>>>\tERROR: Unexpected Exception.")

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
                paramiko.ChannelException) as ex:
            print("\n>>>>>\tERROR: Remote command execution fails.")

    def scp_connection(self):

        r"""
        Create a scp connection for file transfer.
        """
        self.scpclient = scp.SCPClient(self.sshclient.get_transport())

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
        except scp.SCPException:
            print("scp.SCPException scp %s from remotehost" % remote_file)
            return False
        except (SocketTimeout, PipeTimeout) as ex:
            # Future enhancement: multiple retries on these exceptions due to bad ssh connection
            print("Timeout scp %s from remotehost" % remote_file)
            return False

        # Return True for file accounting
        return True
