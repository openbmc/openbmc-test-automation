#!/usr/bin/python
import logging
import warnings
try:
    import httplib
except ImportError:
    import http.client

warnings.filterwarnings("ignore")

# Hijack the HTTP lib logger message and Log only once
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.CRITICAL)
requests_log.propagate = False


class disable_warning_urllib():
    def do_nothing():
        return
