*** Settings ***
Documentation  This module contains keywords for list manipulation.
Library  Collections

*** Keywords ***
Smart Combine Lists
    [Documentation]  Combine all valid list arguments and return the result.
    [Arguments]  @{lists}

    # Description of argument(s):
    # lists  A list of lists to be combined.  Any item in this list which is
    #        NOT a list will be removed.

    ${list_size}=  Get Length  ${lists}
    ${index}=  Set Variable  ${0}

    FOR  ${arg}  IN  @{lists}
      ${type_arg}=  Evaluate  str(type($lists[${index}])).split("'")[1]
      Run Keyword If  '${type_arg}' != 'list'  Run Keywords  Remove From List  ${lists}  ${index}  AND
      ...  Continue For Loop
      ${index}=  Evaluate  ${index}+1
    END

    ${new_list}=  Combine Lists  @{lists}

    [Return]  ${new_list}


Intersect Lists
    [Documentation]  Intersects the two lists passed in. Returns a list of
    ...  values common to both lists with no duplicates.
    [Arguments]  ${list1}  ${list2}

    # list1      The first list to intersect.
    # list2      The second list to intersect.

    ${length1}=  Get Length  ${list1}
    ${length2}=  Get Length  ${list2}

    @{intersected_list}  Create List

    @{larger_list}=  Set Variable If  ${length1} >= ${length2}  ${list1}
    ...                               ${length1} < ${length2}  ${list2}
    @{smaller_list}=  Set Variable If  ${length1} >= ${length2}  ${list2}
    ...                                ${length1} < ${length2}  ${list1}

    FOR  ${element}  IN  @{larger_list}
      ${rc}=  Run Keyword and Return Status  List Should Contain Value  ${smaller_list}  ${element}
      Run Keyword If  '${rc}' == 'True'  Append to List  ${intersected_list}  ${element}
    END

    @{intersected_list}=  Remove Duplicates  ${intersected_list}

    [Return]  @{intersected_list}


Subtract Lists
    [Documentation]  Subtract list 2 from list 1 and return the result.
    #  Return list contain items from the list 1 which are not present
    #  in the list 2.
    [Arguments]  ${list1}  ${list2}
    # Description of argument(s):
    # list1      The base list which is to be subtracted from.
    # list2      The list which is to be subtracted from list1.

    ${diff_list}=  Create List
    FOR  ${item}  IN  @{list1}
        ${status}=  Run Keyword And Return Status
        ...  Should Contain  ${list2}  ${item}
        Run Keyword If  '${status}' == '${False}'
        ...  Append To List  ${diff_list}  ${item}
    END

    [Return]  ${diff_list}
