*** Settings ***
Documentation  Does random repeated IPLs based on the state of the machine. The
...  number of repetitions is designated by ${IPL_TOTAL}. Keyword names that are
...  listed in @{AVAIL_IPLS} become the selection of possible IPLs for the test.

Resource  ../lib/boot/boot_resource_master.robot
Resource  ../lib/dvt/obmc_call_points.robot
Resource  ../lib/dvt/obmc_driver_vars.txt
Resource  ../lib/list_utils.robot

*** Test Cases ***
Repeated Testing
    # Call the Main keyword to prevent any dots from appearing in the console
    # due to top level keywords.
    Main

*** Keywords ***
Main
    Log to Console  ${SUITE NAME}

    Do Test Setup
    Call Point Setup

    Log  Doing ${IPL_TOTAL} IPLs  console=True

    :FOR  ${IPL_COUNT}  IN RANGE  ${IPL_TOTAL}
    \  Log  ${\n}***Starting IPL ${IPL_COUNT+1} of ${IPL_TOTAL}***  console=True
    \  Validate Connection  alias=${master_alias}
    \  ${cur_state}=  Get Power State
    \  ${next_IPL}=  Select IPL  ${cur_state}
    \  Call Point Pre Boot
    \  Log  We are doing a ${next_IPL}${\n}  console=True
    \  Update Last Ten  ${next_IPL}
    \  Run Keyword and Continue On Failure  Run IPL  ${next_IPL}
    \  Call Point Post Boot
    \  Run Keyword If  '${IPL_STATUS}' == 'PASS'
    ...  Log  IPL_SUCCESS: "${next_IPL}" succeeded.  console=True
    ...          ELSE  Log  IPL_FAILED: ${next_IPL} failed.  console=True
    \  Update Run Table Values  ${next_IPL}
    \  Log  FFDC Dump requested!  console=True
    \  Log  ***Beginning dump of FFDC***  console=True
    \  Call Point FFDC
    \  Log Defect Information
    \  Log Last Ten
    \  Log FFDC Files
    \  Log  ***Finished dumping of FFDC***  console=True
    \  Call Point Stop Check
    \  Log FFDC Summary
    \  Log Run Table
    \  Log  ${\n}***Finished IPL ${IPL_COUNT+1} of ${IPL_TOTAL}***  console=True

Do Test Setup
    [Documentation]  Do any setup that needs to be done before running a series
    ...  of IPLs.

    Should Not Be Empty  ${AVAIL_IPLS}

    Setup Run Table
    Log  ***Start of status file for ${OPENBMC_HOST}***  console=True

Setup Run Table
    [Documentation]  For each available IPL, create a variable that stores the
    ...  number of passes and fails for each IPL.

    Log to Console  Setting up run table.

    :FOR  ${ipl}  IN  @{AVAIL_IPLS}
    \  Set Global Variable  ${${ipl}_PASS}  ${0}
    \  Set Global Variable  ${${ipl}_FAIL}  ${0}

Select IPL
    [Documentation]  Contains all of the logic for which IPLs can be chosen
    ...  given the inputted state. Returns the chosen IPL.
    [Arguments]  ${cur_state}

    # cur_state      The power state of the machine, either zero or one.

    ${ipl}=  Run Keyword If  ${cur_state} == ${0}  Select Power On
    ...  ELSE  Run Keyword If  ${cur_state} == ${1}  Select Power Off
    ...  ELSE  Run Keywords  Log to Console
    ...  **ERROR** BMC not in state to power on or off: "${cur_state}"  AND
    ...  Fatal Error

    [return]  ${ipl}

Select Power On
    [Documentation]  Randomly chooses an IPL from the list of Power On IPLs.

    @{power_on_choices}=  Intersect Lists  ${VALID_POWER_ON}  ${AVAIL_IPLS}

    ${length}=  Get Length  ${power_on_choices}

    # Currently selects the first IPL in the list of options, rather than
    # selecting randomly.
    ${chosen}=  Set Variable  @{power_on_choices}[0]

    [return]  ${chosen}

