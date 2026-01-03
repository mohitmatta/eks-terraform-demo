#!/bin/bash
cd /flask
export TC_DYNAMO_TABLE=stocks
/usr/local/bin/gunicorn -b 0.0.0.0 main:stocks_app
tail -f /dev/null
