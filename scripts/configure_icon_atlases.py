"""Insert four real uploaded Image IDs, in atlas order. No upload/publication."""
from pathlib import Path
import argparse,re
r=Path(__file__).resolve().parents[1]
def configure(source,ids):
 if len(ids)!=4 or len(set(ids))!=4 or any(type(n)is not int or n<=0 or n>9007199254740991 for n in ids):raise ValueError('Four distinct positive Roblox Image asset IDs are required.')
 result,n=re.subn(r'AtlasAssetIDs=\{[0-9, ]+\}', 'AtlasAssetIDs={'+','.join(map(str,ids))+'}',source)
 assert n==1,'Atlas configuration not found uniquely';return result
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('ids',type=int,nargs=4,metavar='IMAGE_ID');args=parser.parse_args()
 path=r/'src/client/IconAssets.luau';path.write_text(configure(path.read_text(encoding='utf-8-sig'),args.ids),encoding='utf-8')
 print('Configured four IDs. This checks numeric format only; verify Roblox ownership, image type, moderation and experience permissions. Rebuild both place files and update corresponding source.')
