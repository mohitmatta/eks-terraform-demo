#!/bin/bash
cd /flask
export TC_DYNAMO_TABLE=stocks
/usr/local/bin/gunicorn -b 0.0.0.0 --access-logfile - --error-logfile - --log-level debug --capture-output main:stocks_app