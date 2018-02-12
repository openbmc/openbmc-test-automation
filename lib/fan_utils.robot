*** Settings ***
Documentation     Utilities for fan tests.


*** Keywords ***

Is Fan Present And Functional
    [Documentation]  Return 1 if fan is present and functional, 0 otherwise.
    [Arguments]  ${fan}

    # Description of Argument(s):
    # fan    The name of the fan (i.e., fan0, fan1, fan2, or fan3).

    ${location}=  Catenate
    ...  /xyz/openbmc_project/inventory/system/chassis/motherboard/${fan}

    ${present}=  Read Attribute  ${location}  Present
    ${Functional}=  Read Attribute  ${location}  Functional
    Run Keyword If  ${present} and ${functional}  Return From Keyword  1
    Return From Keyword  0


Is Water Cooled
    [Documentation]  Return 1 if system is water cooled, 0 othersise.

    ${water_cooled}=  Read Attribute
    ...  /xyz/openbmc_project/inventory/system/chassis  WaterCooled
    [Return]  ${water_cooled}


Check Fan Count
    [Documentation]  Verify minimum number of fans.  Return
    ...  a list of fans found to be present and functional.
    [Arguments]  ${fans}

    # Description of Argument(s):
    # fans  This is a list which is built-up and returned, consisting of
    #       the names of the present and active fans found.

    # For a water cooled system.
    ${min_fans_water}=  Set Variable  2

    # For an air cooled system.
    ${min_fans_air}=  Set Variable  3

    # Add fan to the @{fans} list only if its a working fan.
    ${fans}=  Add To Fans List  fan0  ${fans}
    ${fans}=  Add To Fans List  fan1  ${fans}
    ${fans}=  Add To Fans List  fan2  ${fans}
    ${fans}=  Add To Fans List  fan3  ${fans}

    # The number of working fans found.
    ${num_fans}=  Get Length  ${fans}

    # Determine if system is water cooled.
    ${water_coooled}=  Is Water Cooled

    Rprintn
    Rpvars  water_coooled  num_fans

    # If water cooled must have at least min_fans_water fans, otherwise
    # issue Fatal Error and terminate testing.
    Run Keyword if  ${water_coooled} == 1 and ${num_fans} < ${min_fans_water}
    ...  Fatal Error
    ...  msg=Water cooled but less than ${min_fans_water} fans present.

    # If air cooled must have at least min_fans_air fans.
    Run Keyword if  ${water_coooled} == 0 and ${num_fans} < ${min_fans_air}
    ...  Fatal Error
    ...  msg=Air cooled but less than ${min_fans_air} fans present.

    [Return]  ${fans}


Add To Fans List
    [Documentation]  Append the fan name to the @{fans} fans list
    ...  if the fan is present and functional.  The updated @{fans}
    ...  is returned.
    [Arguments]  ${fan}  ${mylist}

    # Description of Argument(s):
    # fan      The name of the fan (e.g., fan0, fan1, fan2, or fan3).
    # mylist   If the fan is present and functional its name is added
    #          to this list.  The updated list is returned to the caller.

    ${present_and_functional}=  Is Fan Present And Functional  ${fan}
    Run Keyword If  ${present_and_functional}  Append To List
    ...  ${mylist}  ${fan}
    Rpvars  fan  present_and_functional
    [Return]  ${mylist}
