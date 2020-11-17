#!/usr/bin/python

r"""
Contains xpaths and related string constants applicable for new Vue based OpenBMC GUI.
"""


class gui_variables():

    # Login page
    xpath_textbox_hostname = "//input[@id='host']"
    xpath_textbox_username = "//input[@id='username']"
    xpath_textbox_password = "//input[@id='password']"
    xpath_login_button = "//button[@type='submit']"
    xpath_logout_button = "//*[@data-test-id='appHeader-link-logout']"

    # Overview menu
    xpath_overview_menu = "//*[@data-test-id='nav-item-overview']"

    # GUI header
    xpath_root_button_menu = "//*[@id='app-header-user__BV_toggle_']"
    xpath_profile_settings = "//*[@data-test-id='appHeader-link-profile']"
    xpath_server_health_header = "//*[@data-test-id='appHeader-container-health']"
    xpath_event_header = "//h1[text()='Event logs']"
    xpath_server_power_header = "//*[@data-test-id='appHeader-container-power']"
    xpath_refresh_button = "//*[@data-test-id='appHeader-button-refresh']"
    xpath_network_page_header = "//h1[contains(text(), 'Network settings')]"
    xpath_sol_header = "//h1[contains(text(), 'Serial over LAN console')]"
    xpath_sol_console_heading = "//h1[text()='Serial over LAN (SOL) console']"

    # Health menu
    xpath_health_menu = "//*[@data-test-id='nav-button-health']"
    xpath_event_logs_sub_menu = "//*[@data-test-id='nav-item-event-logs']"
    xpath_sensor_sub_menu = "//*[@data-test-id='nav-item-sensors']"
    xpath_hardware_status_sub_menu = "//*[@data-test-id='nav-item-hardware-status']"

    # Control menu
    xpath_control_menu = "//*[@data-test-id='nav-button-control']"
    xpath_manage_power_usage_sub_menu = "//*[@data-test-id='nav-item-manage-power-usage']"
    xpath_reboot_bmc_sub_menu = "//*[@data-test-id='nav-item-reboot-bmc']"
    xpath_server_led_sub_menu = "//*[@data-test-id='nav-item-server-led']"
    xpath_server_power_operations_sub_menu = "//*[@data-test-id='nav-item-server-power-operations']"
    xpath_sol_sub_menu = "//*[@data-test-id='nav-item-serial-over-lan']"
    xpath_kvm_sub_menu = "//*[@data-test-id='nav-item-kvm']"

    # Configuration menu
    xpath_server_configuration = "//*[@data-test-id='nav-button-configuration']"
    xpath_select_network_settings = "//*[@data-test-id='nav-item-network-settings']"
    xpath_date_time_settings_sub_menu = "//*[@data-test-id='nav-item-date-time-settings']"
    xpath_firmware_update_sub_menu = "//*[@data-test-id='nav-item-firmware']"

    # Access control menu
    xpath_access_control_menu = "//*[@data-test-id='nav-button-access-control']"
    xpath_ldap_sub_menu = "//*[@data-test-id='nav-item-ldap']"
    xpath_save_settings_button = "//button[contains(text(),'Save settings')]"
    xpath_local_user_management_sub_menu = "//*[@data-test-id='nav-item-local-user-management']"
    xpath_ssl_certificates_sub_menu = "//*[@data-test-id='nav-item-ssl-certificates']"
