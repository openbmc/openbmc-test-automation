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

    obmc_BMC_URL=     "http://localhost:8080/#/login"
    obmc_bmc_ip=      "xpath=//*[@id='login__form']/input[1]"
    obmc_uname=       "username"
    obmc_user_name=   "root"
    obmc_password=    "0penBmc"

    # Power Operation Elements needed for power on
    header_wrapper=  "3"
    header_wrapper_elt=  "3"

    # Power Operation Elements needed for power operations confirmation
    power_operations=  "3"
    warm_boot=  "3"
    cold_boot=  "4"
    shut_down=  "5"
    power_off=  "6"
    confirm_msg=  "2"
    yes=  "1"
