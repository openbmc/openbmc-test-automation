#openbmc-automation

Quickstart
----------

To run openbmc-automation first you need to install the prerequisite python
packages which will help to invoke tests through tox.

1. Install the python dependencies for tox
    $ easy_install tox pip

2. Initilize the following environment variable which will used while testing
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc username>
    $ export OPENBMC_USERNAME=<openbmc password>

3. Run tests
    $ tox -e tests
