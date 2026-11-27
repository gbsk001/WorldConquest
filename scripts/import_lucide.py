"""Fetch pinned upstream vector artwork and complete licences, never Roblox uploads."""
from pathlib import Path
import urllib.request,json,hashlib,concurrent.futures
ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'assets/lucide';TARGET.mkdir(parents=True,exist_ok=True)
MAPPING={
 'Army':'swords','Buildings':'building-complex','Navy':'ship','Missiles':'rocket','Leaderboard':'trophy',
 'Settings':'settings','Soldiers':'shield-user','Recruitment':'user-round-plus','Gold':'coins',
 'Income':'trending-up','Territory':'flag','Rank':'medal','Friends':'user-round-plus','Exit':'log-out',
 'City':'building-complex','Factory':'factory','DefensePost':'castle','Port':'anchor','SAMLauncher':'radar',
 'MissileSilo':'tower-control','TransportShip':'container','Warship':'ship','TradeShip':'sailboat',
 'Train':'train-front','Carriage':'tram-front','AtomBomb':'bomb','HydrogenBomb':'radiation',
 'MIRV':'split','MIRVWarhead':'navigation','SAMMissile':'crosshair','Shell':'circle-dot','Crown':'crown',
 'Close':'x','Play':'play','Public':'globe','Private':'lock-keyhole','Tutorial':'circle-question-mark','Back':'arrow-left',
 'Shop':'shopping-bag','Arsenal':'rocket','Daily':'gift','Stars':'star','Profile':'user-round',
 'Notification':'bell','Volume':'volume-2','Language':'languages','Check':'check','Inventory':'backpack',
 'Upgrade':'chevrons-up','Delete':'trash','Party':'users-round','Calendar':'calendar-days',
}
def read(url):
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WorldConquest-license-audit'}),timeout=40) as response:return response.read()
if __name__=='__main__':
 manifest=TARGET/'manifest.json'
 commit=json.loads(manifest.read_text())['commit'] if manifest.exists() else json.loads(read('https://api.github.com/repos/lucide-icons/lucide/commits/main'))['sha']
 base='https://raw.githubusercontent.com/lucide-icons/lucide/'+commit+'/'
 (TARGET/'LICENSE').write_bytes(read(base+'LICENSE'))
 def fetch(name):
  data=read(base+'icons/'+name+'.svg');(TARGET/(name+'.svg')).write_bytes(data)
  return name,hashlib.sha256(data).hexdigest()
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:hashes=dict(pool.map(fetch,sorted(set(MAPPING.values()))))
 manifest.write_text(json.dumps({'repository':'https://github.com/lucide-icons/lucide','commit':commit,'license':'ISC, plus retained Feather MIT notices','icons':MAPPING,'sha256':hashes},indent=2))
 print('Pinned',len(hashes),'Lucide vectors:',commit)
