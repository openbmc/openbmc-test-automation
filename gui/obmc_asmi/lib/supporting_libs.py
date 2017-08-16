#!/usr/bin/python

r"""
This is an extended user library to support Robot Selenium code.
The class contains functions which the robot framework will use
and import as a user define keyword.
"""

import socket

class supporting_libs():

    def Get_Hostname_From_IP_Address(self,i_IP):
       l_HostName = socket.gethostbyaddr(i_IP)
       return l_HostName[0]

