#!/usr/bin/python

'''
Exports issues from a list of repositories to individual CSV files.
Uses basic authentication (GitHub username + password) to retrieve issues
from a repository that username has access to. Supports GitHub API v3.
'''


class Resource_Variables():

    xpath_TXTBX_USERID_INPUT = "//*[@id='username']"
    xpath_TXTBX_PWD_INPUT = "//*[@id='password']"
    xpath_BTN_LOGIN = "//*[@id='login__submit']"
    xpath_BTN_LOGOUT = "//*[@id='header']/a"
    xpath_DISPLAY_TXT_OBMC_IP = "//*[@id='header__server-name']"

