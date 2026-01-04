from flask import Flask, jsonify, abort
import os
import json

app = Flask(__name__)

DATA_FILE = 'payments.json'

def load_payments():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, 'r') as f:
        return json.load(f)

@app.route('/')
def hello():
    return "Hello from Flask App 2!"

@app.route('/payments', methods=['GET'])
def get_payments():
    return jsonify(load_payments())

@app.route('/payments/<payment_id>', methods=['GET'])
def get_payment(payment_id):
    payments = load_payments()
    payment = next((p for p in payments if p['id'] == payment_id), None)
    if payment:
        return jsonify(payment)
    abort(404)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
