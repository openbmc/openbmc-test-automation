#!/usr/bin/env python3

r"""
Contains xpaths and related string constants applicable for new Vue based OpenBMC GUI.
"""


class gui_variables:
    r"""
    Base class for GUI related XPATH variables.
    """

    # Login page
    xpath_login_hostname_input = "//input[@id='host']"
    xpath_login_username_input = "//*[@data-test-id='login-input-username']"
    xpath_login_password_input = "//*[@data-test-id='login-input-password']"
    xpath_login_button = "//*[@data-test-id='login-button-submit']"
    xpath_logout_button = "//*[@data-test-id='appHeader-link-logout']"

    # Overview menu
    xpath_overview_menu = "//*[@data-test-id='nav-item-overview']"

    # GUI header
    xpath_root_button_menu = "//*[@data-test-id='appHeader-container-user']"
    xpath_profile_settings = "//*[@data-test-id='appHeader-link-profile']"
    xpath_server_health_header = (
        "//*[@data-test-id='appHeader-container-health']"
    )
    xpath_server_power_header = (
        "//*[@data-test-id='appHeader-container-power']"
    )
    xpath_refresh_button = "//*[@data-test-id='appHeader-button-refresh']"

    # Logs menu
    xpath_logs_menu = "//*[@data-test-id='nav-button-logs']"
    xpath_dumps_sub_menu = "//*[@data-test-id='nav-item-dumps']"
    xpath_dumps_header = "//h1[text()='Dumps']"
    xpath_event_logs_sub_menu = "//*[@data-test-id='nav-item-event-logs']"
    xpath_event_logs_heading = "//h1[contains(text(), 'Event logs')]"
    xpath_event_search = "//input[@placeholder='Search logs']"
    xpath_progress_logs_sub_menu = (
        "//*[@data-test-id='nav-item-post-code-logs']"
    )

    # Hardware status menu
    xpath_hardware_status_menu = (
        "//*[@data-test-id='nav-button-hardware-status']"
    )
    xpath_inventory_and_leds_sub_menu = (
        "//*[@data-test-id='nav-item-inventory']"
    )
    xpath_sensor_sub_menu = "//*[@data-test-id='nav-item-sensors']"
    xpath_inventory_and_leds_heading = (
        "//h1[contains(text(), 'Inventory and LEDs')]"
    )

    # Operations menu
    xpath_operations_menu = "//*[@data-test-id='nav-button-operations']"
    xpath_factory_reset_sub_menu = (
        "//*[@data-test-id='nav-item-factory-reset']"
    )
    xpath_firmware_update_sub_menu = "//*[@data-test-id='nav-item-firmware']"
    xpath_reboot_bmc_sub_menu = "//*[@data-test-id='nav-item-reboot-bmc']"
    xpath_host_console_sub_menu = "//*[@data-test-id='nav-item-host-console']"
    xpath_server_power_operations_sub_menu = (
        "//*[@data-test-id='nav-item-server-power-operations']"
    )
    xpath_host_console_heading = "//h1[text()='Host console']"
    xpath_firmware_heading = "//h1[contains(text(), 'Firmware')]"

    # Settings menu
    xpath_settings_menu = "//*[@data-test-id='nav-button-settings']"
    xpath_network_heading = "//h1[text()='Network']"
    xpath_date_time_sub_menu = "//*[@data-test-id='nav-item-date-time']"
    xpath_network_sub_menu = "//*[@data-test-id='nav-item-network']"
    xpath_power_restore_policy_sub_menu = (
        "//*[@data-test-id='nav-item-power-restore-policy']"
    )
    xpath_static_dns = "//h2[text()='Static DNS']"
    xpath_dns_servers_toggle = (
        "//*[@data-test-id='networkSettings-switch-useDns']"
    )
    xpath_add_dns_ip_address_button = (
        "//button[contains(text(),'Add IP address')]"
    )
    xpath_input_static_dns = "//*[@id='staticDns']"

    # Security and access menu
    xpath_secuity_and_accesss_menu = (
        "//*[@data-test-id='nav-button-security-and-access']"
    )
    xpath_sessions_sub_menu = "//*[@data-test-id='nav-item-sessions']"
    xpath_ldap_sub_menu = "//*[@data-test-id='nav-item-ldap']"
    xpath_user_management_sub_menu = (
        "//*[@data-test-id='nav-item-user-management']"
    )
    xpath_policies_sub_menu = "//*[@data-test-id='nav-item-policies']"
    xpath_certificates_sub_menu = "//*[@data-test-id='nav-item-certificates']"

    # Resource management menu
    xpath_resource_management_menu = (
        "//*[@data-test-id='nav-button-resource-management']"
    )
    xpath_power_sub_menu = "//*[@data-test-id='nav-item-power']"
    xpath_power_link = "//a[@href='#/resource-management/power']"
    xpath_power_heading = "//h1[contains(text(), 'Power')]"

    # Profile settings
    xpath_default_UTC = "//*[@data-test-id='profileSettings-radio-defaultUTC']"
    xpath_profile_save_button = (
        "//*[@data-test-id='profileSettings-button-saveSettings']"
    )
    xpath_profile_settings_link = "//a[contains(text(),'Profile Settings')]"
    xpath_profile_settings_heading = "//h1[text()='Profile settings']"
    xpath_browser_offset = (
        "//*[@data-test-id='profileSettings-radio-browserOffset']"
    )
    xpath_browser_offset_textfield = (
        xpath_browser_offset + "/following-sibling::*"
    )
    xpath_input_password = (
        "//*[@data-test-id='profileSettings-input-newPassword']"
    )
    xpath_input_confirm_password = (
        "//*[@data-test-id='profileSettings-input-confirmPassword']"
    )

    # Reboot sub menu
    xpath_reboot_bmc_heading = "//h1[text()='Reboot BMC']"
    xpath_reboot_bmc_button = "//button[contains(text(),'Reboot BMC')]"
    xpath_confirm_bmc_reboot = "//*[@class='btn btn-primary']"

    # Common variables
    xpath_save_settings_button = "//button[contains(text(),'Save')]"
    xpath_confirm_button = "//button[contains(normalize-space(.),'Confirm')]"
    xpath_cancel_button = "//button[contains(text(),'Cancel')]"
    xpath_add_button = "//button[normalize-space(text())='Add']"
    xpath_close_information_message = "//button[@class='btn-close']"
    xpath_page_loading_progress_bar = (
        "//div[@aria-label='Loading Progress']"
    )

    # Pop up variables
    xpath_success_message = "//*[contains(text(),'Success')]"
    xpath_error_popup = (
        "//*[contains(normalize-space(.),'Error')]/following-sibling::button"
    )
    xpath_unauthorized_popup = (
        "//*[contains(normalize-space(.),'Unauthorized')]/following-sibling::button"
    )
    xpath_information_message = "//*[contains(text(),'Reload the browser page to get the updated content.')]"
