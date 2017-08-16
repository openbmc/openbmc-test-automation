#!/usr/bin/python

r"""
This is an extended user library to support Robot Selenium code.
The class contains functions which the robot framework will use
and import as a user-defined keyword.
"""

import socket

class supporting_libs():

    def get_hostname_from_ip_address(self,
                                     i_IP):
         return socket.gethostbyaddr(i_IP)[0]



