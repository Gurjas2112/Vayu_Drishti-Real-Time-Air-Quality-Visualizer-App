import os
import json
import time
from typing import List, Dict, Any, Optional

import requests

class IngestClient:
    def __init__(self, base_url: str, secret: str, timeout: int = 15):
        self.base_url = base_url.rstrip('/')
        self.secret = secret
        self.session = requests.Session()
        self.timeout = timeout
        self.session.headers.update({
            'Content-Type': 'application/json',
            'X-Ingest-Secret': self.secret,
        })

    def _post(self, path: str, payload: List[Dict[str, Any]]):
        url = f"{self.base_url}{path}"
        resp = self.session.post(url, data=json.dumps(payload), timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def send_cpcb(self, records: List[Dict[str, Any]]):
        return self._post('/api/ingest/cpcb', records)

    def send_isro(self, records: List[Dict[str, Any]]):
        return self._post('/api/ingest/isro', records)

if __name__ == '__main__':
    base_url = os.getenv('BACKEND_URL', 'http://localhost:8080')
    secret = os.getenv('INGEST_SHARED_SECRET', 'dev-secret')
    client = IngestClient(base_url, secret)

    # quick sanity test payloads
    cpcb_payload = [{
        'station_id': '00000000-0000-0000-0000-000000000000',
        'timestamp': '2025-09-08T12:00:00Z',
        'aqi': 95,
        'pollutants': [{'name': 'PM2.5', 'value': 45.5}],
    }]
    try:
        print('Posting CPCB...')
        print(client.send_cpcb(cpcb_payload))
    except Exception as e:
        print('CPCB error:', e)

    isro_payload = [{
        'tile_id': 'TILE-123',
        'lat': 28.6469,
        'lon': 77.3158,
        'timestamp': '2025-09-08T12:00:00Z',
        'aqi': 88,
        'pollutants': [{'name': 'O3', 'value': 120}],
    }]
    try:
        print('Posting ISRO...')
        print(client.send_isro(isro_payload))
    except Exception as e:
        print('ISRO error:', e)

