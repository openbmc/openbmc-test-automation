#!/usr/bin/python

# Contains xpaths and related string constants of Security scanning.


class variables():

    # xpaths for security scanning.

    BROWSER = "ff"
    nessus_logo = "xpath=//*[@id='logo']"
    running_status = "xpath=//*[@id='main']/div[1]/section/div[2]/table/tbody/tr[1]/td[4]"
    username = "test"
    password = "passw0rd"
    xpath_exception = "id=advancedButton"
    xpath_add_exce = "id='exceptionDialogButton'"
    xpath_uname = "xpath=//*[@id='nosession']/form/input[1]"
    xpath_password = "xpath=//*[@id='nosession']/form/input[2]"
    xpath_signin = "xpath=//*[@id='sign-in']"

    xpath_search = "xpath=//*[@id='searchbox']/input"
    scan_name = "OP Full Scan"
    xpath_op_scan = "xpath=//*[@id='main']/div[1]/section/table/tbody"
    xpath_launch = "xpath=//*[@id='scans-show-launch-dropdown']/span"
    xpath_default = "xpath=//*[@id='scans-show-launch-default']"
    xpath_status = "xpath=//*[@id='main']/div[1]/section/div[2]/table/tbody/tr[1]/td[4]"
