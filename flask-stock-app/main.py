import json
import os
from flask import Flask, Response, request
import boto3
from boto3.dynamodb.conditions import Key

# Obtaining the current machine's hostname for diagnostic purposes or status monitoring
instance_id = os.popen("hostname -I").read().strip()

# Obtaining the DynamoDB table name via environment variables, with a fallback default
# Set TC_DYNAMO_TABLE in the environment to define the specific table name.
dynamo_table_name = os.environ.get('TC_DYNAMO_TABLE', 'Stocks')

# Setting up the DynamoDB resource and table instance with boto3
# Verify that AWS credentials and region settings are correctly configured.
dyndb_client = boto3.resource('dynamodb', region_name='us-east-1')
dyndb_table = dyndb_client.Table(dynamo_table_name)

# Setting up the Flask web application
stocks_app = Flask(__name__)

# Fallback route for handling unspecified requests
@stocks_app.route('/', methods=['GET'])
def default():
    """
    Standard endpoint that provides a 200 status for nginx purposes
    """
    return Response(status=200)

# Readiness verification endpoint (commonly known as "go to green")
@stocks_app.route('/gtg', methods=['GET'])
def gtg():
    """
    Readiness check endpoint to confirm the app's operational status.
    When the "details" query parameter is included, it provides connectivity information.
    Returns:
        JSON: Connectivity status and hostname if details are requested.
        Otherwise, a plain 200 response.
    """
    details = request.args.get("details")

    if "details" in request.args:
        return Response(
            json.dumps({"connected": "true", "hostname": instance_id}),
            status=200,
            mimetype="application/json"
        )
    else:
        return Response(status=200)

# Fetch a specific stock using its symbol
@stocks_app.route('/stock/<symbol>', methods=['GET'])
def get_stock(symbol):
    """
    Fetches details for a particular stock from DynamoDB.
    Args:
        symbol (str): The stock's unique identifier.
    Returns:
        JSON: Stock information if available, or a 404 error if missing.
    """
    try:
        response = dyndb_table.query(
            KeyConditionExpression=Key('symbol').eq(symbol)
        )

        if len(response['Items']) == 0:
            raise Exception  # Raise an exception if no items are found

        return Response(
            json.dumps(response['Items']),
            status=200,
            mimetype="application/json"
        )
    except:
        return "Not Found", 404

# Create or modify a stock entry
@stocks_app.route('/stock/<symbol>', methods=['POST'])
def post_stock(symbol):
    """
    Inserts or modifies a stock record in DynamoDB.
    Args:
        symbol (str): The stock's identifier for addition or update.
    Returns:
        JSON: Success confirmation with the symbol, or an error message on failure.
    """
    try:
        data = request.get_json()
        if not data:
            return "Invalid JSON", 400
        # Ensure symbol is in the data
        data['symbol'] = symbol
        dyndb_table.put_item(Item=data)
    except Exception as ex:
        return "Unable to update", 500

    return Response(
        json.dumps({"symbol": symbol}),
        status=200,
        mimetype="application/json"
    )

# Fetch the complete list of stocks
@stocks_app.route('/stocks', methods=['GET'])
def get_stocks():
    """
    Obtains a collection of all stocks stored in DynamoDB.
    Returns:
        JSON: Array of stocks if present, or a 404 error if empty.
    """
    try:
        items = dyndb_table.scan()['Items']

        if len(items) == 0:
            raise Exception  # Raise an exception if no items are found

        return Response(
            json.dumps(items),
            status=200,
            mimetype="application/json"
        )
    except:
        return "Not Found", 404
