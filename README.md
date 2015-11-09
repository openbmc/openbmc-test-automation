#openbmc-automation

Quickstart
----------

To run openbmc-automation first you need to install the prerequisite python
packages which will help to invoke tests through tox.

Install the python dependencies for tox
```shell
    $easy_install tox pip
```

Initilize the following environment variable which will used while testing
```shell
    $ export OPENBMC_HOST=<openbmc machine ip address>
    $ export OPENBMC_PASSWORD=<openbmc username>
    $ export OPENBMC_USERNAME=<openbmc password>
```

Run tests
```shell
    $ tox -e tests
```

It can also be run by pasing variables from the cli...
```shell
    $  pybot -v OPENBMC_HOST:<ip> -v OPENBMC_USERNAME:root -v OPENBMC_PASSWORD:0penBmc 
```
