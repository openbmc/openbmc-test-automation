*** Settings ***

Documentation    Module to test IPMI asset tag functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot

Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Set Asset Tag With Valid String Length
    [Documentation]  Set asset tag with valid string length and verify.
    [Tags]  Set_Asset_Tag_With_Valid_String_Length
    # Allowed MAX characters length for asset tag name is 63.
    ${random_string}=  Generate Random String  63
    Run Keyword  Run IPMI Standard Command  dcmi set_asset_tag ${random_string}

    ${asset_tag}=  Run Keyword  Run IPMI Standard Command  dcmi asset_tag
    Should Contain  ${asset_tag}  ${random_string}


Set Asset Tag With Invalid String Length
    [Documentation]  Verify error while setting invalid asset tag via IPMI.
    [Tags]  Set_Asset_Tag_With_Invalid_String_Length
    # Any string more than 63 character is invalid for asset tag.
    ${random_string}=  Generate Random String  64

    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  dcmi set_asset_tag ${random_string}
    Should Contain  ${resp}  Parameter out of range  ignore_case=True

Verify IPMI Inband Network Configuration
    [Documentation]  Run the standard IPMI command in-band
    ...              to set Network Configuration.
    [Tags]  Verify_IPMI_Inband_Network_Configuration

    ${default_ip}  ${default_netmask}  ${default_gateway}=
    ...  Get IPMI Inband Network Configuration  file_name=lan_var.txt

    Set IPMI Inband Network Configuration  10.10.10.10  255.255.255.0  10.10.10.10
    BuiltIn.Sleep  10

    ${changed_ip}  ${changed_netmask}  ${changed_gateway}=
    ...  Get IPMI Inband Network Configuration  file_name=lan_var.txt  login=${False}
    Should Be Equal As Strings  "10.10.10.10"  "${changed_ip}"
    Should Be Equal As Strings  "255.255.255.0"  "${changed_netmask}"
    Should Be Equal As Strings  "10.10.10.10"  "${changed_gateway}"

    Set IPMI Inband Network Configuration
    ...  ${default_ip}  ${default_netmask}  ${default_gateway}


*** Keywords ***

Set IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band
    ...              and set the IP configuration.
    [Arguments]  ${ip}  ${netmask}  ${gateway}  ${login}=${False}

    Run Inband IPMI Standard Command
    ...  lan set 1 ipsrc static  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set 1 ipaddr ${ip}  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set 1 netmask ${netmask}  login_host=${login}
    Run Inband IPMI Standard Command
    ...  lan set 1 defgw ipaddr ${gateway}  login_host=${login}

Get IPMI Inband Network Configuration
    [Documentation]  Run sequence of standard IPMI command in-band
    ...              and set the IP configuration.
    [Arguments]  ${file_name}  ${login}=${True}

    ${out}=  Run Inband IPMI Standard Command  lan print  login_host=${login}
    Create Binary File  ${EXECDIR}${/}${file_name}  ${out}

    ${ip}=
    ...  Run  cat ${EXECDIR}${/}${file_name}|awk -F: 'NR==9{print$2}'|sed 's/ //g'
    ${netmask}=
    ...  Run  cat ${EXECDIR}${/}${file_name}|awk -F: 'NR==10{print$2}'|sed 's/ //g'
    ${gateway}=
    ...  Run  cat ${EXECDIR}${/}${file_name}|awk -F: 'NR==12{print$2}'|sed 's/ //g'
    @{list}=  BuiltIn.Create List  ${ip}  ${netmask}  ${gateway}

    Run  rm ${EXECDIR}${/}${file_name}

    [Return]  @{list}
