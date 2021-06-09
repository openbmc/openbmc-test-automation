### To check common code misspellings, syntax and standard checks.

**Requirement Python 3.x and above**

It is recommended to run these tools against the code before pushing to gerrit.
It helps catches those silly mistake earlier before the review.

### 1. codespell

Project [codespell](https://github.com/codespell-project/codespell) designed primarily for checking misspelled words in source code

```
    $ pip install codespell
```

Example:
```
    $ codespell templates/test_openbmc_setup.robot
    templates/test_openbmc_setup.robot:13: setings ==> settings
```

### 2. robotframework-lint

Project [robotframework-lint](https://pypi.org/project/robotframework-lint/) for static analysis for robot framework plain text files.

```
    $ pip install –upgrade robotframework-lint
 ```

Example:
```
    $ rflint redfish/service_root/test_service_root_security.robot
    + redfish/service_root/test_service_root_security.robot
    W: 19, 100: Line is too long (exceeds 100 characters) (LineTooLong)
```

You can refer a script with example as well [custom rules](https://github.com/openbmc/openbmc-test-automation/blob/master/robot_custom_rules.py)
