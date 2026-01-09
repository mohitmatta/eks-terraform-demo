from flask import Flask, jsonify, abort, Response, request
import os
import json
import boto3
from boto3.dynamodb.conditions import Key
import logging
import sys
from decimal import Decimal

# Obtaining the current machine's hostname for diagnostic purposes or status monitoring
instance_id = os.popen("hostname -I").read().strip()

# Obtaining the DynamoDB table name via environment variables
dynamo_table_name = os.environ.get('TC_DYNAMO_TABLE', 'payments')

# Setting up the DynamoDB resource
dyndb_client = boto3.resource('dynamodb', region_name='us-east-1')
dyndb_table = dyndb_client.Table(dynamo_table_name)

# Setting up the Flask web application
app = Flask(__name__)

# Configure logging to work with Gunicorn
if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)

# Helper class to convert a DynamoDB item to JSON.
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return str(obj)
        return super(DecimalEncoder, self).default(obj)

@app.route('/')
def hello():
    return Response(status=200)

@app.route('/gtg', methods=['GET'])
def gtg():
    return Response(status=200)

@app.route('/payments', methods=['GET'])
def get_payments():
    try:
        items = dyndb_table.scan()['Items']
        return Response(
            json.dumps(items, cls=DecimalEncoder),
            status=200,
            mimetype="application/json"
        )
    except Exception as e:
        app.logger.error(f"Error fetching payments: {e}", exc_info=True)
        return f"Error: {str(e)}", 500

@app.route('/payments/<payment_id>', methods=['GET'])
def get_payment(payment_id):
    try:
        response = dyndb_table.query(
            KeyConditionExpression=Key('id').eq(payment_id)
        )
        if len(response['Items']) == 0:
            return "Payment not found", 404
        
        return Response(
            json.dumps(response['Items'], cls=DecimalEncoder),
            status=200,
            mimetype="application/json"
        )
    except Exception as e:
        app.logger.error(f"Error fetching payment {payment_id}: {e}", exc_info=True)
        return f"Error: {str(e)}", 500
