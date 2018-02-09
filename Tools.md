## Tools available in OpenBMC Test Automation ##

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
    $ ./generate_test_document <Robot test directory path> <test case document file path>
    ```

    Example for generating tests cases documentation for tests directory:
    ```
    $ ./generate_test_document tests testsdirectoryTCdocs.html
    ```

    Example for generating tests cases documentation:
    Note: Invoke the tool without arguments:
    ```
    $ ./generate_test_document
    ```
