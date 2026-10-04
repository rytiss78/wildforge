import io,urllib.request,zipfile,json,hashlib
from pathlib import Path
url='https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
class Remote(io.RawIOBase):
 def __init__(self): self.pos=0;self.size=1281349702
 def seekable(self):return True
 def readable(self):return True
 def tell(self):return self.pos
 def seek(self,n,w=0):self.pos=n if w==0 else self.pos+n if w==1 else self.size+n;return self.pos
 def read(self,n=-1):
  if n<0:n=self.size-self.pos
  if n==0:return b''
  end=min(self.size,self.pos+n)-1
  req=urllib.request.Request(url,headers={'User-Agent':'WildforgeBuild','Range':f'bytes={self.pos}-{end}'})
  with urllib.request.urlopen(req,timeout=120) as r:
   if r.status!=206:raise RuntimeError('Server ignored range')
   b=r.read()
  self.pos+=len(b);return b
z=zipfile.ZipFile(Remote());Path('tools/godot/templates').mkdir(exist_ok=True)
for info in z.infolist():
 if 'windows' in info.filename and ('x86_64' in info.filename) and 'release' in info.filename:
  b=z.read(info);p=Path('tools/godot/templates')/Path(info.filename).name;p.write_bytes(b)
  print(p,len(b),hashlib.sha256(b).hexdigest())
# Discover official extension repository names.
d=json.load(urllib.request.urlopen(urllib.request.Request('https://api.github.com/orgs/GodotSteam/repos?per_page=100',headers={'User-Agent':'WildforgeBuild'})))
print([r['full_name'] for r in d])
