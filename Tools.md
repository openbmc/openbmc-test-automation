## Tools available in OpenBMC Test Automation ##

**The Hardware Test Executive (HTX):**

HTX is a suite of test tools for hardware validation of OpenPOWER system
and we use widely for stressing system in automation for test suites under
`systest/`. Refer [README](https://github.com/open-power/HTX)


**This document describes the tools available in the /tools directory.**

* Obtain a copy of GitHub issues in CSV format:

    Note: You will be prompted to enter your GitHub password.

    Usage:
    ```
    $ cd tools/
    $ python github_issues_to_csv <github user> <github repo>
    ```
    Example for getting openbmc issues:
    ```
    $ python github_issues_to_csv <github user>  openbmc/openbmc
    ```
    Example for getting openbmc-test-automation issues:
    ```
    $ python github_issues_to_csv <github user>  openbmc/openbmc-test-automation
    ```

* Generate Robot test cases documentation:

    Usage:
    ```
    $ ./tools/generate_test_document <Robot test directory path> <test case document file path>
    ```

    Example for generating tests cases documentation for tests directory:
    ```
    $ ./tools/generate_test_document tests testsdirectoryTCdocs.html
    ```

    Example for generating tests cases documentation:
    Note: Invoke the tool without arguments:
    ```
    $ ./tools/generate_test_document
    ```
