*** Settings ***

*** Keywords ***
Intersect Lists
    [Documentation]  Intersects the two lists passed in. Returns a list of
    ...  values common to both lists.
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
    \  ${rc}=  Search List  ${element}  ${smaller_list}
    \  Run Keyword If  '${rc}' == 'True'  Append to List  ${intersected_list}
    ...  ${element}

    [return]  @{intersected_list}

Search List
    [Documentation]  Searches a list for an element. Returns "True" if element
    ...  exists in the list.  Otherwise, returns "False".
    [Arguments]  ${search_element}  ${search_list}

    # search_element      The element to search the list for.
    # search_list         The list in which to search for the element.

    ${rc}=  Set Variable  '${EMPTY}'

    :FOR  ${element}  IN  @{search_list}
    \  ${rc}=  Set Variable If  '${element}' == '${search_element}'  ${TRUE}
    ...                         '${element}' == '${search_element}'  ${FALSE}
    \  Exit For Loop If  '${element}' == '${search_element}'

    [return]  ${rc}
