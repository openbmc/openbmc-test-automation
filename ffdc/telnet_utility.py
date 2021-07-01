#!/usr/bin/env python

import socket
import telnetlib
from collections import deque


class TelnetRemoteclient:

    r"""
    Class to create telnet connection to remote host for command execution.
    """

    def __init__(self, hostname, username, password, port=23, read_timeout=None):

        r"""
        Description of argument(s):

        hostname        Name/IP of the remote (targeting) host
        username        User on the remote host with access to FFCD files
        password        Password for user on remote host
        read_timeout    New read timeout value to override default one
        """

        self.hostname = hostname
        self.username = username
        self.password = password
        self.tnclient = None
        self.port = port
        self.read_timeout = read_timeout

    def tn_remoteclient_login(self):

        is_telnet = True
        try:
            self.tnclient = telnetlib.Telnet(self.hostname, self.port, timeout=15)
            if b'login:' in self.tnclient.read_until(b'login:', timeout=self.read_timeout):
                self.tnclient.write(self.username.encode('utf-8') + b"\n")

                if b'Password:' in self.tnclient.read_until(b'Password:', timeout=self.read_timeout):
                    self.tnclient.write(self.password.encode('utf-8') + b"\n")

                    n, match, pre_match = \
                        self.tnclient.expect(
                            [b'Login incorrect', b'invalid login name or password.', br'\#', br'\$'],
                            timeout=self.read_timeout)
                    if n == 0 or n == 1:
                        print("\n>>>>>\tERROR: Telnet Authentication Failed.  Check userid and password.\n\n")
                        is_telnet = False
                    else:
                        # login successful
                        self.fifo = deque()
                else:
                    # Anything else, telnet server is not running
                    print("\n>>>>>\tERROR: Telnet Connection Refused.\n\n")
                    is_telnet = False
            else:
                is_telnet = False
        except Exception:
            # Any kind of exception, skip telnet protocol
            is_telnet = False

        return is_telnet

    def __del__(self):
        self.tn_remoteclient_disconnect()

    def tn_remoteclient_disconnect(self):
        try:
            self.tnclient.close()
        except Exception:
            # the telnet object might not exist yet, so ignore this one
            pass

    def execute_command(self, cmd,
                        rtnpartial=False,
                        wait_cnt=5,
                        i_timeout=300):

        r'''
            Executes commands on the remote host

            Description of argument(s):
            cmd             Command to run on remote host
            rtnpartial      Set to True to return command output even
                            if we haven't read the command prompt
            wait_cnt        Number of times to check for command output
                            default is 5
            i_timeout       Timeout for command output
                            default is 300 seconds
        '''

        # Execute the command and read the command output
        try:

            # Flush whatever data is in the read buffer by doing
            # a non-blocking read
            self.tnclient.read_very_eager()

            # Execute the command
            self.tnclient.write(cmd.encode('utf-8') + b"\n")

            # Read the command output.  Read until we get command prompt
            l_buf = ''
            l_xcnt = 0
            while(True):
                index, match, b = self.tnclient.expect([br'\$', br'\#'], i_timeout)

                if(b == ''):
                    # Nothing read.  Increment the counter & retry.
                    l_xcnt = l_xcnt + 1
                    if(l_xcnt >= wait_cnt):
                        l_time_waited = str((l_xcnt * i_timeout) / 60)
                        print("\t\t ERROR Timeout execute Telnet command")
                        break
                else:
                    # We got some data.  Reset the counter.
                    l_xcnt = 0
                    l_buf = l_buf + b.decode('utf-8').strip()

                if (index != -1) and (match is not None):
                    # We got the command prompt. Have read the complete command
                    # output.
                    break

                if rtnpartial:
                    print("\t\t WARN "
                          + "Have not read the command prompt. "
                          + "Returning command output read.")

                    return l_buf
        except (socket.error, EOFError) as e:
            self.tn_remoteclient_disconnect()

            if str(e).__contains__("Connection reset by peer"):
                msg = e
            elif str(e).__contains__("telnet connection closed"):
                msg = "Telnet connection closed."
            else:
                msg = "Some other issue. Connection got reset!!"

            print("\t\t ERROR %s " % msg)
            return ''

        # Remove command prompt
        c = l_buf[0: (len(l_buf) - 1)]
        return c
