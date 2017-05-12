*** Settings ***
Documentation  This module contains keywords for list manipulation.
Library  Collections

*** Keywords ***
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

    :FOR  ${element}  IN  @{larger_list}
    \  ${rc}=  Run Keyword and Return Status  List Should Contain Value  ${smaller_list}
    ...  ${element}
    \  Run Keyword If  '${rc}' == 'True'  Append to List  ${intersected_list}
    ...  ${element}

    @{intersected_list}=  Remove Duplicates  ${intersected_list}

    [Return]  @{intersected_list}

Subtract List
    [Documentation]  Subtracts the two lists passed in. Returns a list with
    ...  items from the first list which are not present in the second list.
    [Arguments]  ${list1}  ${list2}

    # list1      The first list to subtract.
    # list2      The second list to subtract.

    ${diff_list}=  Create List
    :FOR  ${item}  IN  @{list1}
    \  ${status}=  Run Keyword And Return Status  Should Contain  ${list2}  ${item}
    \  Run Keyword If  '${status}' == '${False}'
    ...  Append To List  ${diff_list}  ${item}

    [Return]  ${diff_list}
