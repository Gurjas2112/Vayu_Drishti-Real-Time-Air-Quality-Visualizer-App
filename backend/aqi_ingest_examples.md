# Ingesting Data into Backend

Send data from your Python scrapers to the Node.js backend using a shared secret header `X-Ingest-Secret`.

Replace `YOUR_SECRET` with the value in backend `.env` (INGEST_SHARED_SECRET), and `BASE_URL` with your server.

## CPCB Example (Python)
```python
import requests

BASE_URL = "http://localhost:8080"
SECRET = "YOUR_SECRET"

payload = [
    {
        "station_id": "<uuid-of-station>",
        "timestamp": "2025-09-08T12:00:00Z",
        "aqi": 95,
        "pollutants": [{"name": "PM2.5", "value": 45.5}],
    }
]

resp = requests.post(
    f"{BASE_URL}/api/ingest/cpcb",
    json=payload,
    headers={"X-Ingest-Secret": SECRET}
)
print(resp.status_code, resp.text)
```

## ISRO Example (Python)
```python
import requests

BASE_URL = "http://localhost:8080"
SECRET = "YOUR_SECRET"

payload = [
    {
        "tile_id": "TILE-123",
        "lat": 28.6469,
        "lon": 77.3158,
        "timestamp": "2025-09-08T12:00:00Z",
        "aqi": 88,
        "pollutants": [{"name": "O3", "value": 120}],
    }
]

resp = requests.post(
    f"{BASE_URL}/api/ingest/isro",
    json=payload,
    headers={"X-Ingest-Secret": SECRET}
)
print(resp.status_code, resp.text)
```

## Realtime
Clients can connect to Socket.IO at `ws://<host>:<port>` and listen for `aqi:update` events.
