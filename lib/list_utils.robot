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
