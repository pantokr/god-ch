import json
import os
import urllib.error
import urllib.request

KEY = 'AIzaSyAvFtrntzCzsBelC3CyYpwlkJqLEm3uIro'
PW = os.environ.get('PLC_PW', '')
CID = 'hLelZID38yX5wYmB4yrG'
ROOT = 'projects/god-ch/databases/(default)/documents/'
BASE = 'https://firestore.googleapis.com/v1/' + ROOT


def call(url, data=None, token=None, method=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(
        url, data=json.dumps(data).encode() if data is not None else None,
        headers=headers, method=method)
    try:
        return json.load(urllib.request.urlopen(req))
    except urllib.error.HTTPError as e:
        return {'error': e.code, 'body': e.read().decode()[:400]}


def login(n):
    lid = 'plc%d' % n
    r = call('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + KEY,
             {'email': lid + '@id.god-ch.local', 'password': PW, 'returnSecureToken': True})
    return r['localId'], r['idToken']


def val(x):
    for k, v in x.items():
        if k == 'stringValue':
            return v
        if k == 'nullValue':
            return None
        if k == 'arrayValue':
            return [val(i) for i in v.get('values', [])]
        if k == 'mapValue':
            return {a: val(b) for a, b in v.get('fields', {}).items()}
        return v


def fields(doc):
    return {a: val(b) for a, b in doc.get('fields', {}).items()}


def list_docs(path, token, size=200):
    out = []
    url = BASE + path + '?pageSize=%d' % size
    while True:
        r = call(url, token=token)
        if 'error' in r:
            return r
        out += r.get('documents', [])
        if 'nextPageToken' not in r:
            return out
        url = BASE + path + '?pageSize=%d&pageToken=%s' % (size, r['nextPageToken'])
