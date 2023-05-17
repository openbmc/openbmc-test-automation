## OpenBMC GUI Test Setup Guide

The base needed packages for Linux distro.

- Python 3.x or latter
- Robot Framework ( base framework package )

Browser specific pacakges:

- Mozilla Firefox
- Robot Framework Selenium Library
- geckodriver
- Robotframework xvfb
- xvfbwrapper

## Tested On Linux
- RHEL
- Ubuntu

Last tested packages versions:
```
    Python 3.10.6
    Mozilla Firefox 112.0.2
    Robot Framework 5.0.1 (Python 3.10.6 on linux)
    robotframework-seleniumlibrary  6.0.0
    geckodriver                     0.32.2
    robotframework-xvfb             1.2.2
    xvfbwrapper                     0.2.9
```

## Installation Setup Guide

- Python Installation: Please follow the documented procedure available.
- Firefox Installation: Please follow the documented procedure available.
- geckodriver installation: Please follow the documented procedure available.  [Firfox Geckodriver](https://github.com/mozilla/geckodriver/releases)

The recommended installation method is using pip:

```
    pip install --upgrade robotframework
```

```
    pip install --upgrade robotframework-seleniumlibrary
```

```
    pip install --upgrade xvfbwrapper
```

```
    pip install --upgrade robotframework-xvfb
```
