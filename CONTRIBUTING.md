Contributing to OpenBMC Test Automation
=======================================
Guide to working on OpenBMC test automation. This document will always be a
work-in-progress, feel free to propose changes.

Submitting changes via Gerrit server
------------------------------------
-   Reference [openbmc docs](https://github.com/openbmc/docs/blob/master/contributing.md#submitting-changes-via-gerrit-server)

Robot Coding Guidelines
-----------------------
-   For this project, we will write Robot keyword definitions in either Robot
    or python.  Robot code should be quite simple.  Therefore, if algorithm
    in question is the least bit complex, please write it in python.
-   Robot supports delimiting cells with either two or more spaces or with a
    pipe symbol (e.g. "\|"). Our team has chosen to use spaces rather than the
    pipe character. Make sure all space delimiters in robot code are the
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

