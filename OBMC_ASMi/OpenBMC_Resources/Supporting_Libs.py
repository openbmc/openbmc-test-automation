#!/usr/bin/python

r'''
Exports issues from a list of repositories to individual CSV files.
Uses basic authentication (GitHub username + password) to retrieve issues
from a repository that username has access to. Supports GitHub API v3.
'''

import socket

class Supporting_Libs():

    def Get_Hostname_From_IP_Address(self,i_IP):
       l_HostName = socket.gethostbyaddr(i_IP)
       return l_HostName[0]