Select Power Off
    [Documentation]  Randomly chooses an IPL from the list of Power Off IPLs.

    @{power_off_choices}=  Intersect Lists  ${VALID_POWER_OFF}  ${AVAIL_IPLS}

    ${length}=  Get Length  ${power_off_choices}

    # Currently selects the first IPL in the list of options, rather than
    # selecting randomly.
    ${chosen}=  Set Variable  @{power_off_choices}[0]

    [return]  ${chosen}

Run IPL
    [Documentation]  Runs the selected IPL and marks the status when complete.
    [Arguments]  ${ipl_keyword}
    [Teardown]  Set Global Variable  ${IPL_STATUS}  ${KEYWORD STATUS}

    # ipl_keyword      The name of the IPL to run, which corresponds to the
    #                  keyword to run. (i.e "BMC Power On")

    Run Keyword  ${ipl_keyword}

Log Defect Information
    [Documentation]  Logs information needed for a defect. This information
    ...  can also be found within the FFDC gathered.

    Log  Copy this data to the defect:  console=True

Log Last Ten
    [Documentation]  Logs the last ten IPLs that were performed with their
    ...  starting time stamp.

    Log  ${\n}----------------------------------${\n}Last 10 IPLs${\n}
    ...  console=True
    :FOR  ${ipl}  IN  @{LAST_TEN}
    \  Log  ${ipl}  console=True
    Log  ----------------------------------${\n}  console=True

Log FFDC Files
    [Documentation]  Logs the files outputted during FFDC gathering.
    Log  This is where the list of FFDC files would be.  console=True

Log FFDC Summary
    [Documentation]  Logs finding from within the FFDC files gathered.
    Log  This is where the FFDC summary would go.  console=True

Log Run Table
    [Documentation]  Logs the table of IPLs that have passed and failed based on
    ...  the available IPLs, as well as the total passes and failures.

    Log  ${\n}IPL type${space*14}Pass${space*3}Fail  console=True
    Log  ==================================  console=True
    :FOR  ${ipl}  IN  @{AVAIL_IPLS}
    \  ${length}=  Get Length  ${ipl}
    \  ${space_num}=  Set Variable  ${24-${length}}
    \  Log  ${ipl}${space*${space_num}}${${ipl}_PASS}${space*5}${${ipl}_FAIL}
    ...  console=True
    Log  ==================================  console=True
    Log  Totals:${space*17}${IPL_PASSED}${space*5}${IPL_FAILED}${\n}
    ...  console=True

Update Run Table Values
    [Documentation]  Updates the table of IPLs that have passed and failed. See
    ...  the "Log Run Table" keyword for more information.
    [Arguments]  ${last_ipl}

    # last_ipl      The name of the last IPL that ran (i.e "BMC Power On").

    ${cur_value}=  Get Variable Value  ${${last_ipl}_${IPL_STATUS}}
    Set Global Variable  ${${last_ipl}_${IPL_STATUS}}  ${cur_value+1}
    ${total_value}=  Run Keyword If  '${IPL_STATUS}' == 'PASS'
    ...              Get Variable Value  ${IPL_PASSED}
    ...              ELSE  Get Variable Value  ${IPL_FAILED}
    Run Keyword If  '${IPL_STATUS}' == 'PASS'
    ...             Set Global Variable  ${IPL_PASSED}  ${total_value+1}
    ...             ELSE  Set Global Variable  ${IPL_FAILED}  ${total_value+1}

Update Last Ten
    [Documentation]  Updates the list of last ten IPLs
    [Arguments]  ${last_ipl}

    # last_ipl      The name of the last IPL that ran (i.e. "BMC Power On")

    ${time}=  Get Time
    Append to List  ${LAST_TEN}  ${time} - Doing "${last_ipl}"
