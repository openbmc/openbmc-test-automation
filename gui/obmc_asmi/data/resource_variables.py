#!/usr/bin/python

r"""
Contains xpaths and related string constants
applicable to All menus
"""

class resource_variables():

    xpath_TXTBX_USERID_INPUT = "//*[@id='username']"
    xpath_TXTBX_PWD_INPUT = "//*[@id='password']"
    xpath_BTN_LOGIN = "//*[@id='login__submit']"
    xpath_BTN_LOGOUT = "//*[@id='header']/a"
    # xpath_DISPLAY_TXT_OBMC_IP = "//*[@id='header__server-name']"
    xpath_DISPLAY_TXT_OBMC_IP = "//*[@id='header__wrapper']/div/div[2]/p[2]"

