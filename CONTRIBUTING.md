Project Coding Guidelines
=========================

Robot Coding Guidelines
-----------------------

-   When creating keywords, whenever possible, write them in python rather than
    robot. Robot really isn't a good programming language. See the following
    links for support on this approach.
    https://esalagea.wordpress.com/2014/11/24/robot-framework-quit-writing-ugly-robot-code-just-write-proper-python/
    https://www.slideshare.net/pekkaklarck/robot-framework-dos-and-donts

-   Robot supports delimiting cells with either two or more spaces or with a pipe
    symbol (e.g. "\|"). Our team has chosen to use spaces rather than the pipe
    character. Make sure all space delimiters in robot code are the **minimum** of two
    spaces. There may be some exceptions to this rule.

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

