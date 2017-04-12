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
    obmc_xpath_uname=  "xpath=//*[@id='username']"
    obmc_user_name=  "root"
    obmc_password=  "0penBmc"
    obmc_xpath_login_button=  "xpath=//*[@id='login__submit']"
    obmc_xpath_password=  "xpath=//*[@id='password']"
    obmc_xpath_power_on=  "xpath=//*[@id='power__power-on']"
    obmc_xpath_warm_boot=  "xpath=//*[@id='power__warm-boot']"
    obmc_xpath_cold_boot=  "xpath=//*[@id='power__cold-boot']"
    obmc_xpath_orderly_shutdown=  "xpath=//*[@id='power__soft-shutdown']"
    obmc_xpath_immediate_shutdown=  "xpath=//*[@id='power__hard-shutdown']"
    obmc_xpath_logout=  "xpath=//*[@id='header']/a"
    obmc_xpath_power_operations=  "xpath=//*[@id='header__wrapper']/div/div[2]/a[2]/span"
    obmc_xpath_immediate_shutdown_confirmation=  "//*[@id='power-operations']/div[4]/div[6]/confirm/div"
    obmc_xpath_yes_button=  "xpath=//*[@id='power-operations']/div[4]/div[6]/confirm/div/div[2]/button[1]"
    obmc_xpath_warm_boot_confirmation=  "xpath=//*[@id='power-operations']/div[4]/div[3]/confirm/div/div[1]/p[1]"
    obmc_xpath_yes_button_warm_boot=  "xpath=//*[@id='power-operations']/div[4]/div[3]/confirm/div/div[2]/button[1]"
    obmc_xpath_cold_boot_confirmation=  "xpath=//*[@id='power-operations']/div[4]/div[4]/confirm/div/div[1]"
    obmc_xpath_yes_button_cold_boot=  "xpath=//*[@id='power-operations']/div[4]/div[4]/confirm/div/div[2]/button[1]"
    obmc_xpath_orderly_shutdown_confirmation=  "xpath=//*[@id='power-operations']/div[4]/div[5]/confirm/div/div"
    obmc_xpath_yes_button_orderly_shutdown=  "xpath=//*[@id='power-operations']/div[4]/div[5]/confirm/div/div[2]/button[1]"


