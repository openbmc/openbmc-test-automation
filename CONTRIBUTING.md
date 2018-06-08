Contributing to OpenBMC Test Automation
=======================================
Guide to working on OpenBMC test automation. This document will always be a
work-in-progress, feel free to propose changes.

Submitting changes via Gerrit server
------------------------------------
-   Reference [OpenBMC CLA signers](https://github.com/openbmc/openbmc-tools/blob/master/emilyshaffer/cla-signers/cla-signers)
-   Reference [OpenBMC docs](https://github.com/openbmc/docs/blob/master/contributing.md#submitting-changes-via-gerrit-server)

Robot Coding Guidelines
-----------------------
-   For this project, we will write Robot keyword definitions in either Robot
    or Python.  Robot code should be quite simple.  Therefore, if the algorithm
    in question is the least bit complex, please write it in Python.
-   Observe a maximum line length of 79 characters.
-   Avoid trailing space at the end of any line of Robot code.
-   Avoid the use of tabs.
-   Robot supports delimiting cells with either two or more spaces or with a
    pipe symbol (e.g. "\|"). Our team has chosen to use spaces rather than the
    pipe character. Make sure all space delimiters in Robot code are the
    **minimum** of two spaces. There may be some exceptions to this rule.

    Exceptions to two-space delimiter rule:
    - When you wish to line up resource, library or variable values:
      ```
      Library         Lib1
      Resource        Resource1
      *** Variables ***
      ${var1}         ${EMPTY}
      ```
    - When you wish to line up fields for test templates:
      ```
      [Template]  Set System LED State
      # LED Name  LED State
      power       On
      power       Off
      ```
    - When you wish to indent if/else or loop bodies for visual effect:
      ```
      Run Keyword If  '${this}' == '${that}'
      ...    Log  Bla, bla...
      ...  ELSE
      ...    Run Keywords  Key1  parms
      ...    AND  Key2  parms
      ```
-   Use spaces to make conditions more readable:

    Correct example:
    ```
    Run Keyword If  '${var1}' == '${0}'  My Keyword
    ```
    Incorrect example:
    ```
    Run Keyword If  '${var1}'=='${0}'  My Keyword
    ```
-   When you define or call a Robot keyword, Robot pays no attention to spaces,
    underscores or case.  However, our team will observe the following
    conventions in both our definitions and our calls:
    - Separate words with single spaces.
    - Capitalize the first character of each word.
    - Capitalize all characters in any word that is an acronym (e.g. JSON, BMC,
      etc).

    Examples:
    ```
    *** Keywords ***

    This Is Correct

        # This keyword name is correct.

    this_is_incorrect

        # This keyword name is incorrect because of 1) the
        # underscores instead of spaces and 2) the failure to
        # capitalize each word in the keyword.

    soisthis

        # This keyword name is incorrect because of 1) a failure to
        # separate words with spaces and 2) a failure to capitalize
        # each word in the keyword.

    BMC Is An Acronym

        # This keyword name is correct.  Note that "BMC" is an
        # acronym and as such is entirely uppercase.
    ```
-   Documentation strings:
    -  Each documentation string should be phrased as an **English command**.
       Punctuate it correctly with the first word capitalized and a period at
       the end.

       Correct example:
        ```
        Boot BMC
            [Documentation]  Boot the BMC.
        ```
        Incorrect example:
        ```
        Boot BMC
            [Documentation]  This keyword boots the BMC.

            # The doc string above is not phrased as a command.
        ```
    -   Doc strings should be just one terse, descriptive sentence.
        Remember that this doc string shows up in the HTML log file.  Put
        additional commentary below in standard comment lines.

        Correct example:
        ```
        Stop SOL Console Logging

            [Documentation]  Stop system console logging and return log output.
        ```
        Incorrect example:
        ```
        Stop SOL Console Logging

            [Documentation]  Stop system console logging.  If there are multiple
            ...              system console processes, they will all be
            ...              stopped.  If there is no existing log file this
            ...              keyword will return an error message to that
            ...              effect (and write that message to targ_file_path,
            ...              if specified).  NOTE: This keyword will not fail
            ...              if there is no running system console process.

            # This doc string is way too long.
        ```
-   Tags:
    -   Create a tag for every test case with a tag name that mirrors the test case
        name as follows:
        ```
        Create Intermediate File

            [Tags]  Create_Intermediate_File
        ```
-   Description of argument(s):
    -   As shown in the following example, if your keyword has any arguments, include
        a "**Description of argument(s)**" section.  This effectively serves as the
        help text for anyone wanting to use or understand your keyword.  Include
        real data examples wherever possible and applicable.  Leave at least 2 spaces
        between the argument name and the description.  Align all description text as
        shown in the example below.

        Example:
        ```
        Get URL List
            [Documentation]  Return list of URLs under given URL.
            [Arguments]  ${openbmc_url}  ${policy}

            # Description of argument(s):
            # openbmc_url  URL for list operation (e.g.
            #              "/xyz/openbmc_project/inventory").
            # policy       Power restore policy (e.g "RESTORE_LAST_STATE",
            #              ${RESTORE_LAST_STATE}).
        ```
-   Variable assignments:

    When assigning a variable as output from a keyword, do not precede the
    equal sign with a space.

    Correct examples:
    ```
    ${var1}=  Set Variable  ${1}
    ${var1}=  My Keyword
    ```
    Incorrect examples:

    ```
    ${var1} =  Set Variable  ${1}
    ${var1} =  My Keyword
    ```
-   General variable naming conventions:
    -   Variable names should be lower case with few exceptions:
        -   Environment variables should be all upper case.
        -   Variables intended to be set by Robot -v parameters may be all
            upper case.
    -   Words within a variable name should be separated by underscores:

        Correct examples:
        ```
        ${host_name}
        ${program_pid}
        ```
        Incorrect examples:
        ```
        ${HostName}
        ${ProgramPid}
        ```
-   Special variable naming conventions.

    For certain very commonly used kinds of variables, please observe these
    conventions in order to achieve consistency throughout the code.

    -   hosts

        When a variable is intended to contain **either** an IP address **or**
        a host name (either long or short), please give it a suffix of "_host".

        Examples:
        ```
        openbmc_host
        os_host
        pdu_host
        openbmc_serial_host
        ```
    -   host names

        For host names (long or short, e.g. "bmc1" or "bmc1.example.com"), use
        a suffix of _host_name.

        Examples:
        ```
        openbmc_host_name
        os_host_name
        pdu_host_name
        openbmc_serial_host_name
        ```
    -   Short host names

        For short host names (e.g. "bmc1"), use a suffix of _host_short_name.

        Examples:
        ```
        openbmc_host_short_name
        os_host_short_name
        pdu_host_short_name
        openbmc_serial_host_short_name
        ```
    -   IP addresses

        For IP addresses, use a suffix of _ip.

        Example:
        ```
        openbmc_ip
        os_ip
        pdu_ip
        openbmc_serial_ip
        ```
    -   Files and directories:
        -   Files:
            -   If your variable is to contain only the file's name, use a suffix
                of _file_name.

                Examples:
                ```
                ffdc_file_name = "bmc1.170428.120200.ffdc"
                ```
            -   If your variable is to contain the path to a file, use a suffix of
                _file_path.  Bear in mind that a file path can be relative or
                absolute so that should not be a consideration in whether to use
                the "_file_path" suffix.

                Examples:
                ```
                status_file_path = "bmc1.170428.120200.status"
                status_file_path = "subdir/bmc1.170428.120200.status"
                status_file_path = "./bmc1.170428.120200.status"
                status_file_path = "../bmc1.170428.120200.status"
                status_file_path = "/home/user1/status/bmc1.170428.120200.status"
                ```
                To re-iterate, it doesn't matter whether the contents of the
                variable are a relative or absolute path (as shown in the
                examples above).  A file path is simply a value with enough
                information in it for the program to find the file.

            -   If the variable **must** contain an absolute path (which should be
                the rare case), use a suffix _abs_file_path.

        -   Directories:
            -   Directory variables should follow the same conventions as file
                variables.

            -   If your variable is to contain only the directory's name, use a
                suffix of _dir_name.

                Example:
                ```
                ffdc_dir_name = "ffdc"
                ```
            -   If your variable is to contain the path to a directory, use a
                suffix of _dir_path.  Bear in mind that a dir path can be
                relative or absolute so that should not be a consideration in
                whether to use _dir_path.

                Examples:
                ```
                status_dir_path = "status/"
                status_dir_path = "subdir/status"
                status_dir_path = "./status/"
                status_dir_path = "../status/"
                status_dir_path = "/home/user1/status/"
                ```
                To re-iterate, it doesn't matter whether the contents of
                the variable are a relative or absolute path (as shown in
                the examples above).  A dir path is simply a value with
                enough information in it for the program to find the
                directory.

            -   If the variable **must** contain an absolute path (which
                should be the rare case), use a suffix _abs_dir_path.
            -   IMPORTANT:  As a programming convention, do pre-
                processing on all dir_path variables to ensure that they
                contain a trailing slash.  If we follow that convention
                religiously, that when changes are made in other parts of
                the program, the programmer can count on the value having
                a trailing slash.  Therefore they can safely do this kind
                of thing:
                ```
                my_file_path = my_dir_path + my_file_name
                ```
    -   Setup/Teardown keywords

        Use standardized names for setup and teardown keywords:
        - Suite Setup Execution
        - Suite Teardown Execution
        - Test Setup Execution
        - Test Teardown Execution
-   Traditional comments (i.e. using the hashtag style comments)
    -   Please leave one space following the hashtag.
        ```
        #wrong

        # Right
        ```
    -   Please use proper English punction:
        -   Capitalize the first word in the sentence or phrase.
        -   End sentences (or stand-alone phrases) with a period.

    -   Do not keep commented out code in your program.  Instead, remove it
        entirely.

Python Coding Guidelines
-----------------------
-   The minimum required Python version is 2.7.x.
-   Run pep8 on all Python files and correct errors.

    Example as run from a Linux command line:
    ```
    pep8 my_pgm.py

    my_pgm.py:41:1: E302 expected 2 blank lines, found 1
    my_pgm.py:58:52: W291 trailing whitespace
    ```
-   Include doc strings in every function and follow the guidelines in
    https://www.python.org/dev/peps/pep-0257/.

    Example:
    ```
        r"""
        Return the function name associated with the indicated stack frame.

        Description of argument(s):
        stack_frame_ix                  The index of the stack frame whose
                                        function name should be returned.  If
                                        the caller does not specify a value,
                                        this function will set the value to 1
                                        which is the index of the caller's
                                        stack frame.  If the caller is the
                                        wrapper function "print_func_name",
                                        this function will bump it up by 1.
        """
    ```
-   As shown in the prior example, if your function has any arguments, include
    a "Description of argument(s)" section.  This effectively serves as the
    help text for anyone wanting to use or understand your function.  Include
    real data examples wherever possible and applicable.
-   Function definitions:
    -   Put each function parameter on its own line:
        ```
        def func1(parm1,

                  parm2):
        ```
-   Do not keep commented out code in your program.  Instead, remove it
    entirely.
-   When you define or call a Robot keyword, Robot pays no attention to spaces,
    underscores or case.  However, our team will observe the following
    conventions in both our definitions and our calls:
    - Separate words with single spaces.
    - Capitalize the first character of each word.
    - Capitalize all characters in any word that is an acronym (e.g. JSON, BMC,
      etc).

    Examples:
    ```
    *** Keywords ***

    This Is Correct

        # This keyword name is correct.

    this_is_incorrect

        # This keyword name is incorrect because of 1) the
        # underscores instead of spaces and 2) the failure to
        # capitalize each word in the keyword.

    soisthis

        # This keyword name is incorrect because of 1) a failure to
        # separate words with spaces and 2) a failure to capitalize
        # each word in the keyword.

    BMC Is An Acronym

        # This keyword name is correct.  Note that "BMC" is an
        # acronym and as such is entirely uppercase.
    ```
-   Documentation strings:
    -  Each documentation string should be phrased as an **English command**.
       Punctuate it correctly with the first word capitalized and a period at
       the end.

       Correct example:
        ```
        Boot BMC
            [Documentation]  Boot the BMC.
        ```
        Incorrect example:
        ```
        Boot BMC
            [Documentation]  This keyword boots the BMC.

            # The doc string above is not phrased as a command.
        ```
    -   Doc strings should be just one terse, descriptive sentence.
        Remember that this doc string shows up in the HTML log file.  Put
        additional commentary below in standard comment lines.

        Correct example:
        ```
        Stop SOL Console Logging

            [Documentation]  Stop system console logging and return log output.
        ```
        Incorrect example:
        ```
        Stop SOL Console Logging

            [Documentation]  Stop system console logging.  If there are multiple
            ...              system console processes, they will all be
            ...              stopped.  If there is no existing log file this
            ...              keyword will return an error message to that
            ...              effect (and write that message to targ_file_path,
            ...              if specified).  NOTE: This keyword will not fail
            ...              if there is no running system console process.

            # This doc string is way too long.
        ```
-   Tags:
    -   Create a tag for every test case with a tag name that mirrors the test case
        name as follows:
        ```
        Create Intermediate File

            [Tags]  Create_Intermediate_File
        ```
-   General variable naming conventions:
    -   Variable names should be lower case with few exceptions:
        -   Environment variables should be all upper case.
        -   Variables intended to be set by Robot -v parameters may be all
            upper case.
    -   Words within a variable name should be separated by underscores:

        Correct examples:
        ```
        ${host_name}
        ${program_pid}
        ```
        Incorrect examples:
        ```
        ${HostName}
        ${ProgramPid}
        ```
-   Special variable naming conventions.

    For certain very commonly used kinds of variables, please observe these
    conventions in order to achieve consistency throughout the code.

    -   hosts

        When a variable is intended to contain **either** an IP address **or**
        a host name (either long or short), please give it a suffix of "_host".

        Examples:
        ```
        openbmc_host
        os_host
        pdu_host
        openbmc_serial_host
        ```
    -   host names

        For host names (long or short, e.g. "bmc1" or "bmc1.example.com"), use
        a suffix of _host_name.

        Examples:
        ```
        openbmc_host_name
        os_host_name
        pdu_host_name
        openbmc_serial_host_name
        ```
    -   Short host names

        For short host names (e.g. "bmc1"), use a suffix of _host_short_name.

        Examples:
        ```
        openbmc_host_short_name
        os_host_short_name
        pdu_host_short_name
        openbmc_serial_host_short_name
        ```
    -   IP addresses

        For IP addresses, use a suffix of _ip.

        Example:
        ```
        openbmc_ip
        os_ip
        pdu_ip
        openbmc_serial_ip
        ```
-   Files and directories:
    -   Files:
        -   If your variable is to contain only the file's name, use a suffix
            of _file_name.

            Examples:
            ```
            ffdc_file_name = "bmc1.170428.120200.ffdc"
            ```
        -   If your variable is to contain the path to a file, use a suffix of
            _file_path.  Bear in mind that a file path can be relative or
            absolute so that should not be a consideration in whether to use
            the "_file_path" suffix.

            Examples:
            ```
            status_file_path = "bmc1.170428.120200.status"
            status_file_path = "subdir/bmc1.170428.120200.status"
            status_file_path = "./bmc1.170428.120200.status"
            status_file_path = "../bmc1.170428.120200.status"
            status_file_path = "/home/user1/status/bmc1.170428.120200.status"
            ```
            To re-iterate, it doesn't matter whether the contents of the
            variable are a relative or absolute path (as shown in the
            examples above).  A file path is simply a value with enough
            information in it for the program to find the file.

        -   If the variable **must** contain an absolute path (which should be
            the rare case), use a suffix _abs_file_path.

    -   Directories:
        -   Directory variables should follow the same conventions as file
            variables.

        -   If your variable is to contain only the directory's name, use a
            suffix of _dir_name.

            Example:
            ```
            ffdc_dir_name = "ffdc"
            ```
        -   If your variable is to contain the path to a directory, use a
            suffix of _dir_path.  Bear in mind that a dir path can be
            relative or absolute so that should not be a consideration in
            whether to use _dir_path.

            Examples:
            ```
            status_dir_path = "status/"
            status_dir_path = "subdir/status"
            status_dir_path = "./status/"
            status_dir_path = "../status/"
            status_dir_path = "/home/user1/status/"
            ```
            To re-iterate, it doesn't matter whether the contents of
            the variable are a relative or absolute path (as shown in
            the examples above).  A dir path is simply a value with
            enough information in it for the program to find the
            directory.

        -   If the variable **must** contain an absolute path (which
            should be the rare case), use a suffix _abs_dir_path.
        -   IMPORTANT:  As a programming convention, do pre-
            processing on all dir_path variables to ensure that they
            contain a trailing slash.  If we follow that convention
            religiously, that when changes are made in other parts of
            the program, the programmer can count on the value having
            a trailing slash.  Therefore they can safely do this kind
            of thing:
            ```
            my_file_path = my_dir_path + my_file_name
            ```
-   Traditional comments (i.e. using the hashtag style comments)
    -   Please leave one space following the hashtag.
        ```
        #wrong

        # Right
        ```
    -   Please use proper English punction:
        -   Capitalize the first word in the sentence or phrase.
        -   End sentences (or stand-alone phrases) with a period.

    -   Do not keep commented out code in your program.  Instead, remove it
        entirely.

Python Coding Guidelines
-----------------------
-   Run pep8 on all Python files and correct errors.

    Example as run from a Linux command line:
    ```
    pep8 my_pgm.py

    my_pgm.py:41:1: E302 expected 2 blank lines, found 1
    my_pgm.py:58:52: W291 trailing whitespace
    ```
-   Include doc strings in every function and follow the guidelines in
    https://www.python.org/dev/peps/pep-0257/.

    Example:
    ```
        r"""
        Return the function name associated with the indicated stack frame.

        Description of argument(s):
        stack_frame_ix                  The index of the stack frame whose
                                        function name should be returned.  If
                                        the caller does not specify a value,
                                        this function will set the value to 1
                                        which is the index of the caller's
                                        stack frame.  If the caller is the
                                        wrapper function "print_func_name",
                                        this function will bump it up by 1.
        """
    ```
-   As shown in the prior example, if your function has any arguments, include
    a "Description of argument(s)" section.  This effectively serves as the
    help text for anyone wanting to use or understand your function.  Include
    real data examples wherever possible and applicable.
-   Function definitions:
    -   Put each function parameter on its own line:
        ```
        def func1(parm1,

                  parm2):
        ```
-   Do not keep commented out code in your program.  Instead, remove it
    entirely.

Template Usage Guidelines
-------------------------
We have several templates in the templates/ sub-directory. If there is a
template that applies to your programming situation (Python, bash, etc.),
it should be used to create new programs as in the following example

- Example:

    ```
    $ cd templates
    $ cp python_pgm_template ../bin/my_new_program
    ```

These templates have much of your preliminary work done for you and will help
us all follow a similar structure.

- Features:
    - Help text and arg parsing started for you.
    - Support for "stock" parameters like "quiet", "debug", "test_mode".
    - "exit_function" and "signal_handler" defined.
    - "validate_parms" function pre-created.
    - "main" function follows conventional startup sequence:

        ```
            if not gen_get_options(parser, stock_list):
                return False

            if not validate_parms():
                return False

            qprint_pgm_header()

            # Your code here.
        ```
