### To check common code misspellings, syntax and standard checks.

**Requirement Python 3.x and above**

It is recommended to run these tools against the code before pushing to gerrit.
It helps catches those silly mistake earlier before the review.

### 1. codespell

Project [codespell](https://github.com/codespell-project/codespell) designed
primarily for checking misspelled words in source code

```
    $ pip install codespell
```

Example:

```
    $ codespell templates/test_openbmc_setup.robot
    templates/test_openbmc_setup.robot:13: setings ==> settings
```

### 2. robotframework-lint

Project [robotframework-lint](https://pypi.org/project/robotframework-lint/) for
static analysis for robot framework plain text files.

```
    $ pip install –upgrade robotframework-lint
```

Example:

```
    $ rflint redfish/service_root/test_service_root_security.robot
    + redfish/service_root/test_service_root_security.robot
    W: 19, 100: Line is too long (exceeds 100 characters) (LineTooLong)
```

You can refer a script with example as well
[custom rules](https://github.com/openbmc/openbmc-test-automation/blob/master/robot_custom_rules.py)

### 3. robot tags check

Project [check_robot_tags](https://github.com/generatz/check_robot_tags) Checks
that Tags are equivalent to test case names or task names.

Example:

```
    $ git clone https://github.com/generatz/check_robot_tags
    $ cd check_robot_tags/

    $ awk -f check_robot_tags.awk ~/openbmc-test-automation/redfish/test_xit.robot
     --- /home/openbmc-test-automation/redfish/test_xit.robot:
     Verify No BMC Dump And Application Failures In BMC
     Iam_different_here
```

### 4. Black

Project [Black](https://pypi.org/project/black/) is the Python code formatter.
It requires Python 3.8+ to run.

```
    $ pip install git+https://github.com/psf/black
```

Example:

```
    python -m black lib/utils.py

    - To limit the line range use

    python -m black -l 80 lib/utils.py
```
