#!/bin/bash

/opt/status-page/venv/bin/gunicorn --pid /var/tmp/status-page.pid --pythonpath /opt/status-page/statuspage --config /opt/status-page/gunicorn.py statuspage.wsgi --daemon

nginx -g 'daemon off;'