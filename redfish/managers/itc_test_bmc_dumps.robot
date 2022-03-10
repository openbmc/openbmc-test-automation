*** Settings ***

Documentation       Test BMC dump functionality of OpenBMC.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/dump_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Redfish.Login
Test Setup          Redfish Delete All BMC Dumps
Test Teardown       Test Teardown Execution

*** Variables ***

# Total size of the dump in kilo bytes
${BMC_DUMP_TOTAL_SIZE}        ${419430400} 


# Minimum space required for one bmc dump in kilo bytes
${BMC_DUMP_MIN_SPACE_REQD}   ${20}

*** Test Cases ***


Verify BMCdump Generation In Standalone Configuration For 24 Hours
    [Documentation]  Verify BMCdump Generation Continuously In Standalone Configuration
    [Tags]  Verify_BMCdump_Generation_In_Standalone Configuration_For_24_Hours

    # It is estimated 800  iterations of dum generations take 24 hours.
    Redfish Delete All BMC Dumps    
    FOR  ${n}  IN RANGE  0  800
      Create User Initiated BMC Dump Via Redfish
      # It is estimated that there is no disk space overhead issue in these iterations.
      # However, as precaustionary measure, a check is added.  
      ${dump_space}=  Get Disk Usage For Dumps
      Exit For Loop If  ${dump_space} >= (${BMC_DUMP_TOTAL_SIZE} - ${BMC_DUMP_MIN_SPACE_REQD}) 
    END
    Redfish Delete All BMC Dumps



*** Keywords ***

Get Disk Usage For Dumps
    [Documentation]  Return disk usage in kilobyte for BMC dumps.

    ${usage_output}  ${stderr}  ${rc}=  BMC Execute Command  du -s /var/lib/phosphor-debug-collector/dumps

    # Example of output from above BMC cli command.
    # $ du -s /var/lib/phosphor-debug-collector/dumps
    # 516    /var/lib/phosphor-debug-collector/dumps

    ${usage_output}=  Fetch From Left  ${usage_output}  /
    ${usage_output}=  Convert To Integer  ${usage_output}

    [return]  ${usage_output}


Test Teardown Execution
    [Documentation]  Do test teardown operation.

    FFDC On Test Case Fail
    Close All Connections
