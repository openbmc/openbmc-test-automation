#!/usr/bin/env python3

r"""
Contains xpaths and related string constants applicable to all openBMC GUI
menus.
"""


class resource_variables():

    xpath_textbox_hostname = "//input[@id='host']"
    xpath_textbox_username = "//input[@id='username']"
    xpath_textbox_password = "//input[@id='password']"
    xpath_input_password = "//input[@id='password']"
    xpath_input_confirm_password = "//input[@id='passwordConfirm']"
    xpath_submit_button = '//button[@type="submit"]'
    xpath_button_profile_settings = '//a[@href="#/profile-settings"]'
    xpath_button_login = "//*[@id='login__submit']"
    xpath_button_user_action = "//button[@id='user-actions']"
    xpath_button_logout = '//button[text()="Log out"]'
    xpath_yes_button = "//button[text()='Yes']"
    xpath_power_indicator = "//*[@id='power-indicator-bar']"
    xpath_select_button_power_on = "//*[@id='power__power-on']"
    xpath_cancel_button = "//button[contains(text(),'Cancel')]"
    xpath_save_setting_button = "//button[contains(text(),'Save settings')]"
    xpath_save_button = "//button[contains(text(),'Save')]"
    xpath_remove_button = "//button[contains(text(),'Remove')]"
    xpath_add_button = "//button[@type='submit']"

    xpath_select_button_warm_reboot = \
        "//*[@id='power__warm-boot']"
    xpath_operation_warning_message = \
        "//*[@class='inline__confirm active']"
    text_warm_reboot_warning_message = "warm reboot?"
    xpath_select_button_warm_reboot_yes = \
        "//*[@id='power-operations']" \
        "/div[3]/div[3]/confirm/div/div[2]/button[1]"

    xpath_select_button_cold_reboot = \
        "//*[@id='power__cold-boot']"
    text_cold_reboot_warning_message = "cold reboot?"
    xpath_select_button_cold_reboot_yes = \
        "//*[@id='power-operations']" \
        "/div[3]/div[4]/confirm/div/div[2]/button[2]"

    xpath_select_button_orderly_shutdown = \
        "//*[@id='power__soft-shutdown']"
    xpath_select_button_orderly_shutdown_button_no = \
        "//*[@id='power-operations']/div[3]/div[5]"\
        "/confirm/div/div[2]/button[2]"
    text_orderly_shutdown_warning_message = "orderly shutdown?"
    xpath_select_button_orderly_shutdown_yes = \
        "//*[@id='power-operations']/div[3]/div[5]" \
        "/confirm/div/div[2]/button[1]"

    xpath_select_button_immediate_shutdown = \
        "//*[@id='power__hard-shutdown']"
    text_immediate_shutdown_warning_message = "immediate shutdown?"
    xpath_select_button_immediate_shutdown_yes = \
        "//*[@id='power-operations']/div[3]/div[6]" \
        "/confirm/div/div[2]/button[1]"

    obmc_off_state = "Off"
    obmc_standby_state = "Standby"
    obmc_running_state = "Running"

    # xpath for main menu.
    xpath_select_server_control = "//button[contains(@class,'btn-control')]"
    xpath_select_server_configuration = "//button[contains(@class,'btn-config')]"
    xpath_select_access_control = "//button[contains(@class,'btn-access-control')]"

    # xpath for sub main menu.
    xpath_select_server_power_operations = "//a[@href='#/server-control/power-operations']"
    xpath_select_snmp_settings = "//a[@href='#/configuration/snmp']"
    xpath_select_manage_power_usage = "//a[@href='#/server-control/power-usage']"
    xpath_select_virtual_media = "//a[@href='#/server-control/virtual-media']"
    xpath_select_sol_console = "//a[@href='#/server-control/remote-console']"
    xpath_select_reboot_bmc = "//a[@href='#/server-control/bmc-reboot']"
    xpath_select_ldap = "//a[@href='#/access-control/ldap']"
    xpath_select_server_health = "//a[@href='#/server-health/event-log']"
    xpath_select_server_led = "//a[@href='#/server-control/server-led']"
    xpath_select_date_time_settings = "//a[@href='#/configuration/date-time']"
    xpath_select_local_users = "//a[@href='#/access-control/local-users']"

    # GUI header elements locators.
    xpath_select_server_power = "//a[@href='#/server-control/power-operations']"

    # Server health elements locators.
    xpath_select_refresh_button = \
        "//*[contains(text(),'Refresh')]"
    xpath_event_severity_all = "//*[text()='Filter by severity']/following-sibling::button[1]"
    xpath_event_severity_high = "//*[text()='Filter by severity']/following-sibling::button[2]"
    xpath_event_severity_medium = "//*[text()='Filter by severity']/following-sibling::button[3]"
    xpath_event_severity_low = "//*[text()='Filter by severity']/following-sibling::button[4]"
    xpath_drop_down_timezone_edt = \
        "//*[@id='event-log']/section[1]/div/div/button"
    xpath_refresh_circle = "/html/body/main/loader/div[1]/svg/circle"
    xpath_drop_down_timezone_utc =  \
        "//*[@id='event-log']/section[1]/div/div/ul/li[2]/button"
    xpath_event_filter_all = "//*[text()='All events']"
    xpath_event_filter_resolved = "//*[text()='Resolved events']"
    xpath_event_filter_unresolved = "//*[text()='Unresolved events']"
    xpath_event_action_bars = \
        "//*[@id='event__actions-bar']/div[1]/label/span"
    xpath_event_action_delete = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/button[1]"
    xpath_event_action_export = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/a"
    xpath_number_of_events = \
        "//*[@id='event__actions-bar']/div[2]/p[2]/span"
    xpath_mark_as_resolved = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/button[2]"
    xpath_events_export = "//*[@id='event__actions-bar']/div[2]/div[2]/a"
    xpath_individual_event_select = "(//*[@class='control__indicator'])[2]"
    xpath_individual_event_delete = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/button[1]"
    xpath_second_event_select = "(//*[@class='control__indicator'])[3]"
    xpath_individual_event_resolved = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/button[2]"
    xpath_individual_event_export = \
        "//*[@id='event__actions-bar']/div[2]/div[2]/a"
    xpath_select_all_events = "(//*[@class='control__indicator'])[1]"
