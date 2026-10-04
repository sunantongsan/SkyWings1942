"""Fetch exactly the original GhostMatch3 art used by the embedded native game."""
import hashlib,json,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def fetch():
    manifest=json.loads((ROOT/'native/xian/ghost-source.json').read_text())
    dest=ROOT/'native/xian/res/drawable-nodpi';dest.mkdir(parents=True,exist_ok=True)
    for item in manifest['assets']:
        p=dest/item['name']
        def valid(data):return hashlib.sha256(data).hexdigest()==item['sha256']
        if p.exists() and valid(p.read_bytes()):continue
        url=f"https://raw.githubusercontent.com/sunantongsan/GhostMatch3/{manifest['commit']}/app/src/main/res/drawable-nodpi/{item['name']}"
        data=urllib.request.urlopen(url,timeout=60).read()
        if not valid(data):raise ValueError('Asset checksum mismatch: '+item['name'])
        p.write_bytes(data)
if __name__=='__main__':fetch()
