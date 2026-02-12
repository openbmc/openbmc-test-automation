## OpenBMC GUI Test Setup Guide

The base needed packages for Linux distro.

- Python 3.x or latter
- Robot Framework ( base framework package )

Browser specific packages:

- Mozilla Firefox
- Robot Framework Selenium Library
- geckodriver
- Robotframework xvfb
- xvfbwrapper
- Robot Framework AngularJS Library

## Tested On Linux

- RHEL
- Ubuntu

Last tested packages versions:

```
    Python                          3.12
    Selenium                        4.8.2
    Mozilla Firefox                 112.0.2
    Robot Framework                 7.2.2
    robotframework-seleniumlibrary  6.0.0
    geckodriver                     0.32.2
    robotframework-xvfb             1.2.2
    xvfbwrapper                     0.2.9
    webdriver-manager               4.0.2
```

## Installation Setup Guide

- Python Installation: Please follow the documented procedure available.

- Firefox Installation: Please follow the documented procedure available.

- geckodriver installation: Please follow the documented procedure available.
  [Firefox Geckodriver](https://github.com/mozilla/geckodriver/releases)

The recommended installation method is using pip:

```
    pip install --upgrade robotframework
    pip install --upgrade robotframework-seleniumlibrary
    pip install --upgrade xvfbwrapper
    pip install --upgrade robotframework-xvfb
    pip install --upgrade robotframework-angularjs
```

## Geckodriver Supported Platforms

Mapping between geckodriver releases, and required versions of Selenium and
Firefox:
[Geckodriver Supported platforms](https://firefox-source-docs.mozilla.org/testing/geckodriver/Support.html#supported-platforms)
