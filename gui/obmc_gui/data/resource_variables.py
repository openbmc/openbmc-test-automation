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
    xpath_display_server_power_status = "//*[@id='header__wrapper']/div/div[3]/a[2]/span"
    xpath_select_button_orderly_power_shutdown = "//*[@id='power__soft-shutdown']"
    xpath_select_button_orderly_power_shutdown_yes = "//*[@id='power-operations']/div[4]/div[5]/confirm/div/div[2]/button[1]"
    xpath_select_button_power_on = "//*[@id='power__power-on']"

    string_OBMC_off="Off"
    string_OBMC_quiesced="Quiesced"
    string_OBMC_running="Running"

    