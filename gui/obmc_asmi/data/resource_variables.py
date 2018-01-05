#!/usr/bin/python

r"""
Contains xpaths and related string constants applicable to all openBMC GUI
menus.
"""


class resource_variables():

    xpath_textbox_username = "//*[@id='username']"
    xpath_textbox_password = "//*[@id='password']"
    xpath_button_login = "//*[@id='login__submit']"
    xpath_button_logout = "//*[@id='header']/a"
    xpath_BMC_URL = "http://localhost:8080/#/login"
    xpath_bmc_ip = "//*[@id='login__form']/input[1]"
    obmc_uname = "username"
    obmc_user_name = "root"
    obmc_password = "0penBmc"

    # Power Operation Elements needed for power on
    header_wrapper = "3"
    header_wrapper_elt = "3"

    # Power Operation Elements needed for power operations confirmation
    power_operations = "3"
    warm_boot = "3"
    cold_boot = "4"
    shut_down = "5"
    power_off = "6"
    confirm_msg = "2"
    yes = "1"
