#!/usr/bin/python

# Contains xpaths and related string constants of Security scanning.

class variables():

    # xpaths for security scanning.

    BROWSER=          "ff"
    nessus_logo=      "xpath=//*[@id='logo']"
    running_status=   "xpath=//*[@id='main']/div[1]/section/div[2]/table/tbody/tr[1]/td[4]"
    username=         "test"
    password=         "passw0rd"
    xpath_exception=  "id=advancedButton"
    xpath_add_exce=   "id='exceptionDialogButton'"
    xpath_uname=      "xpath=//*[@id='nosession']/form/input[1]"
    xpath_password=   "xpath=//*[@id='nosession']/form/input[2]"
    xpath_signin=     "xpath=//*[@id='sign-in']"

    xpath_search=     "xpath=//*[@id='searchbox']/input"
    scan_name=        "OP Full Scan"
    xpath_op_scan=    "xpath=//*[@id='main']/div[1]/section/table/tbody"
    xpath_launch=     "xpath=//*[@id='scans-show-launch-dropdown']/span"
    xpath_default=    "xpath=//*[@id='scans-show-launch-default']"
    xpath_status=     "xpath=//*[@id='main']/div[1]/section/div[2]/table/tbody/tr[1]/td[4]"
    obmc_BMC_URL=  "https://openbmc-test.mybluemix.net/#/login"
    obmc_uname=  "username"
    obmc_user_name=  "root"
    obmc_password=  "0penBmc"
    #obmc_login_button=  "login__submit"
    obmc_login_button=  "xpath=//*[@id='login__submit']"
    obmc_passwordelt=  "password"
    obmc_power_on=  "power__power-on"
    obmc_warm_boot=  "power__warm-boot"
    obmc_cold_boot=  "power__cold-boot"
    obmc_orderly_shutdown=  "power__soft-shutdown"
    obmc_immediate_shutdown=  "power__hard-shutdown"
    obmc_logout=  "header"
    power_operations=  "4"
    warm_boot=  "3"
    cold_boot=  "4"
    shut_down=  "5"
    power_off=  "6"
    confirm_msg=  "2"
    yes=  "1"
    header_wrapper=  "2"
    header_wrapper_elt=  "2"
