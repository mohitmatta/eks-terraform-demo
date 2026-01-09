import sys
import json
import urllib.request
import urllib.error
import uuid

def make_request(url, method='GET', data=None):
    try:
        req = urllib.request.Request(url, method=method)
        if data:
            json_data = json.dumps(data).encode('utf-8')
            req.add_header('Content-Type', 'application/json')
            req.data = json_data
        
        with urllib.request.urlopen(req) as response:
            return response.status, response.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')
    except Exception as e:
        return 0, str(e)

def test_stock_app(base_url):
    print(f"Testing Stock App at {base_url}")

    # 1. Test GTG
    status, body = make_request(f"{base_url}/gtg")
    if status == 200:
        print("PASS: GTG endpoint reachable")
    else:
        print(f"FAIL: GTG returned {status}")
        return False

    # 2. Test POST /stock/<symbol>
    symbol = f"TEST-{uuid.uuid4().hex[:6].upper()}"
    payload = {
        "stockname": "Test Company",
        "lastsale": "$100.00",
        "country": "Testland",
        "ipoyear": 2024
    }
    
    status, body = make_request(f"{base_url}/stock/{symbol}", method='POST', data=payload)
    if status == 200:
        print(f"PASS: POST /stock/{symbol} successful")
    else:
        print(f"FAIL: POST /stock/{symbol} returned {status} - {body}")
        return False

    # 3. Test GET /stock/<symbol>
    status, body = make_request(f"{base_url}/stock/{symbol}")
    if status == 200:
        try:
            data = json.loads(body)
            # The API returns a list of items for query based on main.py logic
            if isinstance(data, list) and len(data) > 0 and data[0]['symbol'] == symbol:
                 print(f"PASS: GET /stock/{symbol} returned correct data")
            else:
                 print(f"FAIL: GET /stock/{symbol} returned unexpected data: {body}")
                 return False
        except json.JSONDecodeError:
            print(f"FAIL: GET /stock/{symbol} returned invalid JSON")
            return False
    else:
        print(f"FAIL: GET /stock/{symbol} returned {status}")
        return False

    # 4. Test GET /stocks
    status, body = make_request(f"{base_url}/stocks")
    if status == 200:
        try:
            data = json.loads(body)
            if isinstance(data, list):
                found = any(item.get('symbol') == symbol for item in data)
                if found:
                    print("PASS: GET /stocks contains the new symbol")
                else:
                    print("WARN: GET /stocks did not contain the new symbol (eventual consistency?)")
            else:
                print("FAIL: GET /stocks did not return a list")
                return False
        except json.JSONDecodeError:
             print("FAIL: GET /stocks returned invalid JSON")
             return False
    else:
        print(f"FAIL: GET /stocks returned {status}")
        return False

    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 test_stock_app.py <BASE_URL>")
        sys.exit(1)
    
    url = sys.argv[1].rstrip('/')
    if test_stock_app(url):
        sys.exit(0)
    else:
        sys.exit(1)